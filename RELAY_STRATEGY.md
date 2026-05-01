# Relay Connection Strategy — Implementation Plan

> Companion to [RELAYS.md](RELAYS.md). This document focuses on three concrete questions:
> **A)** How to discover a user's relay list at sign-in,
> **B)** When/how to connect to other users' relays at runtime, and
> **C)** How to refresh state when relays change mid-session.

---

## A. Relay Discovery at Sign-In

### A.1 The Problem

When a user signs in with an existing nsec, their NIP-65 (kind `10002`) relay list may live on relays we don't know about. Our current bootstrap set (`relay.hostr.network` + `relay.damus.io`) won't find users whose events only exist on `purplepag.es`, `relay.snort.social`, etc.

### A.2 Discovery Waterfall

Execute sequentially, short-circuit on first success:

```
Phase 1 — Bootstrap relays
  Query kind:10002 + kind:0 for pubkey from all bootstrap relays.
  If found → done.

Phase 2 — Well-known directory relays (ephemeral connections)
  Connect temporarily to:
    wss://purplepag.es          (de-facto NIP-65 directory)
    wss://relay.nostr.band      (indexing relay)
    wss://relay.nos.social
  Query kind:10002 + kind:0.
  Disconnect after query completes.
  If found → done.

Phase 3 — Manual entry (user action)
  Show the "Add Your Relay" prompt (see §A.3).
  User enters their relay URL → connect → query kind:10002 + kind:0.
  If found → done.

Phase 4 — Give up gracefully
  Start with bootstrap relays only.
  Publish fresh kind:10002 with hostr relay.
```

### A.3 UI: Post-Login Relay Setup (EditProfileScreen Second Pane)

After the startup gate resolves `hasMetadata: false`, the user is routed to `EditProfileScreen`. We add relay discovery as a **second `AppPane`** in the `AppPaneLayout`:

```
┌─────────────────────────────────────────────────────────────┐
│  EditProfileScreen                                          │
│                                                             │
│  ┌─────────────────────────┐  ┌──────────────────────────┐  │
│  │  Pane 1 (flex: 2)       │  │  Pane 2 (flex: 1)        │  │
│  │                         │  │                           │  │
│  │  Profile Setup           │  │  🔗 Your Relays          │  │
│  │  ─────────────────────  │  │  ─────────────────────── │  │
│  │  [Avatar / Banner]      │  │                           │  │
│  │  Name: ___________      │  │  ✅ relay.hostr.network   │  │
│  │  About: __________      │  │  ✅ relay.damus.io        │  │
│  │  NIP-05: _________      │  │                           │  │
│  │  LN addr: ________     │  │  "Already set up a        │  │
│  │                         │  │   profile on another      │  │
│  │                         │  │   relay?"                  │  │
│  │                         │  │                           │  │
│  │                         │  │  [ + Add Relay ]          │  │
│  │                         │  │                           │  │
│  │  [ Save Profile ]       │  │  Once added, your         │  │
│  │                         │  │  existing profile will    │  │
│  └─────────────────────────┘  │  be loaded automatically. │  │
│                               └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Compact / mobile layout:** The second pane becomes a collapsible section or a bottom-sheet prompt at the top of the edit profile page:

```
┌──────────────────────────────┐
│  Time to set up your profile │
│                              │
│  Already set up a profile    │
│  on another relay?           │
│  [ + Add Relay ]             │
│                              │
│  ── Your Relays ──           │
│  ✅ relay.hostr.network      │
│  ✅ relay.damus.io           │
│                              │
│  ── Profile ──               │
│  [Avatar / Banner]           │
│  Name: ___________           │
│  ...                         │
└──────────────────────────────┘
```

### A.4 Flow When User Adds a Relay on This Screen

```
1. User taps "+ Add Relay" → opens RelayAddStep modal (already exists)
2. User enters wss://their-relay.example.com
3. hostr.relays.add(url) → connects to relay
4. Query kind:10002 + kind:0 for user's pubkey on new relay
5. If profile metadata found:
   a. Populate the edit-profile form with fetched metadata
   b. Connect to any additional relays discovered in their NIP-65
   c. Show toast: "Profile loaded from their-relay.example.com"
6. If not found:
   a. Relay is added (user may just want to publish there)
   b. Form stays as-is
