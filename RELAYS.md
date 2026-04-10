# Relay Strategy — Going Live

> Plan for transitioning from hostr-only relay to a multi-relay, open Nostr ecosystem.

---

## Table of Contents

1. [Current State](#1-current-state)
2. [Problem Statement](#2-problem-statement)
3. [Sign-In & Relay Discovery](#3-sign-in--relay-discovery)
4. [Bootstrap Relay Set](#4-bootstrap-relay-set)
5. [Publishing Strategy (Which Relays Get Which Events)](#5-publishing-strategy)
6. [Relay Addition — Backfilling Existing Events](#6-relay-addition--backfilling-existing-events)
7. [Relay Removal](#7-relay-removal)
8. [Hostr Relay Special Role](#8-hostr-relay-special-role)
9. [Privacy-Sensitive Events](#9-privacy-sensitive-events)
10. [Reading Strategy (Where to Query)](#10-reading-strategy)
11. [Edge Cases & Failure Modes](#11-edge-cases--failure-modes)
12. [Implementation Roadmap](#12-implementation-roadmap)
13. [Open Questions](#13-open-questions)

---

## 1. Current State

| Aspect                      | Today                                                                    |
| --------------------------- | ------------------------------------------------------------------------ |
| **Hostr relay**             | `wss://relay.hostr.network` — always connected, always in NIP-65         |
| **Bootstrap relays (prod)** | `wss://relay.damus.io` + hostr relay                                     |
| **NIP-65 sync**             | ✅ On login: fetch kind:10002, connect to listed relays                  |
| **NIP-65 publish**          | ✅ On login: ensure hostr relay is in the user's kind:10002 (read+write) |
| **User relay management**   | ✅ Add/remove relays via Settings UI; bootstrap relays cannot be removed |
| **Relay persistence**       | Per-pubkey SQLite storage; falls back to bootstrap relays for new users  |
| **Event broadcasting**      | NDK outbox model (user's NIP-65 write relays + connected relays)         |
| **DMs**                     | NIP-17 gift wraps routed to recipient's inbox relays via NDK             |

**Key gap:** In practice, most users today only have hostr's relay. The system technically supports multi-relay, but the strategy for a heterogeneous relay environment hasn't been stress-tested.

---

## 2. Problem Statement

When we go live and users bring their own nsec (with existing relay lists pointing to Damus, nos.lol, relay.nostr.band, etc.), several questions arise:

1. **Discovery:** How do we find an existing user's metadata and relay list when we only know their pubkey?
2. **Availability:** Will our domain-specific events (listings, reservations, escrow) survive on third-party relays that may not understand or index them?
3. **Consistency:** When a user adds a new relay, do historical events need to be replicated there?
4. **Privacy:** Which events must NEVER go to third-party relays?
5. **Reliability:** What happens when third-party relays are down, rate-limit, or reject our events?

---

## 3. Sign-In & Relay Discovery

### 3.1 New User (fresh keypair)

```
1. Generate keypair
2. Connect to bootstrap relays (hostr relay + well-known relays)
3. Publish NIP-65 relay list with hostr relay as read+write
4. Publish kind:0 profile metadata
5. → User starts with a known, working relay set
```

**No changes needed.** This flow works today.

### 3.2 Existing User (imports nsec)

This is the critical path. The user may already have:

- A kind:0 profile on relays we don't know about
- A kind:10002 (NIP-65) relay list pointing to relays we're not connected to
- A kind:10050 (NIP-17 DM) relay list for their inbox

**Current flow:**

```
1. Derive pubkey from nsec
2. Connect to bootstrap relays
3. Query kind:10002 for this pubkey from bootstrap relays  ← PROBLEM
4. Connect to discovered relays
5. Ensure hostr relay is in their NIP-65
```

**The problem:** Step 3 assumes the user's NIP-65 exists on one of our bootstrap relays. If the user only uses `wss://relay.snort.social` and `wss://purplepag.es`, we'll never find their relay list.

### 3.3 Proposed Solution: Relay Discovery Waterfall

On sign-in with an existing nsec, execute this discovery sequence:

```
Phase 1 — Bootstrap query
  → Query kind:10002 + kind:0 for pubkey from all bootstrap relays
  → If found: proceed with discovered relay list

Phase 2 — Well-known relay directories (if Phase 1 fails)
  → Query purplepag.es (the de-facto NIP-65 directory relay)
  → Query relay.nostr.band (indexing relay)
  → Query relay.nos.social
  → If found: connect to discovered relays, proceed

Phase 3 — NIP-05 lookup (if Phase 2 fails)
  → If user provides a NIP-05 identifier (user@domain.com),
    resolve via /.well-known/nostr.json to get relay hints
  → Connect to hinted relays, query for kind:10002

Phase 4 — Fallback (if all above fail)
  → User has no discoverable relay list
  → Start with bootstrap relays only
  → Prompt user: "We couldn't find your existing relays. Add them manually?"
  → Publish fresh NIP-65 with hostr relay
```

### 3.4 Implementation: Discovery Relays (New Config)

Add a new config list distinct from bootstrap relays:

```dart
/// Relays queried during sign-in discovery but NOT permanently connected to.
/// These are high-availability directory/indexing relays.
final List<String> discoveryRelays;
```

**Production values:**

```dart
discoveryRelays: [
  'wss://purplepag.es',         // NIP-65 directory relay
  'wss://relay.nostr.band',     // Indexing relay
  'wss://relay.nos.social',     // Popular relay
  'wss://relay.damus.io',       // Popular relay (already bootstrap)
],
```

These relays are connected **temporarily** during discovery, then disconnected unless they appear in the user's NIP-65.

---

## 4. Bootstrap Relay Set

### 4.1 Production Bootstrap Relays

The bootstrap set should be expanded for production:

```dart
bootstrapRelays: [
  'wss://relay.hostr.network',  // Our relay (always)
  'wss://relay.damus.io',       // High availability, large user base
  'wss://nos.lol',              // High availability
],
```

**Rationale:** These are relays we maintain a persistent connection to for all users. They should be:

- Highly available and well-maintained
- Broadly used (maximizes chance of finding counterparties)
- Not so many that we waste connections (3-4 is plenty)

### 4.2 Bootstrap ≠ Discovery

|                      | Bootstrap Relays             | Discovery Relays                |
| -------------------- | ---------------------------- | ------------------------------- |
| **When connected**   | Always (persistent)          | Only during sign-in discovery   |
| **Purpose**          | Ensure baseline connectivity | Find existing user's relay list |
| **User can remove?** | No                           | N/A (ephemeral)                 |
| **Count**            | 2-4                          | 4-6                             |

---

## 5. Publishing Strategy

### 5.1 Event Categories & Relay Targets

| Event Type                  | Kind(s)      | Publish To                                  | Rationale                                                                   |
| --------------------------- | ------------ | ------------------------------------------- | --------------------------------------------------------------------------- |
| **Profile metadata**        | 0            | All write relays (NIP-65 outbox)            | Standard Nostr — maximize discoverability                                   |
| **NIP-65 relay list**       | 10002        | All connected relays                        | Must be broadly available for others to find you                            |
| **Accommodation listings**  | 32121        | All write relays + **hostr relay (always)** | Listings need maximum discoverability; hostr relay is the marketplace index |
| **Escrow service ads**      | 30303        | All write relays + **hostr relay**          | Must be discoverable by all hostr users                                     |
| **Escrow methods**          | 30301        | All write relays + **hostr relay**          | Paired with escrow service                                                  |
| **Escrow trust**            | 30300        | All write relays + **hostr relay**          | Paired with escrow service                                                  |
| **Reservation (commit)**    | 32122        | All write relays + **hostr relay**          | Public record of committed reservation                                      |
| **Reservation transitions** | 32126        | All write relays + **hostr relay**          | State machine progression                                                   |
| **Reviews**                 | 32124        | All write relays + **hostr relay**          | Public reputation data                                                      |
| **Reservation (negotiate)** | —            | **NEVER published to relays**               | Exchanged only via NIP-17 DMs                                               |
| **Escrow service selected** | 30302        | **NIP-17 DM only**                          | Private — part of negotiation                                               |
| **DMs (gift wraps)**        | 1059         | Recipient's **inbox relays** (kind:10050)   | NIP-17 spec — use recipient's DM relay list                                 |
| **Zap requests**            | 9734         | As specified by NIP-57                      | Follow zap protocol                                                         |
| **Badges**                  | 30009, 30008 | All write relays                            | Standard                                                                    |
| **NWC**                     | 23194/23195  | NWC relay only                              | Wallet-specific relay                                                       |

### 5.2 The "Hostr Relay Always" Rule

For all **domain-specific events** (listings, reservations, escrow, reviews), we MUST ensure they are always published to `wss://relay.hostr.network` regardless of the user's NIP-65 relay list.

**Why:** The hostr relay is the canonical marketplace index. Even if a user's write relays are all down, their listing should be discoverable by other hostr users.

**Implementation:** When broadcasting domain-specific events, always include hostr relay in the `specificRelays` parameter, merged with the user's outbox relays:

```dart
Future<List<RelayBroadcastResponse>> broadcastDomainEvent({
  required Nip01Event event,
}) async {
  // Get user's write relays from NIP-65
  final writeRelays = ndk.userRelayLists.getWriteRelays(event.pubKey);

  // Always include hostr relay
  final targetRelays = {...writeRelays, config.hostrRelay}.toList();

  return broadcast(event: event, relays: targetRelays);
}
```

### 5.3 Third-Party Relay Compatibility

**Will third-party relays accept our custom event kinds?**

Yes — with caveats:

| Relay Behavior                      | Impact                                                 | Mitigation                                                             |
| ----------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------- |
| **Stores all events** (most relays) | ✅ Our events are stored and queryable                 | None needed                                                            |
| **Filters by kind whitelist**       | ❌ May reject kinds 32121, 32122, etc.                 | Hostr relay is always a fallback                                       |
| **Size limits**                     | ⚠️ Listings with many images may exceed content limits | Keep event content lean; use blossom for media                         |
| **Rate limiting**                   | ⚠️ May throttle rapid publishes                        | Implement retry with backoff; hostr relay has no limits for our events |
| **Ephemeral-only**                  | ❌ Won't store replaceable events                      | Hostr relay is the canonical store                                     |

**Conclusion:** We cannot guarantee third-party relay compatibility for our custom kinds. The hostr relay serves as the **guaranteed fallback**. Third-party relays are best-effort distribution for discoverability and redundancy.

---

## 6. Relay Addition — Backfilling Existing Events

### 6.1 The Problem

When a user adds a new relay in Settings, should we send all their existing events to it?

### 6.2 Will Relays Accept Old Events?

**Yes, with some nuance:**

- **NIP-01 says:** Relays SHOULD accept events regardless of `created_at` timestamp. There is no protocol-level requirement to reject "old" events.
- **In practice:** Most relays accept events with any timestamp. Some relays may have:
  - **Future timestamp limits** (e.g., reject events >15min in the future)
  - **Very old event rejection** (rare, but some relays reject events older than X days)
  - **Storage quotas** that may cause older events to be evicted first
- **Replaceable events** (our primary concern): For kinds 3xxxx (parameterized replaceable), the relay keeps only the latest version per `pubkey` + `kind` + `d` tag. So publishing an old listing to a new relay will work — the relay just stores the latest version.

### 6.3 Proposed Backfill Strategy

```
When user adds a new relay:

1. Connect to the new relay

2. Selective backfill (immediate):
   - Publish current NIP-65 relay list (kind:10002)
   - Publish current profile (kind:0)
   - Publish all active listings (kind:32121)
   - Publish active escrow methods (kind:30301) and services (kind:30303)

3. Deferred backfill (background, non-blocking):
   - Publish committed reservations (kind:32122) from the last 90 days
   - Publish reservation transitions (kind:32126) from the last 90 days
   - Publish reviews (kind:32124) — all, since these are permanent reputation

4. DO NOT backfill:
   - DMs / gift wraps (privacy — these are for specific recipients)
   - Negotiation-stage reservations (never published to relays)
   - NWC events (wallet-specific relay)
   - Expired/cancelled reservations older than 90 days
```

### 6.4 Implementation

```dart
Future<void> backfillRelay(String relayUrl) async {
  final pubkey = auth.currentPubkey;

  // Phase 1: Critical events (blocking)
  final criticalKinds = [
    0,      // Profile
    10002,  // NIP-65
    32121,  // Listings
    30301,  // Escrow methods
    30303,  // Escrow services
    30300,  // Escrow trust
  ];

  for (final kind in criticalKinds) {
    final events = await localCache.getEventsByAuthorAndKind(pubkey, kind);
    for (final event in events) {
      await requests.broadcast(event: event, relays: [relayUrl]);
    }
  }

  // Phase 2: Historical events (background)
  final cutoff = DateTime.now().subtract(Duration(days: 90));
  final historicalKinds = [32122, 32126, 32124]; // Reservations, transitions, reviews

  for (final kind in historicalKinds) {
    final events = await localCache.getEventsByAuthorAndKind(pubkey, kind);
    for (final event in events.where((e) =>
        e.createdAt.isAfter(cutoff) || kind == 32124 /* all reviews */)) {
      await requests.broadcast(event: event, relays: [relayUrl]);
      await Future.delayed(Duration(milliseconds: 100)); // Rate limit courtesy
    }
  }
}
```

### 6.5 Update NIP-65 on Relay Add

When a user adds a relay, we must also **republish their NIP-65** (kind:10002) to include the new relay. This ensures other clients can discover them on the new relay.

```
1. User taps "Add relay" → enters wss://new-relay.example.com
2. Connect to new relay
3. Add to NIP-65 with read+write marker
4. Publish updated NIP-65 to ALL connected relays
5. Start backfill (as above)
```

---

## 7. Relay Removal

When a user removes a relay:

1. **Remove from NIP-65** (kind:10002) — republish updated list to all remaining relays
2. **Disconnect** from the relay
3. **Remove from local storage**
4. **Do NOT attempt to delete events** from the removed relay — Nostr has no reliable deletion mechanism, and the events are signed by the user anyway

**Constraint:** Bootstrap relays and the hostr relay cannot be removed. This is already enforced in the UI.

---

## 8. Hostr Relay Special Role

The hostr relay (`wss://relay.hostr.network`) has a privileged role in the ecosystem:

### 8.1 Guarantees

| Guarantee                           | Detail                                                            |
| ----------------------------------- | ----------------------------------------------------------------- |
| **Always connected**                | Part of bootstrap; cannot be removed                              |
| **Always in NIP-65**                | Published as read+write on every login                            |
| **Receives all domain events**      | Listings, reservations, escrow, reviews always published here     |
| **Indexes custom kinds**            | Optimized for our event kinds; supports all needed query patterns |
| **No rate limits for hostr events** | Our relay, our rules                                              |
| **Available as fallback**           | If a user's other relays fail, their data is still here           |

### 8.2 What the Hostr Relay Should NOT Be

- **The only relay** — we want decentralization; users should have multiple relays
- **A walled garden** — the relay accepts standard Nostr events; other clients can read from it
- **A privacy risk** — DMs are never sent here unless the user specifically adds it to their DM relay list

### 8.3 Relay-Side Configuration (Future)

Consider implementing on the hostr relay:

- **Kind whitelisting/prioritization:** Prioritize storage for kinds 32121, 32122, 32124, 32126, 303xx
- **Garbage collection:** Expire old non-domain events (e.g., reaction events older than 1 year)
- **Geospatial indexing:** For listing discovery by location (NIP-52 geohash tags)
- **Full-text search:** NIP-50 search support for listing content
- **Spam filtering:** Require valid NIP-65 or proof-of-work for publishing

---

## 9. Privacy-Sensitive Events

### 9.1 Events That Must Stay Private

| Event                    | Mechanism         | Relay Handling                                        |
| ------------------------ | ----------------- | ----------------------------------------------------- |
| Reservation negotiations | NIP-17 gift wraps | Sent only to counterparty's inbox relays (kind:10050) |
| Escrow service selection | NIP-17 gift wraps | Sent only within DM thread                            |
| Payment details          | NIP-17 gift wraps | Never on public relays                                |
| NWC requests/responses   | NWC relay         | Only the designated NWC relay                         |

### 9.2 DM Relay List (kind:10050)

When a user signs in, we should also check/publish their **DM relay list** (kind:10050, NIP-17):

```
1. On login, query kind:10050 for user
2. If not found:
   - Publish kind:10050 with hostr relay as the inbox relay
3. If found:
   - Ensure hostr relay is in the list (so other hostr users can DM them)
   - Connect to their existing DM relays
```

**Important:** The DM relay list is separate from NIP-65. A user might want DMs delivered to different relays than their public events.

---

## 10. Reading Strategy

### 10.1 Where to Query For Events

| Query Type                                                | Relay Strategy                                            |
| --------------------------------------------------------- | --------------------------------------------------------- |
| **Own events**                                            | Local cache first → hostr relay → own NIP-65 write relays |
| **Specific user's events** (e.g., view a host's listings) | Their NIP-65 write relays (outbox model) + hostr relay    |
| **Discovery queries** (e.g., "listings in Paris")         | Hostr relay (canonical index) + bootstrap relays          |
| **DMs**                                                   | Own inbox relays (kind:10050)                             |
| **Counterparty's profile**                                | Their NIP-65 write relays + discovery relays              |
| **Escrow service ads**                                    | Hostr relay (canonical) + bootstrap relays                |

### 10.2 The Outbox Model (NIP-65)

NDK's JIT engine already implements the outbox model:

- **When querying by author:** NDK looks up the author's NIP-65 write relays and queries those
- **When querying without author (e.g., filters):** NDK queries the bootstrap/connected relays
- **When sending DMs:** NDK looks up the recipient's inbox relays (kind:10050)

**For hostr, we augment this:** Always include the hostr relay in any query for domain-specific event kinds, since we guarantee those events exist there.

---

## 11. Edge Cases & Failure Modes

### 11.1 User's NIP-65 Relays Are All Down

```
Scenario: User has NIP-65 = [relay-a.com, relay-b.com], both offline
Impact: Can't fetch their listings, can't deliver DMs

Mitigation:
  → Hostr relay always has their domain events (listings, reservations)
  → For DMs: queue gift wraps and retry with exponential backoff
  → UI: Show "some relays unreachable" warning, not a hard error
```

### 11.2 New Relay Rejects Old Events

```
Scenario: User adds a relay that rejects events with created_at > 7 days ago
Impact: Backfill fails for historical events

Mitigation:
  → Log failures but don't block the relay addition
  → The relay will still receive future events
  → Hostr relay remains the canonical store for historical data
```

### 11.3 User Has Hundreds of Relays in NIP-65

```
Scenario: Power user has 50+ relays in their NIP-65
Impact: Excessive connections, slow broadcasting, resource waste

Mitigation:
  → Cap active connections (e.g., max 10-15 concurrent relay connections)
  → Prioritize: hostr relay > bootstrap relays > user's most-connected relays
  → Connect to remaining relays on-demand (JIT) for specific queries
  → UI: Warn user that too many relays may degrade performance
```

### 11.4 Relay Imposes Storage Quotas

```
Scenario: A relay only stores the latest N events per pubkey
Impact: Older listings or reservations may be evicted

Mitigation:
  → Hostr relay has no such limits for domain events
  → On app launch, periodically re-publish active listings to user's relays
  → Consider a "refresh listings" background task (e.g., weekly)
```

### 11.5 Clock Skew Between Relays

```
Scenario: Replaceable event has different versions on different relays
Impact: User sees stale data depending on which relay responds first

Mitigation:
  → NDK already handles this: for replaceable events, it takes the highest created_at
  → Ensure we always query multiple relays and merge results
  → On edit: broadcast to ALL write relays to minimize version skew
```

### 11.6 Counterparty Not on Hostr Relay

```
Scenario: A Nostr user wants to book via a third-party client,
          their NIP-65 doesn't include hostr relay
Impact: We can't deliver DMs, can't find their profile

Mitigation:
  → Use discovery relays to find their NIP-65
  → Send DMs to THEIR inbox relays (not ours)
  → Accept reservations from any relay we're connected to
  → The outbox model handles this naturally
```

---

## 12. Implementation Roadmap

### Phase 1: Pre-Launch Hardening (Before Go-Live)

- [ ] **Add discovery relays config** — separate from bootstrap relays
- [ ] **Implement relay discovery waterfall** for existing-user sign-in (§3.3)
- [ ] **Ensure hostr relay is always included** in domain event broadcasts (§5.2)
- [ ] **Publish kind:10050 (DM relay list)** on login if missing (§9.2)
- [ ] **Expand production bootstrap relays** to 3-4 well-known relays (§4.1)
- [ ] **Add connection cap** — max 15 concurrent relay connections (§11.3)

### Phase 2: Backfill & Resilience (Launch + 2 weeks)

- [ ] **Implement selective backfill on relay add** (§6.3)
- [ ] **Update NIP-65 on relay add/remove** (§6.5, §7)
- [ ] **Add retry queue for failed broadcasts** with exponential backoff
- [ ] **Periodic listing refresh** — re-publish active listings weekly to all write relays
- [ ] **DM delivery queue** — retry gift wraps when recipient's relays come online

### Phase 3: Optimization (Launch + 1 month)

- [ ] **Relay health scoring** — track success rates per relay, deprioritize unreliable ones
- [ ] **Smart relay selection** — when querying, prefer relays with lower latency and higher success rate
- [ ] **Hostr relay optimizations** — geospatial indexing, full-text search (NIP-50), spam filtering
- [ ] **Relay recommendations** — suggest well-known relays to users with few relays
- [ ] **Analytics** — track relay distribution across user base, identify single-points-of-failure

### Phase 4: Decentralization (Launch + 3 months)

- [ ] **Federation testing** — verify end-to-end flows with users who DON'T have hostr relay
- [ ] **Third-party client compatibility** — test that our events are readable by other Nostr clients
- [ ] **Relay operator documentation** — guide for running a relay compatible with hostr event kinds
- [ ] **Reduce hostr relay dependency** — ensure the app degrades gracefully if hostr relay is down

---

## 13. Open Questions

1. **Should we run a `purplepag.es`-style NIP-65 aggregator?** This would give us a local cache of relay lists for all Nostr users, improving discovery without depending on third-party infrastructure.

2. **Should the hostr relay require authentication (NIP-42)?** This could prevent spam but would make the relay less open. Alternative: require auth for writing but allow anonymous reading.

3. **How do we handle relay costs?** If users add expensive/premium relays, should we warn them? Should we limit backfill to avoid running up their quota on paid relays?

4. **Should listings be cross-posted to general-purpose social relays?** This would increase discoverability outside the hostr ecosystem but might be considered spam on social relays.

5. **Do we need a relay proxy/aggregator service?** A server-side component that maintains connections to all known relays and proxies queries could reduce client-side connection overhead.

6. **What's our strategy for relay.nostr.band (search relay)?** Should we actively publish to it for discoverability, or let organic propagation handle it?

7. **Should we support NIP-42 (relay authentication)?** Some relays require auth before accepting events. NDK may need to handle this transparently.
