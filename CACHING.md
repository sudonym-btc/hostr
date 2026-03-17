# Caching and batching strategy

## Goal

Make `ListingListItem` and `ListingView` fast by ensuring that:

1. callers can ask for a single high-level dependency bundle
2. the caller never knows about caching or batching
3. duplicate Nostr queries are coalesced
4. duplicate validation work is coalesced
5. duplicate RPC work is coalesced
6. expensive work does not block the UI isolate

This document proposes the strategy, not a final implementation.

---

## Desired page model

A listing surface should ideally work from a single dependency bundle:

- `Listing`
- validated reservation-pair stream for that listing
- validated review stream for that listing

That bundle can be passed from a search result into the listing detail page when already available.
If the user navigates directly to the listing page, the page should create the same bundle itself.

Important: this bundle is a UI convenience only.
The real caching, batching, and deduplication must live below the widget layer.
The widget layer should only express intent.

---

## Core rule

All batching and caching should live in shared infrastructure:

- `Requests`
- `CrudUseCase`
- generic validation cache / dependency cache services used by all use cases

It should **not** be reimplemented separately in:

- `Reviews`
- `ReservationPairs`
- `Listings`
- widget/provider code

Use cases may describe:

- what they need
- how to derive a cache key
- what kind of validation/dependency resolution they want

But the actual machinery should be generic.

---

## 1. ListingDependenciesProvider shape

A `ListingDependenciesProvider` should expose a stable object something like:

- listing
- `StreamWithStatus<List<Validation<ReservationPair>>>`
- `StreamWithStatus<Validation<Review>>`
- cheap derived streams like:
  - review count
  - average rating
  - reservation count

The provider should:

- accept a listing anchor or full listing
- reuse an existing dependency object if one is already present in the widget tree
- otherwise resolve it lazily

However, the provider itself should not own custom caching logic.
It should just obtain shared streams from the SDK.

---

## 2. Nostr query caching and batching

### Problem

Today there is already batching for:

- `getOne`
- `findByTag`

But listing dependencies need something broader:

- many listing items on a search page all request reviews
- many listing items request reservation pairs
- review validation itself triggers more reservation/listing fetches
- the same data may be requested by both direct queries and validation side effects

### Strategy

Build a generic request coalescing layer in `Requests` and expose it through `CrudUseCase`.

### A. Normalized query key

Every query should be normalized into a canonical cache key based on:

- kind(s)
- authors
- ids
- tags
- d-tags
- limits
- sort-relevant fields
- subscription vs one-shot semantics

Two logically identical filters must produce the same key even if field order differs.

### B. In-flight dedupe

If the same normalized query is already running:

- do not start another query
- attach the new caller to the existing future/stream

This should work for:

- one-shot query
- live subscription
- count query

### C. Result cache with TTL

For one-shot queries, cache the resolved results for a short TTL.
Examples:

- listing lookup: longer TTL
- metadata lookup: medium TTL
- reviews / reservations for active pages: short TTL

This should be keyed by normalized query key.

### D. Shared live subscriptions

For subscriptions, maintain a shared subscription registry:

- one underlying relay subscription per normalized filter
- many consumers attach listeners
- reference count consumers
- close underlying subscription when the last consumer detaches

This is the most important fix for search pages launching many similar streams.

### E. Superset query reuse

Where practical, allow a broader query to satisfy narrower callers.
Example:

- a shared listing-reservations subscription for anchor `A`
- review validation asking for reservation pair `tradeId X` under the same listing

If the superset stream already contains enough data, derive locally instead of launching another Nostr query.

This likely requires a small query-planner layer, but even partial reuse will help.

---

## 3. Validation caching

### Problem

This is the biggest architectural gap.

Example:

- `ListingDependenciesProvider` asks for validated reservation pairs
- independently, validated reviews arrive
- each review asks to resolve and validate the associated reservation/pair
- reservation-pair validation for trade `X` may already be in progress
- review validation should not trigger the same work again

### Strategy

Create a generic validation cache service used by all `CanVerify`-style flows.

### A. Cache by validation target key

Each validation target must have a stable key.
Examples:

- review validation key: `review:<event-id>`
- reservation pair validation key: `reservation-pair:<trade-id>:<fingerprint>`
- escrow validation key: `escrow:<trade-id>:<fingerprint>`

The fingerprint should change only when the effective inputs change.
For reservation pairs this could include:

- buyer reservation id + stage
- seller reservation id + stage
- relevant proof fields

### B. Cache pending work, not just completed work

The cache must store:

- completed result
- in-flight future

If validation for `trade X` is already running, the second caller should await the same future.
This is essential.

### C. Split caches by stage

There should be separate caches for:

1. dependency resolution
2. cheap validation
3. expensive validation

That allows:

- reuse of resolved deps
- reuse of parsed/assembled pairs
- reuse of on-chain verification

### D. Generic API

At the shared layer, the pattern should be something like:

- `resolveCached(key, resolver)`
- `validateCached(key, validator)`
- `enrichCached(key, enricher)`

Use cases define keys and functions.
The cache service handles dedupe.

---

## 4. Reservation-pair specific validation plan

### Current pain

`ReservationPairs._buildValidatedStream()` verifies pair updates one item at a time and can trigger on-chain work for every trade independently.

### Strategy

#### A. Split pair assembly from pair validation

Stage 1:

- raw reservation stream
- group into `tradeId -> ReservationPair`
- emit raw pairs cheaply

Stage 2:

- validate those grouped pairs using validation cache

This avoids rebuilding pair state and validation state as one inseparable pipeline.

#### B. Keep a trade-level validation map

Maintain a generic shared map:

- `tradeId/fingerprint -> Future<Validation<ReservationPair>>`

