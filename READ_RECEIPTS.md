# Read Receipts — Implementation Plan

> **Status:** Iteration 3 — Gift-wrapped `kind:16` seen receipts, no expiration
> **Decision:** Use the same gift-wrap pipeline as regular DMs. One seen
> receipt per read session, sent as the chronologically last event in the
> conversation. Never set an expiration tag — these wraps persist forever.

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
  ┌─ Check: are there counterparty messages newer than localSeenUntil?
  │     │
  │    NO ──▶ Do nothing (already up to date)
  │     │
  │    YES
  │     ▼
  │  Update localSeenUntil = max(counterparty message timestamps)
  │     │
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
  │     ├──▶ seen_until = timestamp of latest message in conversation
  │     ├──▶ p = counterparty pubkey
  │     │
  │     ▼
  │  Gift-wrap via Messaging._broadcastRumour()
  │     │
  │     ├──▶ Wrap to counterparty (they learn we read their messages)
  │     └──▶ Wrap to self (so our other clients can sync our read state)
  │
  └─ Emit updated ThreadState with new localSeenUntil
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

### Flow 2: Receiving a Counterparty's Seen Receipt (they read our messages)

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
                ├──▶ Extract counterpartyPubKey (the "p" tag — that's us)
                ├──▶ Extract seenUntil timestamp
                │
                ▼
          Route to the Thread for this conversation
                │
                ▼
          Update ThreadState:
                │
                ├──▶ counterpartySeenUntil = max(existing, new seenUntil)
                │    (high-water mark — never decreases)
                │
                └──▶ read = (counterpartySeenUntil >= our latest sent message's createdAt)
                │
                ▼
          Emit state → UI shows ✓✓
```

**Key details:**

- The `counterpartySeenUntil` value only ever increases. If we receive an
  older seen receipt (e.g. from a delayed relay sync), we ignore it.
- The `read` boolean on `ThreadState` is `true` when the counterparty's
  `seenUntil` is ≥ the `createdAt` of our most recently sent message.
- When we wrap the seen receipt to _ourselves_, our other clients receive it
  too. This lets us sync our own `localSeenUntil` across devices: if the
  inner rumor is from our own pubkey and is kind:16, update `localSeenUntil`
  for that thread.

### Flow 3: Receiving Our Own Seen Receipt (cross-device sync)

```
Gift wrap arrives, inner rumor kind:16, rumor.pubkey == our pubkey
        │
        ▼
  This is a receipt WE sent from another device
        │
        ▼
  Extract seenUntil, identify the thread via the "p" tag
        │
        ▼
  Update localSeenUntil = max(existing, seenUntil)
        │
        ▼
  Recompute unreadCount for that thread
```

This gives us cross-device read sync for free — read on phone, see it
reflected on desktop — because seen receipts are wrapped to self.

---

## Unread Conversation Count

### Per-thread unread count

**Local-first**, computed entirely from local state:

```
unreadCount = thread.messages
  .where(msg.pubKey != ourPubkey)            // only counterparty messages
  .where(msg.createdAt > localSeenUntil)     // newer than our last read
  .length
```

**`localSeenUntil`** is a per-thread unix timestamp stored in local persistence
(e.g. `HydratedStorage` / shared preferences / Hive). It tracks the timestamp
up to which we've read messages in this conversation.

**Lifecycle:**

1. Thread is created → `localSeenUntil = 0` → all counterparty messages are unread
2. User opens the thread → `localSeenUntil` = latest message's `createdAt`
   → `unreadCount` drops to 0
3. New messages arrive while thread is open → `localSeenUntil` updates in
   real-time as messages appear on screen
4. User leaves thread → `localSeenUntil` is persisted
5. New messages arrive while thread is closed → `unreadCount` increases
6. Cross-device sync: if we receive our own kind:16 with a higher
   `seenUntil`, update `localSeenUntil` and recompute

**Important:** `kind:16` seen receipt events themselves should NOT count
toward `unreadCount`. They're metadata, not user-visible messages. When
computing unread count, filter to only `kind:14` DM messages.

### Global unread count (inbox badge)

```
totalUnread = threads.values.sum(thread.unreadCount)
```

Or, if only a count of unread _conversations_ is needed:

```
unreadConversationCount = threads.values.where(thread.unreadCount > 0).length
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
        ├──▶ threadState.read         → InboxItemView.read
        ├──▶ threadState.received     → InboxItemView.received    (existing)
        ├──▶ threadState.unreadCount  → InboxItemView.unreadCount (new)
        └──▶ threadState.isLastMessageOurs → InboxItemView.sentByUs
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
    ├──▶ counterpartySeenUntil: int?     (from their latest kind:16)
    ├──▶ messages: List<Message>          (kind:14 DMs only — seen receipts filtered out)
    │
    ▼
  For each message bubble:
    │
    ├──▶ msg.pubKey == ourPubkey?
    │       │
    │      YES ──▶ isRead = msg.createdAt <= counterpartySeenUntil
    │       │         │
    │       │        YES ──▶ show ✓✓ (or "Read") below bubble
    │       │        NO  ──▶ show ✓ if received, else nothing
    │       │
    │      NO ──▶ It's their message, no read indicator needed
```

### Filtering seen receipts from the message list

`kind:16` seen receipts should NOT appear as message bubbles in the thread
view. When building the list of messages for display:

- Include: `kind:14` DM messages
- Exclude: `kind:16` seen status events

The seen receipt data is consumed as _state_ (updating `counterpartySeenUntil`
and `localSeenUntil`), not displayed as _content_.

---

## ThreadState Changes

Current `ThreadState` fields:

```dart
final bool read;       // currently always false — never set
final bool received;   // set by _computeReceived() via heartbeat
```

### New / modified fields

```dart
// Persisted locally — tracks our own read position
final int localSeenUntil;            // unix timestamp, default 0

// From counterparty's latest kind:16 seen receipt
final int? counterpartySeenUntil;    // unix timestamp, null until first receipt

// Computed
int get unreadCount => messages
    .where((m) => m.pubKey != ourPubkey && m.createdAt > localSeenUntil)
    .length;

// Updated: now actually computed from counterpartySeenUntil
bool get read {
  if (counterpartySeenUntil == null) return false;
  final ourLatest = messages
      .where((m) => m.pubKey == ourPubkey)
      .map((m) => m.createdAt)
      .fold(0, (a, b) => a > b ? a : b);
  return ourLatest > 0 && counterpartySeenUntil! >= ourLatest;
}
```

### `copyWith` update

Add `localSeenUntil` and `counterpartySeenUntil` to the existing `copyWith`
method. Both should use high-water-mark semantics: never decrease.

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
              Thread updates counterpartySeenUntil (or localSeenUntil
              if the receipt is from our own pubkey — cross-device sync)
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

The Thread needs to know about the most recent event _including_ seen receipts,
even though seen receipts are filtered out of the visible message list. Two
approaches:

**Approach A: Track `ourLatestSeenReceiptAt` separately**

Store the `createdAt` timestamp of our most recently sent `kind:16` for this
thread. Compare it against the latest DM's `createdAt`:

```
shouldSendReceipt =
    hasUnreadCounterpartyMessages
    && (ourLatestSeenReceiptAt == null
        || latestMessage.createdAt > ourLatestSeenReceiptAt)
```

This is simpler — we don't need to mix seen receipts into the message list.

**Approach B: Include seen receipts in the raw event list**

Keep a parallel list of all events (DMs + receipts) and check the tail.
More general but adds complexity.

**Recommendation: Approach A.** Add `ourLatestSeenReceiptAt: int?` to
`ThreadState`. Update it when we send a receipt, and when we receive our own
receipt via cross-device sync. The guard check is a simple timestamp comparison.

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
| 4   | `hostr_sdk/lib/usecase/messaging/thread/state.dart`                                       | Add `localSeenUntil`, `counterpartySeenUntil`, `ourLatestSeenReceiptAt`, computed `unreadCount`, updated `read` getter, updated `copyWith`              |
| 5   | `hostr_sdk/lib/usecase/messaging/thread/thread.dart`                                      | Call `SeenService` on state changes; add `markAsRead()` method; subscribe to incoming seen receipts; guard logic for "should send receipt"              |
| 6   | `hostr_sdk/lib/usecase/user_subscriptions/user_subscriptions.dart`                        | Route incoming `kind:16` rumours to `SeenService` (or emit on a new `seenReceipts$` stream alongside `messages$`)                                       |
| 7   | `hostr_sdk/lib/usecase/messaging/messaging.dart`                                          | Add `broadcastSeenReceipt()` method (creates kind:16 rumor, wraps, broadcasts — or this lives in `SeenService` calling the existing `_broadcastRumour`) |
| 8   | `hostr_sdk/lib/usecase/messaging/threads.dart`                                            | Route kind:16 events to threads for state update (or delegate to `SeenService`)                                                                         |
| 9   | `app/lib/presentation/component/widgets/inbox/inbox_item.dart`                            | Show ✓✓ when `read == true`; show unread count badge; bold styling for unread conversations                                                             |
| 10  | `app/lib/presentation/component/widgets/inbox/inbox_thread_list.dart`                     | Pass `unreadCount` through to inbox items                                                                                                               |
| 11  | `app/lib/logic/cubit/messaging/thread.cubit.dart`                                         | Call `thread.markAsRead()` when user views thread; expose `unreadCount` and `counterpartySeenUntil` to the UI                                           |
| 12  | `app/lib/presentation/screens/shared/inbox/thread/thread.dart` (or message bubble widget) | Show ✓✓ / "Read" indicator on our sent messages based on `counterpartySeenUntil`                                                                        |

### Models — no changes needed

- `SeenStatus` (`kind:16`) model already exists with `counterpartyPubKey`,
  `seenUntil`, `seenUntilAt` getters, and `SeenStatus.create()` factory.
- `kNostrKindSeenStatus = 16` already defined in `kinds.dart` and in
  `kHostrOnlyKinds` (hostr relay only).

---

## Persistence

### What needs to persist locally

| Data                                | Storage                            | Reason                                                                                                                                              |
| ----------------------------------- | ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `localSeenUntil` per thread         | HydratedStorage / shared prefs     | Survives app restart. Without this, all conversations show as unread on relaunch.                                                                   |
| `counterpartySeenUntil` per thread  | Not persisted — derived from relay | On app launch, we re-subscribe and receive the counterparty's latest kind:16. State is reconstructed from the relay.                                |
| `ourLatestSeenReceiptAt` per thread | HydratedStorage / shared prefs     | Needed for the "last message" dedup guard. Could also be derived from relay (we receive our own receipts), but local is faster for the guard check. |

### Key for local storage

Use the thread's anchor (conversation identifier hash) as the key:

```
"seen:$anchor:localSeenUntil"  → int
"seen:$anchor:ourLatestReceiptAt"  → int
```

---

## Risks & Mitigations

| Risk                                              | Mitigation                                                                                                                                                                                                                                       |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Bloat from non-replaceable wraps**              | Bounded by "one per read session" rule. ~20–50 receipts per conversation lifetime. Acceptable overhead on top of DM wraps. Relay can GC old receipts as future optimization.                                                                     |
| **No merged NIP — hostr-only feature**            | All custom kinds in `kHostrOnlyKinds`, forced to hostr relay. No interop expectation with Amethyst/Coracle. We can change the scheme without migration.                                                                                          |
| **Late-arriving messages after seen receipt**     | `seen_until` is a timestamp high-water mark. A message arriving late with an earlier timestamp will be correctly marked as read if `createdAt ≤ seen_until`. A message with a _later_ timestamp won't be falsely marked — it's genuinely unread. |
| **Clock skew**                                    | Nostr events use server-validated unix timestamps. Minor skew (seconds) doesn't affect UX. Major skew (minutes) is a general Nostr problem, not specific to read receipts.                                                                       |
| **Cross-device sync delay**                       | Self-wrapped receipts propagate through the relay. If a user reads on phone, desktop will sync when it next receives events. Small delay is acceptable.                                                                                          |
| **Privacy: relay operator sees kind:1059 volume** | Already the case for DMs. Seen receipts are indistinguishable from DMs to the relay (both are kind:1059 gift wraps). No additional metadata leaked.                                                                                              |
| **Privacy: counterparty knows when we read**      | Inherent to read receipts. Could add a user preference to disable sending seen receipts (still track unread counts locally).                                                                                                                     |

---

## Phasing

### Phase 0 — Local unread counts (quick win, no relay interaction)

- [ ] Add `localSeenUntil` to `ThreadState` + `copyWith`
- [ ] Compute `unreadCount` getter in `ThreadState`
- [ ] Persist `localSeenUntil` in local storage
- [ ] Update `localSeenUntil` when user opens thread / scrolls to bottom
- [ ] Show unread badge count on `InboxItemView`
- [ ] Bold/dim styling for unread vs read conversations

This gives users unread counts **immediately** with zero protocol work. Purely
local — the counterparty doesn't know you've read their messages, but your own
inbox shows accurate badges.

### Phase 1 — Send & receive seen receipts

- [ ] `SeenService`: create `kind:16` rumor, gift-wrap, broadcast
- [ ] Implement the "last message" guard (don't send if last event is our receipt)
- [ ] Debounce seen receipt sends (~1–2s)
- [ ] Route incoming `kind:16` rumours through `UserSubscriptions`
- [ ] Update `counterpartySeenUntil` on `ThreadState`
- [ ] Compute `read` from `counterpartySeenUntil` vs our latest sent message
- [ ] Show ✓✓ in `InboxItemView` when `read == true`
- [ ] Cross-device sync: process own kind:16 receipts to update `localSeenUntil`
- [ ] Unit tests for `SeenService`, guard logic, state computation

### Phase 2 — Thread view read indicators

- [ ] Show ✓✓ / "Read" on our sent messages in the message thread view
- [ ] Show on the last read message only (not every message)
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