```

**Implementation detail:** The `ProfileProvider` (or equivalent metadata provider) should expose a `refresh(pubkey)` method. When a relay is added on the edit-profile screen, call `refresh()` to re-query metadata across all now-connected relays and update the form controllers.

### A.5 Discovery Relay Config

```dart
/// Relays queried ephemerally during sign-in, NOT persisted.
final List<String> discoveryRelays = [
  'wss://purplepag.es',
  'wss://relay.nostr.band',
  'wss://relay.nos.social',
];
```

Add to `HostrConfig` alongside `bootstrapRelays`. The startup gate's relay-list step should query these if bootstrap queries return nothing.

---

## B. Connecting to Other Users' Relays at Runtime

### B.1 How NDK JIT Handles This Today

NDK's **JIT (Just-In-Time) engine** implements the **outbox model** (NIP-65):

| Operation                      | NDK Behavior                                                                         |
| ------------------------------ | ------------------------------------------------------------------------------------ |
| **Query by author**            | Looks up the author's kind:10002 **write** relays, connects on-demand, queries there |
| **Query by tag (p-tagged)**    | Looks up the tagged user's **read** relays                                           |
| **Broadcast own event**        | Sends to user's own **write** relays                                                 |
| **Send gift wrap (kind:1059)** | Sends to recipient's **inbox** relays (kind:10050)                                   |

This means NDK **automatically** opens ephemeral connections to other users' relays when needed. We don't need to manually manage cross-user relay connections for most cases.

### B.2 When We Need Explicit Relay Targeting

Despite the JIT engine, there are cases where we must be explicit:

#### Gift Wraps (NIP-17 DMs, Reservation Negotiations)

**Standard:** Send kind:1059 to the recipient's **kind:10050 DM relay list**.

**Current state:** NDK handles this if the recipient has published a kind:10050. However:

- We do **not** publish kind:10050 for our own users yet → other Nostr clients can't DM them
- If a counterparty has no kind:10050, NDK falls back to their NIP-65 read relays

**Action items:**

1. On login, publish kind:10050 with at least `relay.hostr.network` (see [RELAYS.md §9.2](RELAYS.md))
2. When sending gift wraps, let NDK handle relay selection (it already does the right thing)
3. If NDK can't find a recipient's 10050 or NIP-65, fall back to sending via hostr relay

#### Reservations (kind:32122, 32126)

**Should reservation events carry relay hints?** Yes.

Per NIP-01, `p` tags support a relay hint in the 3rd position:

```json
["p", "<seller-pubkey>", "wss://seller-relay.example.com"]
["p", "<buyer-pubkey>", "wss://buyer-relay.example.com"]
["p", "<escrow-pubkey>", "wss://escrow-relay.example.com"]
```

**Why relay hints on reservations matter:**

- A third-party client processing a reservation needs to find all participants
- If the seller's NIP-65 isn't cached, the relay hint provides a starting point
- The escrow daemon may not have the buyer's NIP-65 cached

**Implementation:** When creating reservation events, populate the `p` tag relay hint with the participant's **first write relay** from their NIP-65 (or `relay.hostr.network` as fallback):

```dart
String relayHintFor(String pubkey) {
  final nip65 = ndk.userRelayLists.getWriteRelays(pubkey);
  return nip65.isNotEmpty ? nip65.first : config.hostrRelay;
}

// In reservation event construction:
["p", sellerPubkey, relayHintFor(sellerPubkey)]
["p", buyerPubkey, relayHintFor(buyerPubkey)]
["p", escrowPubkey, relayHintFor(escrowPubkey)]
```

#### Listings (kind:32121)

**Should listings carry relay hints?** Yes, on the `p` tag (host's pubkey):

```json
["p", "<host-pubkey>", "wss://host-write-relay.example.com"]
```

This helps other clients find the host's profile metadata without a separate NIP-65 lookup.

#### Escrow Events (kind:17388, 30302, 30303)

Same pattern — include relay hints on `p` tags referencing other participants.

### B.3 Relay Hint Standards Summary

| Tag                    | Relay Hint Position | What to Put                                          |
| ---------------------- | ------------------- | ---------------------------------------------------- |
| `["p", pubkey, ???]`   | 3rd element         | That user's first NIP-65 write relay, or hostr relay |
| `["e", event-id, ???]` | 3rd element         | Relay where that event was first seen / published    |
| `["a", address, ???]`  | 3rd element         | Relay where the addressable event lives              |

These hints are **advisory** — clients may ignore them. But they dramatically improve discoverability in a multi-relay world.

### B.4 Sending To All Participants' Relays

For **reservation state transitions** (kind:32126), the event should reach all participants:

```
Publish to:
  1. Author's own write relays (NDK outbox handles this)
  2. Hostr relay (always — domain event rule)
  3. Each p-tagged participant's read relays (NDK handles via outbox model)
```

NDK's outbox model already does (1) and (3) when you broadcast a tagged event. We just need to ensure (2) — always include hostr relay in the broadcast relay set for domain events.

### B.5 The Escrow Daemon's Relay Needs

The escrow daemon is a special case — it's a headless service that needs to:

1. Subscribe to reservation events across all user relays
2. Send gift wraps to buyers and sellers

**Strategy for the daemon:**

- Connect to hostr relay (guaranteed to have all domain events)
- Connect to bootstrap relays
- On encountering a new participant pubkey: look up their NIP-65, connect to their relays
- For gift wraps: look up recipient's kind:10050, send there
- The daemon should maintain a larger connection pool than mobile clients (it's server-side)

---

## C. Refreshing State When Relays Change Mid-Session

### C.1 What Needs Refreshing

When a user adds a relay at runtime (via Settings → Relays → Add):

| Data                      | Refresh Needed?           | Why                                                            |
| ------------------------- | ------------------------- | -------------------------------------------------------------- |
| Own profile (kind:0)      | ✅ May find newer version | User may have updated profile on new relay from another client |
| Own listings (kind:32121) | ⚠️ Low priority           | User's own listings are authoritative locally                  |
| Inbox (gift wraps)        | ✅ Yes                    | May have pending DMs on new relay                              |
| NIP-65 relay list         | ✅ Must republish         | Include new relay in our published NIP-65                      |
| Other users' events       | ❌ No immediate need      | NDK will query new relay on next relevant lookup               |

### C.2 Proposed Refresh Flow

```
User adds relay URL via RelayAddStep:

1. hostr.relays.add(url)
   → Connects to relay
   → Persists to RelayStorage

2. Republish NIP-65 (kind:10002)
   → Add new relay as read+write
   → Broadcast updated 10002 to ALL connected relays

3. Republish DM relay list (kind:10050)
   → Add new relay to inbox list
   → Broadcast updated 10050 to ALL connected relays

4. Re-query own metadata (kind:0)
   → hostr.metadata.loadMetadata(pubkey, forceRefresh: true)
   → If newer version found on new relay, update local state

5. Re-subscribe to gift wraps on new relay
   → Extend the existing kind:1059 subscription to include new relay
   → Process any gift wraps that were waiting there

6. Background backfill (non-blocking)
   → Publish active listings, escrow config to new relay
   → See RELAYS.md §6.3 for full backfill strategy
```

### C.3 Implementation: Relay Change Event Bus

Add a stream/event that fires when relays change:

```dart
// In Relays usecase
final _relayChangeController = StreamController<RelayChangeEvent>.broadcast();
Stream<RelayChangeEvent> get onRelayChange => _relayChangeController.stream;

Future<void> add(String url) async {
  await ndk.relays.connectRelay(url);
  await _relayStorage.add(url);
  _relayChangeController.add(RelayAdded(url));
}

Future<void> remove(String url) async {
  await ndk.relays.closeRelay(url);
  await _relayStorage.remove(url);
  _relayChangeController.add(RelayRemoved(url));
}
```

Consumers that care about relay changes:

- **NIP-65 publisher** → listens, republishes kind:10002
- **DM relay publisher** → listens, republishes kind:10050
- **Gift wrap subscriber** → listens, extends subscription
- **Backfill worker** → listens, starts background publish

### C.4 Priority

This (C) is the **lowest priority** of the three questions. Most users will set up relays once and rarely change them. The critical paths are (A) sign-in discovery and (B) cross-user relay communication.

---

## NDK JIT Engine — How It Works

For reference, here's how NDK's JIT engine handles relays under the hood:

1. **Startup:** Connects to all bootstrap relays.
2. **NIP-65 cache:** Maintains an in-memory cache of known users' relay lists (kind:10002).
3. **On query by author:** Checks the NIP-65 cache for the author's write relays. If found, opens JIT connections to those relays for the query. If not found, queries bootstrap relays.
4. **On broadcast:** Sends to the author's write relays (from NIP-65) + all currently connected relays.
5. **On gift wrap send:** Looks up recipient's kind:10050 inbox relays. Falls back to their NIP-65 read relays.
6. **Connection lifecycle:** JIT connections may be closed after a period of inactivity (managed by NDK internally).

**Implication:** We don't need to manually manage connections to other users' relays. NDK does it. Our job is to:

- Ensure our user's NIP-65 and kind:10050 are published and accurate
- Include relay hints in tags so NDK (and other clients) can find events efficiently
- Always include hostr relay for domain-specific events

---

## Summary of Action Items

### Must-Have (Pre-Launch)

1. **Add `discoveryRelays` config** — ephemeral relays for sign-in discovery waterfall
2. **Implement discovery waterfall** in startup gate's relay-list step
3. **Add relay setup pane** to EditProfileScreen (second `AppPane` on wide, collapsible section on compact)
4. **Publish kind:10050** (DM relay list) on login — at minimum with hostr relay
5. **Add relay hints** to `p` tags on listings, reservations, escrow events, and transitions
6. **Always include hostr relay** in broadcast relay set for domain events (kinds 32121, 32122, 32124, 32126, 303xx)

### Should-Have (Launch + 2 weeks)

7. **Relay change event bus** — stream that fires on add/remove, triggers NIP-65 + 10050 republish
8. **Gift wrap re-subscription** on relay add
9. **Selective backfill** on relay add (profile, listings, escrow config → immediate; reservations, reviews → background)
10. **Connection cap** — max 12–15 concurrent relay connections

### Nice-to-Have (Launch + 1 month)

11. **Relay health scoring** — track latency and failure rates, prefer healthy relays
12. **Periodic listing refresh** — re-publish active listings weekly to catch evicted events
13. **DM delivery retry queue** — exponential backoff for failed gift wrap sends