Any consumer needing that pair validation should hit this map first.

#### C. Only revalidate changed pairs

n
When a reservation update arrives:

- recompute the pair fingerprint for that trade only
- if unchanged, do nothing
- if changed, invalidate only that trade key

Do not reprocess the whole listing.

---

## 5. Review validation plan

### Current pain

A review validation currently resolves:

- listing reservations
  n- listing

That can still be batched, but it is not enough because it duplicates work already being done elsewhere.

### Strategy

#### A. Resolve from shared listing dependency context first

If listing dependencies for anchor `A` already exist, review validation should try to resolve from:

- cached listing
- cached reservation pair map
- cached reservation list

before issuing any query.

#### B. Validate against pair cache, not raw fetch path

If a review references reservation/pair `X`, the review validator should:

- consult shared reservation-pair validation cache
- await in-flight validation if already running
- only create new work if cache miss

#### C. Minimize cryptography in review flow

Review validation should be layered:

1. cheap structural checks
2. lookup matching reservation(s) from cached context
3. only if needed, run proof verification

Avoid repeated proof hashing/signature checks if the same reservation has already been validated elsewhere.

---

## 6. RPC batching and caching strategy

### Problem

Logs show on-chain escrow verification causing multiple near-identical RPC calls:

- repeated chain resolution
- repeated contract wrapper use
- repeated `eth_getLogs` by trade id

### Strategy

### A. Shared RPC request registry

At the EVM/RPC layer, build generic request dedupe exactly like Nostr query dedupe:

- normalized RPC key
- in-flight future reuse
- short TTL result cache

This should apply to:

- `eth_getLogs`
- `eth_call`
- `getCode`
- balance/nonce lookups where relevant

### B. Batch `eth_getLogs`

For escrow verification, do not query logs trade-by-trade when multiple trades belong to the same:

- chain
- contract address
- event family

Instead:

- collect trade ids for a short window
- issue one `eth_getLogs`
- group results by trade id client-side

This should be the default behavior in the shared RPC layer or escrow-verification helper, not special-cased in UI.

### C. Cache contract wrapper / chain resolution

Never repeatedly recreate expensive chain-specific helpers if they are deterministic.
Cache:

- `escrowService -> chain`
- `chain + contract address -> wrapper`

### D. Multi-stage escrow verification cache

Cache:

1. raw logs by batched request key
2. grouped per-trade logs
3. final escrow verification result by `tradeId:fingerprint`

That way:

- one RPC response serves many trades
- one parsed result serves many validators
- one final verification result serves reviews and reservation-pair streams alike

### E. Do heavy verification off-main

If cryptographic or log parsing work is significant, run it off the UI isolate in a bounded worker pool.

Do not spawn unlimited workers.
Use a small queue.

---

## 7. Debouncing and rebuild control

Debouncing should happen before UI publication.

### Good places to debounce

- batched query flush in `Requests`
- batched validation flush in validation cache
- batched RPC flush in chain/RPC layer
- stream publication of validated snapshots

### Avoid over-debouncing widgets

The widget layer should not hide structural inefficiency.
If the data layer emits too often, fix the data layer.

### Distinct-until-changed

For all derived UI streams, publish only on meaningful change:

- review count changed
- average rating changed
- reservation count changed
- blocked reservation list changed
- availability result changed

This will reduce repaint noise even after caching is improved.

---

## 8. Where this should live

### `Requests`

Should own:

- normalized query keys
- in-flight dedupe for Nostr queries
- shared live subscription registry
- one-shot query TTL cache
- request batching windows

### `CrudUseCase`

Should own generic higher-level helpers built on top of `Requests`, such as:

- cached/stream-shared query APIs
- dependency-bundle helpers
- generic join/reuse hooks for child validations

`CrudUseCase` should become the common place where all entity use cases inherit the same behavior.

### Generic validation cache service

Should own:

- in-flight validation dedupe
- completed validation cache
- dependency resolution cache
- fingerprint invalidation

Use cases supply keys and functions, but not the machinery.

### EVM / RPC infrastructure

Should own:

- normalized RPC keys
- in-flight dedupe
- batched `eth_getLogs`
- TTL caching
- parsed-result reuse

---

## 9. Recommended rollout order

### Phase 1

- add shared one-shot query cache + in-flight dedupe in `Requests`
- add shared live subscription registry in `Requests`
- make `CrudUseCase` consume these by default

### Phase 2

- add generic validation cache service
- migrate reservation-pair validation to it
- cache pending validation futures, not just completed results

### Phase 3

- make review validation consult reservation-pair validation cache first
- reuse listing dependency context when available

### Phase 4

- add RPC request dedupe and `eth_getLogs` batching
- cache chain resolution and contract wrappers

### Phase 5

- add `ListingDependenciesProvider` on top of the shared SDK behavior
- allow parent surfaces to pass it down, while detail pages can create it lazily

---

## 10. Non-negotiable invariants

1. UI callers must never care whether data came from cache, batch, live stream, or direct fetch.
2. If work for a key is already in progress, everyone else must await the same work.
3. Validation results must be invalidated by input fingerprint changes, not by arbitrary rebuilds.
4. Batching must happen below the use-case callsite.
5. Expensive crypto / chain work must not sit on the UI isolate when avoidable.

---

## Bottom line

The right model is:

- `ListingDependenciesProvider` at the UI level
- shared query cache + shared subscription registry in `Requests`
- shared dependency/validation cache in generic infrastructure used by `CrudUseCase`
- shared RPC cache + batcher in EVM infrastructure

That will solve both classes of waste:

- duplicate network/query work
- duplicate validation/crypto work

especially the important case where one stream's validation triggers dependency lookups already being validated by another stream.
