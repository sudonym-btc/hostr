# TODO: NIP-17 Read Receipts & Chat Liveness

Status: **Not started**
References:

- [PR #2000 — Mark as Received](https://github.com/nostr-protocol/nips/pull/2000) (vitorpamplona, open)
- [PR #1761 — Seen events / bloom filter](https://github.com/nostr-protocol/nips/pull/1761) (kehiy, open)
- [PR #1994 — "seen" event](https://github.com/nostr-protocol/nips/pull/1994) (fiatjaf, closed)
- [PR #1405 — Read status 2](https://github.com/nostr-protocol/nips/pull/1405) (staab, closed — removed from Coracle)
- [Issue #2002 — Liveness pulse](https://github.com/nostr-protocol/nips/issues/2002)

---

## Overview

There are three distinct concerns for message-delivery feedback in NIP-17 DMs.
Each has a different privacy/complexity trade-off and should be implemented
separately.

| #   | Concern                                                         | Visibility          | Persistence                  | Priority |
| --- | --------------------------------------------------------------- | ------------------- | ---------------------------- | -------- |
| 1   | **Received** — counterparty's client has downloaded & decrypted | Public heartbeat    | Replaceable event            | **High** |
| 2   | **Seen** — user has actually read a message (cross-client sync) | Private / encrypted | Replaceable event per chat   | Medium   |
| 3   | **Typing / liveness** — ephemeral chat-specific status          | Public, ephemeral   | Short-lived (expiration tag) | Low      |

---

## 1. "Received" heartbeat — kind `10017`

### What it does

A public **replaceable** event (`kind 10017`) updated every time the NIP-17
client decrypts a new message batch. Contains no message IDs and no content —
just a `created_at` timestamp. Counterparties check: _"is their `10017`
timestamp newer than my last sent message?"_ If yes → message was likely
received.

### Event shape

```json
{
  "kind": 10017,
  "pubkey": "<my-pubkey>",
  "created_at": "<now, slightly randomized ±30s>",
  "tags": [],
  "content": ""
}
```

### Implementation plan

1. **Create `ReceivedHeartbeat` service** in `usecase/messaging/received_heartbeat.dart`.
   - Inject `Ndk`, `Auth`, `Requests`.
   - On each `Threads.processMessage()` call (or debounced after a batch),
     publish/replace a `kind 10017` event signed by the active keypair.
   - Randomise `created_at` by up to ±30 seconds to limit metadata leakage
     (as discussed in PR #2000).

2. **Query counterparty heartbeats** in `Thread`:
   - When opening a thread, subscribe to `kind 10017` from the counterparty
     pubkey.
   - Expose a `Stream<DateTime?> lastReceivedAt` on `Thread`.
   - In the UI, compare each outgoing message's `created_at` against
     `lastReceivedAt`. If `lastReceivedAt >= message.created_at` → show a
     single-check (✓) "delivered" indicator.

3. **Debounce publishing** — don't publish a new `10017` on every single
   message decrypt. Debounce to ~5 seconds so that catching up on 100
   messages produces one event, not 100.

4. **Files to create/modify:**
   - `usecase/messaging/received_heartbeat.dart` (new — service)
   - `usecase/messaging/threads.dart` (call heartbeat after processing)
   - `usecase/messaging/thread/thread.dart` (subscribe to counterparty's 10017)
   - `datasources/` — add filter/kind constant `kNostrKindReceivedHeartbeat = 10017`

---

## 2. "Seen" status — private, per-conversation

### What it does

Tells the **counterparty** which specific messages you have actually opened/read
(double-check ✓✓). Two sub-approaches are viable:

### Option A: Timestamp-based (recommended — simplest)

Store a single timestamp per conversation = `created_at` of the most recent
message you've scrolled to / rendered on screen. Everything with
`created_at <= that timestamp` is "seen." Send this inside a NIP-17 gift-wrapped
event to the counterparty.

**Pros:** Simple, tiny payload, no bloom-filter complexity.
**Cons:** Late-arriving or out-of-order messages may be incorrectly marked seen.
staab found this acceptable in practice for 1:1 chats.

```json
// Rumor (unsigned, inside gift-wrap)
{
  "kind": 16,
  "tags": [
    ["p", "<counterparty-pubkey>"],
    ["seen_until", "<unix-timestamp-of-last-seen-message>"]
  ],
  "content": ""
}
```

### Option B: Bloom filter on replaceable event (PR #1761)

A `kind 30010` addressable event whose `.content` is a bloom filter encoding
seen gift-wrap IDs. The `d` tag is derived as
`sha256(hkdf(private_key, salt: 'nip17') || "<counterparty-pubkey>")` to hide
the conversation counterparty.

**Pros:** Per-message granularity, public but obfuscated, replaceable.
**Cons:** Must spec bloom filter exactly (hash function, encoding, salt, size).
False positives (message falsely shown as seen) are possible but benign.

### Implementation plan (Option A — timestamp-based)

1. **Create `SeenStatus` service** in `usecase/messaging/seen_status.dart`.
   - Track `Map<String, int> lastSeenTimestampByThread` (thread ID → unix ts).
   - When the user scrolls to / views a message in the UI, update the
     timestamp for that thread.

2. **Broadcast seen timestamp to counterparty:**
   - Debounce (e.g. 3 seconds after last scroll).
   - Create a `kind 16` rumor with a `seen_until` tag.
   - Gift-wrap and send via the same `Messaging.broadcastText` path to the
     counterparty's `10050` relays.
   - Set a short `expiration` tag on the gift wrap (e.g. 7 days) to avoid
     relay bloat.

3. **Receive and display counterparty's seen status:**
   - In `Thread`, listen for incoming `kind 16` events with `seen_until` tag.
   - Expose `Stream<int?> counterpartySeenUntil` on `Thread`.
   - UI: for each outgoing message, if `message.created_at <= counterpartySeenUntil`
     → show double-check ✓✓.

4. **Cross-client sync (own devices):**
   - Optionally publish a **private** replaceable event (`kind 30010` or
     similar) encrypted to yourself, storing `lastSeenTimestampByThread`.
   - This lets a second client (e.g. desktop) pick up where mobile left off
     without re-marking everything as unread.

5. **Files to create/modify:**
   - `usecase/messaging/seen_status.dart` (new — service)
   - `usecase/messaging/thread/thread.dart` (expose seen stream, process incoming seen events)
   - `usecase/messaging/thread/state.dart` (add seen-until to thread state)
   - App UI layer — message bubbles need ✓ / ✓✓ indicators

---

## 3. "Typing" / liveness indicator — kind `10018` (ephemeral)

### What it does

A public, short-lived replaceable event indicating the user is currently typing
in a specific chat room. The `room` is identified by a bloom filter of recent
message IDs (so it doesn't leak which conversation).

### Event shape (per vitorpamplona's proposal)

```json
{
  "kind": 10018,
  "pubkey": "<my-pubkey>",
  "created_at": "<now>",
  "tags": [
    ["room", "<bloom-filter-of-last-3-message-ids>"],
    ["expiration", "<now + 15 seconds>"]
  ],
  "content": ""
}
```

Receiving clients check if the IDs of the 3 most recent `kind 14` messages in
the current thread are inside the bloom filter. If yes → show "typing…".

### Implementation plan

1. **Create `TypingIndicator` service** in `usecase/messaging/typing_indicator.dart`.
   - Expose `void startTyping(Thread thread)` / `void stopTyping()`.
   - On `startTyping`, publish a `kind 10018` with a 15-second expiration.
   - Re-publish every ~10 seconds while the user continues typing.
   - On `stopTyping` (or after 15s idle), stop publishing.

2. **Bloom filter for room identification:**
   - Take the last 3 message IDs from the thread.
   - Build a small bloom filter (≤256 bits, 3 hash rounds, random salt).
   - Encode as `size:rounds:base64(bits):base64(salt)` in the `room` tag.

3. **Subscribe to counterparty typing events:**
   - In `Thread`, subscribe to `kind 10018` from the counterparty pubkey.
   - On receive, check if your last 3 thread message IDs appear in the bloom
     filter → if yes, set `isCounterpartyTyping = true`.
   - Auto-expire after 15 seconds with no new event.

4. **Privacy considerations:**
   - This is **opt-in**. Users should be able to disable it in settings.
   - The bloom filter prevents leaking exact conversation identity to relay
     operators while still allowing the counterparty to match.

5. **Files to create/modify:**
   - `usecase/messaging/typing_indicator.dart` (new)
   - `util/bloom_filter.dart` (new — shared bloom filter implementation)
   - `usecase/messaging/thread/thread.dart` (subscribe, expose typing stream)

---

## Key Constants to Add

In `models` or `datasources`, define:

```dart
const kNostrKindReceivedHeartbeat = 10017;
const kNostrKindTypingIndicator = 10018;
const kNostrKindSeenMessages = 30010;
const kNostrKindSeenStatus = 16; // rumor kind inside gift-wrap
```

---

## Risks & Open Questions

- **No merged NIP yet.** All proposals are still open PRs. Kind numbers and
  event shapes may change. Build behind a feature flag.
- **Gift-wrap bloat.** Seen events sent as gift wraps are non-replaceable on
  relays. Always set `expiration` tags to limit storage.
- **Group chats.** The timestamp approach works well for 1:1 DMs (Hostr's
  primary use case for host↔guest messaging). For groups >2, bloom filters
  or per-member seen events are needed — defer until needed.
- **staab's lesson.** Enumerating individual event IDs in persistent events
  caused "notification badge whack-a-mole" due to late-arriving events.
  Timestamp-based is more forgiving. Don't store full ID lists.
- **Privacy.** The `10017` heartbeat is public — anyone can see when you last
  fetched DMs. Randomise `created_at` to limit precision.
