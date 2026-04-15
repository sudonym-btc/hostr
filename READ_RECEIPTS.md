# Read Receipts — Implementation Plan

> **Status:** Iteration 3 — Gift-wrapped `kind:16` seen receipts, no expiration
> **Decision:** Use the same gift-wrap pipeline as regular DMs. One seen
> receipt per read session, sent as the chronologically last event in the
> conversation. Never set an expiration tag — these wraps persist forever.
> **No local persistence.** All seen state is derived from the kind:16
> gift wraps present in the thread.

---

## Context & Motivation

Hostr uses NIP-17 gift-wrapped DMs (`kind:14` → `kind:13` seal → `kind:1059`
wrap) for all host↔guest messaging. Users need to know:

1. **Was my message received?** (Did their client download it?)
2. **Was my message read?** (Did they actually look at it?)
3. **How many conversations are unread?** (Badge count for the inbox)

Tier 1 ("Received" heartbeat, `kind:10017`) is already shipped. This document
is the plan for Tier 2 — true **read receipts** powering three UI features:

- **✓✓ double-check** in inbox list items (counterparty read our last message)
- **Unread count** on each inbox item (how many unread messages from them)
- **Read indicators** on individual messages inside the thread view

---

## Community Landscape (as of April 2026)

There is **no merged NIP** for read receipts. Active proposals:

| PR / Issue                                                  | Author        | Approach                                           | Status |
| ----------------------------------------------------------- | ------------- | -------------------------------------------------- | ------ |
| [#2000](https://github.com/nostr-protocol/nips/pull/2000)   | vitorpamplona | Public `kind:10017` heartbeat (what we ship)       | Open   |
| [#1761](https://github.com/nostr-protocol/nips/pull/1761)   | kehiy         | `kind:30010` bloom filter of seen IDs              | Open   |
| [#1994](https://github.com/nostr-protocol/nips/pull/1994)   | fiatjaf       | Gift-wrapped seen event with IDs + timestamp       | Closed |
| [#1405](https://github.com/nostr-protocol/nips/pull/1405)   | staab         | Event-ID + timestamp hybrid (removed from Coracle) | Closed |
| [#2002](https://github.com/nostr-protocol/nips/issues/2002) | kehiy         | Umbrella liveness-pulse issue                      | Open   |

### Key lessons from the discussion

| Contributor                     | Take-away                                                                                                                                                                                             |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **staab** (Coracle)             | Shipped ID-enumeration read receipts in production; suffered "notification badge whack-a-mole" with late-arriving events. Reverted to timestamps. **Timestamps are simpler and good enough for 1:1.** |
| **vitorpamplona** (Amethyst)    | Prefers public heartbeat for "received." For "seen," warns that gift-wrapped events are non-replaceable and will accumulate. Recommends replaceable events or bloom filters.                          |
| **fiatjaf**                     | Agrees timestamps suffice. Bloom filters are "overkill" for DM read receipts.                                                                                                                         |
| **erskingardner** (White Noise) | Short `expiration` tags are fine; long-term reconstitution of read history isn't important.                                                                                                           |
| **Giszmo**                      | Purely timestamp-based is imperfect for group chats (out-of-order delivery). Fine for 1:1 / small groups — Hostr's use case.                                                                          |

---

## Why We Chose Gift-Wrapped `kind:16` With No Expiration

### Approaches considered and rejected

**Bloom filter (`kind:30010`)** — Addressable replaceable event with a bloom
filter encoding seen message IDs. Technically elegant (no bloat, persistent,
replaces in-place), but introduces significant complexity:

- Must implement bloom filter data structure (hash functions, encoding, sizing)
- No merged NIP — the exact spec (hash function, encoding format, `d` tag
  derivation) is still under discussion in PRs #1761 and #1497
- Cross-client interop is impossible until a NIP merges
- The `d` tag derivation (`sha256(hkdf(privkey, salt:'nip17') || sorted_pubkeys)`)
  adds cryptographic complexity for questionable benefit in our walled-garden
  relay setup
- Overkill for Hostr's use case: 1:1 accommodation chats with moderate volume

**Gift-wrapped `kind:16` with expiration** — The obvious first instinct, but
fatally broken. When the relay GCs expired wraps, conversations silently revert
to "unread" for both sides. A user who goes on holiday comes back to every
thread showing as unread. The ✓✓ indicator vanishes on the counterparty's side
too. Expiration and read receipts are fundamentally incompatible.

### The chosen approach

**Gift-wrapped `kind:16` with _no_ expiration.** Same pipeline as regular DMs.
The seen receipt is a `kind:16` rumor inside the standard `kind:13` seal →
`kind:1059` gift wrap chain. It carries a `seen_until` timestamp telling the
counterparty: "I have read everything in our conversation up to this moment."

The `kind:1059` wraps **never expire** — they persist on the relay forever,
just like DM wraps.

### Addressing the bloat concern

vitorpamplona's warning (PR #1994) is valid: non-replaceable gift wraps
accumulate over time. Here's why it's manageable for us:

**Bloat is bounded by the "one per read session" rule.**

We only send a seen receipt when _both_ conditions are true:

1. There are counterparty messages newer than our last seen receipt
2. The chronologically last event in the conversation is NOT already our own
   seen receipt

This means:

| Scenario                                        | Seen receipts sent                           |
| ----------------------------------------------- | -------------------------------------------- |
| I read 10 new messages in one sitting           | 1                                            |
| I close the app and reopen, no new messages     | 0 (last event is already my receipt)         |
| Counterparty sends 3 more messages, I read them | 1                                            |
| Long conversation, 200 messages over 2 months   | ~30–50 receipts total (one per read session) |

For a typical Hostr accommodation thread (10–200 messages over days/weeks),
we'd accumulate roughly **1 seen receipt per distinct reading session**. That's
maybe 20–50 extra gift wraps over the life of a conversation. Compared to the
DM wraps themselves (2 wraps per message × N messages), this adds ~10–25% more
events. Manageable.

**Worst case:** a power user obsessively checking messages 100 times a day.
Even then, the counterparty would need to send a message between each check
for a receipt to be sent. The bloat is bounded by `min(read_sessions,
counterparty_messages)`.

**If we need to clean up later**, we can:

- Ask the relay to GC seen-receipt wraps older than N months
- Since `seen_until` is a high-water mark, only the latest receipt matters —
  old ones are redundant by definition
- This is a relay-side optimization, not a protocol change

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Three Tiers                              │
├──────────┬──────────────────┬───────────────────────────────────┤
│  Tier    │  Concern         │  Mechanism                        │
├──────────┼──────────────────┼───────────────────────────────────┤
│  1 ✅    │  Received        │  kind:10017, public replaceable   │
│          │  (delivered)     │  heartbeat. Already shipped.      │
├──────────┼──────────────────┼───────────────────────────────────┤
│  2 🔲    │  Seen / Read     │  kind:16 rumor, gift-wrapped.     │
│          │  (read receipt)  │  No expiration. Timestamp-based.  │
│          │                  │  Sent as last event in thread.    │
├──────────┼──────────────────┼───────────────────────────────────┤
│  3 ⏳    │  Typing          │  kind:10018 public ephemeral.     │
│          │  (liveness)      │  Deferred — models exist.         │
└──────────┴──────────────────┴───────────────────────────────────┘
```

---

## Event Shape — `kind:16` Seen Receipt

The inner rumor (before gift-wrapping):

```jsonc
{
  "kind": 16,
  "pubkey": "<our-pubkey>",
  "created_at": "<now>",
  "tags": [
    ["p", "<counterparty-pubkey>"],
    ["seen_until", "<unix-timestamp-of-latest-message-we-read>"],
  ],
  "content": "",
}
```

This rumor is then sealed (`kind:13`) and gift-wrapped (`kind:1059`) to the
counterparty — and to ourselves — using the exact same pipeline as regular
`kind:14` DM rumours. No expiration tag is set on the gift wrap.

The `SeenStatus` model already exists and produces exactly this shape:

```dart
SeenStatus.create(
  pubKey: ourPubkey,
  counterpartyPubKey: counterparty,
  seenUntil: latestMessage.createdAt,  // unix timestamp
);
```

**Fields:**

| Tag          | Meaning                                                                                                           |
| ------------ | ----------------------------------------------------------------------------------------------------------------- |
| `p`          | The counterparty whose messages we've read                                                                        |
| `seen_until` | Unix timestamp. All messages with `createdAt ≤ seen_until` are considered read. High-water mark — only increases. |

---

## Detailed Flows

### Flow 1: Sending a Seen Receipt (we read their messages)

```
User opens a conversation (or scrolls to bottom)
        │
        ▼
  ┌─ Check: are there counterparty messages newer than
  │  seenUntil[ourPubkey]?  (our own latest seen receipt in this thread)
  │     │
  │    NO ──▶ Do nothing (already up to date)
  │     │
  │    YES
  │     ▼
  │  Check: is the latest event in this conversation already
  │  our own kind:16 seen receipt?
  │     │
  │    YES ──▶ Do nothing (avoid duplicate receipt)
  │     │
  │    NO
  │     ▼
  │  Create SeenStatus rumor (kind:16)
  │     │
  │     ├──▶ seen_until = createdAt of latest message in conversation
  │     ├──▶ p = counterparty pubkey (one receipt per counterparty)
  │     │
  │     ▼
  │  Gift-wrap via Messaging._broadcastRumour()
  │     │
  │     ├──▶ Wrap to each counterparty (they learn we read their messages)
  │     └──▶ Wrap to self (so our own seenUntil map gets updated on
  │          re-subscription — this IS the persistence mechanism)
  │
  └─ Thread picks up the new kind:16 wrap → updates seenUntil[ourPubkey]
     → recomputes unreadCount → emits new state
```

**Key details:**

- The `seen_until` timestamp should be the `createdAt` of the latest message
  in the thread _at the time of viewing_, regardless of who sent it. This is
  the high-water mark.
- The "latest event" check compares across both DMs (kind:14) and seen
  receipts (kind:16) in the conversation's event stream. If the most recent
  event by `createdAt` is our own kind:16 → skip.
- Debounce: if the user rapidly opens/closes threads, debounce the send by
  ~1–2 seconds to avoid sending receipts for accidental taps.
- **No local persistence.** When the app restarts and re-subscribes to gift
  wraps, it receives our own kind:16 receipts from the relay, rebuilding
  the `seenUntil` map. The relay _is_ the persistence layer.

### Flow 2: Receiving a Seen Receipt (any pubkey — counterparty or self)

All kind:16 wraps are processed identically regardless of who sent them.
The `seenUntil` map is keyed by the rumor's pubkey, so our own receipts
and counterparty receipts are handled by the same codepath.

```
Gift wrap arrives via user subscription
        │
        ▼
  Decrypt: kind:1059 → kind:13 seal → inner rumor
        │
        ▼
  Route by rumor kind:
        │
        ├──▶ kind:14 (DM)     → existing message pipeline
        │
        └──▶ kind:16 (Seen)   → seen receipt pipeline
                │
                ▼
          Parse SeenStatus from rumor
                │
                ├──▶ senderPubkey = rumor.pubkey (who sent this receipt)
                ├──▶ seenUntil = the timestamp value
                │
                ▼
          Route to the Thread for this conversation
                │
                ▼
          Update seenUntil map:
                │
                ├──▶ seenUntil[senderPubkey] = max(existing, new value)
                │    (high-water mark — never decreases)
                │
                ▼
          Recompute derived state:
                │
                ├──▶ unreadCount(ourPubkey): messages from others
                │    with createdAt > seenUntil[ourPubkey]
                │
                └──▶ read: seenUntil[counterparty] >= our latest sent msg
                │
                ▼
          Emit state → UI updates (badge / ✓✓)
```

**Key details:**

- The `seenUntil` map value for any pubkey only ever increases. Older
  receipts (e.g. from delayed relay sync) are ignored.
- When `rumor.pubkey == ourPubkey`, it's either a receipt we just sent or
  one from another device (cross-device sync). Either way, it updates
  `seenUntil[ourPubkey]` and recomputes `unreadCount`.
- When `rumor.pubkey == counterpartyPubkey`, it updates
  `seenUntil[counterparty]` and recomputes the `read` flag.
- Cross-device sync comes for free: read on phone → seen receipt wraps to
  self → desktop re-subscribes → picks up the receipt → `seenUntil[ourPubkey]`
  is up to date → unread count is correct.

---

## Unread Conversation Count

### Per-thread unread count

**Relay-derived** — computed from the `seenUntil` map that the Thread builds
from kind:16 gift wraps in its event stream:

```
int unreadCount(String pubkey) {
  final seen = seenUntil[pubkey] ?? 0;
  return messages
    .where((m) => m.pubKey != pubkey)       // messages from others
    .where((m) => m.createdAt > seen)        // newer than this pubkey's last read
    .length;
}
```

Call it with our own pubkey to get our unread count:

```
thread.unreadCount(auth.publicKey)  // → 3 unread messages in this conversation
```

**Lifecycle:**

1. Thread is created, no kind:16 wraps yet → `seenUntil[ourPubkey]` is `null`
   → `unreadCount(ourPubkey)` = all counterparty messages (everything is unread)
2. User opens the thread → app sends a kind:16 seen receipt
   → wrap arrives back (self-wrap) → `seenUntil[ourPubkey]` updates
   → `unreadCount` drops to 0
3. New messages arrive while thread is open → user sends another receipt
   (if needed, per the guard rule) → count stays at 0
4. New messages arrive while thread is closed → they're newer than
   `seenUntil[ourPubkey]` → `unreadCount` increases
5. App restarts → re-subscribes to gift wraps → receives all kind:16 wraps
   from relay → `seenUntil` map is rebuilt → counts are correct

**Important:** `kind:16` seen receipt events themselves should NOT count
toward `unreadCount`. They're metadata, not user-visible messages. When
computing unread count, filter to only `kind:14` DM messages.

### Global unread count (inbox badge)

```dart
convosWithUnread = threads.where(
  (thread) => thread.unreadCount(auth.publicKey) > 0,
).length;
```

Or a total message count:

```dart
totalUnread = threads.fold(0, (sum, t) => sum + t.unreadCount(auth.publicKey));
```

This powers the inbox tab badge / notification count.

---

## UI Feature 1: Read Ticks in Inbox List Items

Current behaviour in `InboxItemView`:

- Shows single ✓ when `received == true` (heartbeat-based, already working)
- Tints ✓ with primary color when `read == true` (but `read` is never set)

### Target behaviour

| State                     | Indicator                | Condition                       |
| ------------------------- | ------------------------ | ------------------------------- |
| Sent, not received        | No check                 | `sentByUs && !received`         |
| Received, not read        | ✓ (grey)                 | `sentByUs && received && !read` |
| Read                      | ✓✓ or ✓ tinted           | `sentByUs && read`              |
| Unread messages from them | **Unread badge** (count) | `unreadCount > 0`               |
| All caught up             | No badge                 | `unreadCount == 0`              |

### Changes needed

The `InboxItemView` already accepts `read` and `received` booleans. It
already renders a single ✓ when received. Changes:

1. **When `read == true`**: change the icon from `Icons.done` to
   `Icons.done_all` (✓✓), OR tint the existing ✓ with the primary color.
   Both are standard patterns. WhatsApp uses blue ✓✓; we can use our
   primary color.

2. **Unread badge**: add an unread count badge to the trailing column. When
   `unreadCount > 0`, show a small circular badge with the count. When
   `unreadCount == 0`, hide it. This replaces the date in the trailing
   position or appears alongside it.

3. **Bold/dim styling**: optionally, conversations with `unreadCount > 0`
   get a bolder title/subtitle, and read conversations get dimmer text.
   Standard inbox pattern.

### Data flow for inbox item

```
Thread.state$ (BehaviorSubject<ThreadState>)
        │
        ▼
  ThreadCubit maps to ThreadCubitState
        │
        ├──▶ threadState.read                         → InboxItemView.read
        ├──▶ threadState.received                     → InboxItemView.received    (existing)
        ├──▶ threadState.unreadCount(ourPubkey)       → InboxItemView.unreadCount (new)
        └──▶ threadState.isLastMessageOurs            → InboxItemView.sentByUs
```

---

## UI Feature 2: Read Indicators in the Thread (Message) View

Inside the actual conversation, users need to see which messages have been
read by the counterparty.

### Strategy: "last read" marker, not per-message ticks

Showing ✓✓ on every single message is noisy. Instead, show a read indicator
on the **last message that the counterparty has read** — i.e. our last sent
message with `createdAt ≤ counterpartySeenUntil`.

This mirrors WhatsApp/iMessage behavior: blue ticks appear on the most recent
message(s), not on every historical message.

### How it works

Given the counterparty's `seenUntil` timestamp:

1. Find our sent messages in the thread (where `msg.pubKey == ourPubkey`)
2. For each: `isReadByCounterparty = msg.createdAt <= counterpartySeenUntil`
3. In the UI, show a small "Read" label or ✓✓ icon beneath the _last_ such
   message (the most recent one they've read)
4. If they haven't read any of our messages: show nothing (or show ✓ for
   received, based on heartbeat)

### Visual treatment options

| Option                    | Description                                                                   |
| ------------------------- | ----------------------------------------------------------------------------- |
| **A) Subtle "Read" text** | Small grey "Read" label below the last read message bubble, like iMessage     |
| **B) ✓✓ icon**            | Double check mark below the bubble, matching inbox styling                    |
| **C) "Read at HH:MM"**    | Include the time from the seen receipt's `created_at`. More info, more space. |

Recommendation: **Option B (✓✓ icon)** for consistency with the inbox, with
an optional tap-to-expand that shows the timestamp.

### Data flow for thread view

```
ThreadState
    │
    ├──▶ seenUntil: Map<String, int>    (pubkey → seen_until timestamp)
    ├──▶ messages: List<Message>         (kind:14 DMs only — seen receipts filtered out)
    │
    ▼
  For each message bubble:
    │
    ├──▶ msg.pubKey == ourPubkey?
    │       │
    │      YES ──▶ Check all counterparty pubkeys:
    │       │       for each cp in counterpartyPubkeys:
    │       │         isRead = seenUntil[cp] != null
    │       │                  && msg.createdAt <= seenUntil[cp]
    │       │       │
    │       │       ALL read  ──▶ show ✓✓ (or "Read")
    │       │       SOME read ──▶ show ✓✓ with partial indicator (group chats)
    │       │       NONE read ──▶ show ✓ if received, else nothing
    │       │
    │      NO ──▶ It's their message, no read indicator needed
```

### Filtering seen receipts from the message list

`kind:16` seen receipts should NOT appear as message bubbles in the thread
view. When building the list of messages for display:

- Include: `kind:14` DM messages
- Exclude: `kind:16` seen status events

The seen receipt data is consumed as _state_ (updating the `seenUntil` map),
not displayed as _content_.

---

## ThreadState Changes

Current `ThreadState` fields:

```dart
final bool read;       // currently always false — never set
final bool received;   // set by _computeReceived() via heartbeat
```

### New field: `seenUntil` map

```dart
/// Maps pubkey → highest seen_until timestamp from their kind:16 receipts.
/// Derived entirely from the kind:16 gift wraps in this thread's event stream.
/// No local persistence — rebuilt from relay on every subscription.
final Map<String, int> seenUntil;    // default: {}
```

This single map replaces the old `localSeenUntil` + `counterpartySeenUntil`
concept. Every participant's read position lives in the same structure:

- `seenUntil[ourPubkey]` — how far WE have read (from our own self-wrapped receipts)
- `seenUntil[counterparty1]` — how far counterparty 1 has read
- `seenUntil[counterparty2]` — how far counterparty 2 has read (group chats)

### Computed properties

```dart
/// How many messages are unread for a given pubkey.
/// Call with ourPubkey for our unread count.
int unreadCount(String pubkey) {
  final seen = seenUntil[pubkey] ?? 0;
  return messages
      .where((m) => m.pubKey != pubkey && m.createdAt > seen)
      .length;
}

/// Have ALL counterparties read our latest sent message?
bool get read {
  if (counterpartyPubkeys.isEmpty) return false;
  final ourLatest = messages
      .where((m) => m.pubKey == ourPubkey)
      .map((m) => m.createdAt)
      .fold(0, (a, b) => a > b ? a : b);
  if (ourLatest == 0) return false;
  return counterpartyPubkeys.every(
    (cp) => (seenUntil[cp] ?? 0) >= ourLatest,
  );
}
```

### `copyWith` update

Add `seenUntil` to the existing `copyWith` method. When updating, merge with
high-water-mark semantics:

```dart
Map<String, int> mergeSeenUntil(Map<String, int> existing, Map<String, int> incoming) {
  final merged = Map<String, int>.from(existing);
  for (final entry in incoming.entries) {
    merged[entry.key] = max(merged[entry.key] ?? 0, entry.value);
  }
  return merged;
}
```

---

## Processing Pipeline — Where kind:16 Fits In

Currently, gift-wrapped events flow through:

```
UserSubscriptions (subscription) → decrypt → Message → Threads.processMessage() → Thread
```

### Required changes

The decrypt step currently assumes all inner rumours are `kind:14` DMs. We
need to branch on the inner rumour's kind:

```
UserSubscriptions (subscription)
        │
        ▼
  Decrypt gift wrap → inner rumor
        │
        ▼
  Switch on rumor.kind:
        │
        ├──▶ kind:14 (DM)
        │       │
        │       ▼
        │     Existing pipeline: create Message, route to Thread
        │
        └──▶ kind:16 (Seen Status)
                │
                ▼
              Parse SeenStatus from rumor
                │
                ▼
              Route to the Thread for the conversation
              identified by the "p" tag + pubkey combination
                │
                ▼
              Thread updates seenUntil[rumor.pubkey]
              (same codepath for counterparty receipts and our own)
```

### Sending pipeline

Add a method to `Messaging` (or a new `SeenStatusService`) that creates the
`kind:16` rumor and broadcasts it via the existing gift-wrap pipeline:

```
Thread.markAsRead()
        │
        ▼
  Create SeenStatus.create(pubKey, counterpartyPubKey, seenUntil)
        │
        ▼
  Convert to Nip01Event (rumor)
        │
        ▼
  Messaging._broadcastRumour(rumor, recipientPubkeys)
        │
        ├──▶ Gift-wrap to counterparty (no expiration)
        └──▶ Gift-wrap to self (cross-device sync)
```

This reuses the entire existing gift-wrap infrastructure. No new crypto, no
new relay subscriptions for a different kind, no bloom filter math. The seen
receipt flows through the same pipes as DMs.

---

## The "Last Message" Guard — Preventing Duplicate Receipts

The core dedup rule: **don't send a seen receipt if the last event in the
conversation is already our own seen receipt.**

### How to track this

Since the `seenUntil` map is derived from gift wraps in the thread, and the
Thread already tracks the latest message timestamp, the guard is a simple
comparison:

```dart
bool get shouldSendReceipt {
  final ourSeen = seenUntil[ourPubkey] ?? 0;
  final latestCounterpartyMsg = messages
      .where((m) => m.pubKey != ourPubkey)
      .map((m) => m.createdAt)
      .fold(0, (a, b) => a > b ? a : b);

  // Are there counterparty messages newer than what we've seen?
  return latestCounterpartyMsg > ourSeen;
}
```

If `seenUntil[ourPubkey]` is already ≥ the latest counterparty message, we've
already sent a receipt for this state — don't send another. This naturally
deduplicates because our own receipt's `seen_until` value is in the map.

---

## File Change Checklist

### New files

| #   | File                                              | Purpose                                                   |
| --- | ------------------------------------------------- | --------------------------------------------------------- |
| 1   | `hostr_sdk/lib/usecase/seen/seen.dart`            | `SeenService` — send seen receipts, process incoming ones |
| 2   | `hostr_sdk/lib/usecase/seen/main.dart`            | Barrel export                                             |
| 3   | `hostr_sdk/test/unit/usecase/seen/seen_test.dart` | Unit tests                                                |

### Modified files

| #   | File                                                                                      | Change                                                                                                                                                  |
| --- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4   | `hostr_sdk/lib/usecase/messaging/thread/state.dart`                                       | Add `seenUntil` map (`Map<String, int>`), `unreadCount(String pubkey)` method, computed `read` getter, updated `copyWith` with high-water-mark merge    |
| 5   | `hostr_sdk/lib/usecase/messaging/thread/thread.dart`                                      | Process kind:16 wraps to build `seenUntil` map; add `markAsRead()` method; `shouldSendReceipt` guard logic; call `SeenService` to send receipts         |
| 6   | `hostr_sdk/lib/usecase/user_subscriptions/user_subscriptions.dart`                        | Route incoming `kind:16` rumours to `SeenService` (or emit on a new `seenReceipts$` stream alongside `messages$`)                                       |
| 7   | `hostr_sdk/lib/usecase/messaging/messaging.dart`                                          | Add `broadcastSeenReceipt()` method (creates kind:16 rumor, wraps, broadcasts — or this lives in `SeenService` calling the existing `_broadcastRumour`) |
| 8   | `hostr_sdk/lib/usecase/messaging/threads.dart`                                            | Route kind:16 events to threads for state update (or delegate to `SeenService`)                                                                         |
| 9   | `app/lib/presentation/component/widgets/inbox/inbox_item.dart`                            | Show ✓✓ when `read == true`; show unread count badge; bold styling for unread conversations                                                             |
| 10  | `app/lib/presentation/component/widgets/inbox/inbox_thread_list.dart`                     | Pass `unreadCount` through to inbox items                                                                                                               |
| 11  | `app/lib/logic/cubit/messaging/thread.cubit.dart`                                         | Call `thread.markAsRead()` when user views thread; expose `unreadCount(ourPubkey)` and `seenUntil` map to the UI                                        |
| 12  | `app/lib/presentation/screens/shared/inbox/thread/thread.dart` (or message bubble widget) | Show ✓✓ / "Read" indicator on our sent messages based on `seenUntil[counterparty]`                                                                      |

### Models — no changes needed

- `SeenStatus` (`kind:16`) model already exists with `counterpartyPubKey`,
  `seenUntil`, `seenUntilAt` getters, and `SeenStatus.create()` factory.
- `kNostrKindSeenStatus = 16` already defined in `kinds.dart` and in
  `kHostrOnlyKinds` (hostr relay only).

---

## Risks & Mitigations

| Risk                                              | Mitigation                                                                                                                                                                                                                                                                         |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Bloat from non-replaceable wraps**              | Bounded by "one per read session" rule. ~20–50 receipts per conversation lifetime. Acceptable overhead on top of DM wraps. Relay can GC old receipts as future optimization.                                                                                                       |
| **No merged NIP — hostr-only feature**            | All custom kinds in `kHostrOnlyKinds`, forced to hostr relay. No interop expectation with Amethyst/Coracle. We can change the scheme without migration.                                                                                                                            |
| **Late-arriving messages after seen receipt**     | `seen_until` is a timestamp high-water mark. A message arriving late with an earlier timestamp will be correctly marked as read if `createdAt ≤ seen_until`. A message with a _later_ timestamp won't be falsely marked — it's genuinely unread.                                   |
| **Clock skew**                                    | Nostr events use server-validated unix timestamps. Minor skew (seconds) doesn't affect UX. Major skew (minutes) is a general Nostr problem, not specific to read receipts.                                                                                                         |
| **Cross-device sync delay**                       | Self-wrapped receipts propagate through the relay. If a user reads on phone, desktop will sync when it next receives events. Small delay is acceptable.                                                                                                                            |
| **Privacy: relay operator sees kind:1059 volume** | Already the case for DMs. Seen receipts are indistinguishable from DMs to the relay (both are kind:1059 gift wraps). No additional metadata leaked.                                                                                                                                |
| **Privacy: counterparty knows when we read**      | Inherent to read receipts. Could add a user preference to disable sending seen receipts (unread counts would still work if we track the "last opened" timestamp ephemerally in memory while the thread is open, but counts wouldn't survive app restart without our own receipts). |

---

## Phasing

### Phase 1 — Send & receive seen receipts + unread counts

- [ ] Add `seenUntil` map (`Map<String, int>`) to `ThreadState` + `copyWith`
- [ ] Add `unreadCount(String pubkey)` method to `ThreadState`
- [ ] Compute `read` getter from `seenUntil` map vs our latest sent message
- [ ] Process incoming kind:16 gift wraps in Thread → update `seenUntil` map
- [ ] `SeenService`: create `kind:16` rumor, gift-wrap, broadcast (no expiration)
- [ ] `shouldSendReceipt` guard (compare `seenUntil[ourPubkey]` vs latest counterparty msg)
- [ ] Debounce seen receipt sends (~1–2s)
- [ ] Route incoming `kind:16` rumours through `UserSubscriptions`
- [ ] Show unread badge count on `InboxItemView`
- [ ] Show ✓✓ in `InboxItemView` when `read == true`
- [ ] Bold/dim styling for unread vs read conversations
- [ ] `Threads`: expose `convosWithUnread` count
- [ ] Unit tests for `SeenService`, guard logic, state computation, map merging

### Phase 2 — Thread view read indicators

- [ ] Show ✓✓ / "Read" on our sent messages in the message thread view
- [ ] Show on the last read message only (not every message)
- [ ] Support multi-counterparty threads (group read indicators)
- [ ] Optional: tap to see "Read at HH:MM" timestamp

### Phase 3 — Typing indicator (future, deferred)

- [ ] `TypingIndicatorService` — `kind:10018` ephemeral
- [ ] UI: "typing…" bubble in thread view
- [ ] Opt-in setting in user preferences

---

## Appendix: Prior Art & References

- [NIP-17 spec](https://github.com/nostr-protocol/nips/blob/master/17.md) — base DM protocol
- [NIP-59 spec](https://github.com/nostr-protocol/nips/blob/master/59.md) — gift wrap / seal
- [PR #2000](https://github.com/nostr-protocol/nips/pull/2000) — vitorpamplona's `kind:10017` heartbeat
- [PR #1761](https://github.com/nostr-protocol/nips/pull/1761) — kehiy's bloom filter seen events
- [PR #1994](https://github.com/nostr-protocol/nips/pull/1994) — fiatjaf's "seen" event (closed)
- [PR #1405](https://github.com/nostr-protocol/nips/pull/1405) — staab's read-status-2 (closed)
- [Issue #2002](https://github.com/nostr-protocol/nips/issues/2002) — liveness pulse umbrella issue
- [Coracle removal PR](https://github.com/coracle-social/coracle/pull/504) — staab's post-mortem
