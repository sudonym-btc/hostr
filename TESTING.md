# Testing Audit — `hostr_sdk`

> Generated 2025-03-28 from a full read of every test file + the seed pipeline.

---

## Executive Summary

The test suite has **strong pockets** — reservation lifecycle, stream utilities, swap store CAS
operations, and barter policy are all thoroughly tested. But the **dominant pattern** is
file-local `_listing()` / `_reservation()` helpers copy-pasted across 10+ files, file-local
`_Fake*` stubs duplicated 3-4× each, and **22 of ~37 usecase modules with zero tests**.

The `TestSeedHelper` / `SeedFactory` infrastructure exists and is excellent — but it is
**never used in any test file**. Every test rolls its own helpers.

---

## Table of Contents

1. [Anti-Pattern: Duplicated Test-Data Factories](#1-anti-pattern-duplicated-test-data-factories)
2. [Anti-Pattern: File-Local Fake Stubs](#2-anti-pattern-file-local-fake-stubs)
3. [Anti-Pattern: Integration-Scoped EVM Helpers](#3-anti-pattern-integration-scoped-evm-helpers)
4. [Integration Harness Improvements](#4-integration-harness-improvements)
5. [Arrange / Assert Patterns](#5-arrange--assert-patterns)
6. [Test Organisation](#6-test-organisation)
7. [Missing Test Coverage](#7-missing-test-coverage)
8. [Dead / Skipped Tests](#8-dead--skipped-tests)
9. [Action Plan](#9-action-plan)

---

## 1. Anti-Pattern: Duplicated Test-Data Factories

### The Problem

`_listing()` appears in **10 files** — each a copy-paste with different parameter subsets.
`_reservation()` / `_negotiate()` appears in **9 files**. `_sellerAck()` / `_cancel()` in 3
each. They all call `Listing.create(…).signAs(…)` or `Reservation.create(…).signAs(…)` with
the same boilerplate — the only differences are which params they expose vs hardcode.

**Files with duplicate `_listing()`:**

| File                                                                     | Variant                                                                               |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| `unit/usecase/reservations/reservation_lifecycle_test.dart`              | `_listing({signer, allowBarter, allowSelfSigned, requiresEscrow, pricePerNightSats})` |
| `unit/usecase/reservations/reservation_pairs_test.dart`                  | `_listing({signer, allowSelfSigned})`                                                 |
| `unit/usecase/escrow/escrow_verification_test.dart`                      | `_listing({pricePerNightSats, allowBarter})`                                          |
| `unit/usecase/trades/barter_policy_test.dart`                            | `_listing({pricePerNightSats, allowBarter})`                                          |
| `unit/usecase/reservations/trade_identity_preservation_test.dart`        | `_listing()` (no params)                                                              |
| `unit/usecase/reservations/listing_availability_test.dart`               | `_fixtureListing()`                                                                   |
| `unit/usecase/reservations/reservations_validator_mock_data_test.dart`   | `_fixtureListing()` (identical)                                                       |
| `unit/usecase/reviews/review_verification_test.dart`                     | `_fixtureListing()` (near-identical)                                                  |
| `integration/usecase/evm/fee_and_verification_test.dart`                 | `_buildListing({host, pricePerNight, …5 params})`                                     |
| `integration/usecase/reservation/validation/reservation_pairs_test.dart` | `_buildListing({host, …5 params})`                                                    |

### The Fix: `TestSeedHelper` Already Exists — Use It

`TestSeedHelper.freshHost()` returns a `TestHost` with a signed `Listing`, and
`freshTrade()` gives you a `TestTrade` with host + guest + listing + negotiate reservation
— all deterministically signed, no manual construction needed.

For unit tests that need model-level objects without DI, `SeedFactory.buildListings()` is
the pure-data equivalent that creates signed listings from `SeedUser` objects.

#### Before (current pattern):

```dart
Listing _listing({int pricePerNightSats = 100000}) =>
    Listing.create(
      dTag: 'test-listing-abc',
      title: 'Test Cottage',
      description: 'A cozy cottage',
      listingType: ListingType.entirePlace,
      images: [],
      pricePerNight: DenominatedAmount.sats(BigInt.from(pricePerNightSats)),
      // ... 8 more required fields ...
      requiresEscrow: true,
      allowBarter: false,
      allowSelfSignedReservation: false,
    ).signAs(MockKeys.hoster, Listing.fromNostrEvent);
```

#### After (recommended):

```dart
// Option A — Full fixture with host profile + key + listing:
final host = await seeds.freshHost();
final listing = host.listing; // signed, realistic, deterministic

// Option B — Override just what the test cares about:
final listing = host.listing.copyWith(pricePerNight: DenominatedAmount.sats(BigInt.from(50000)));

// Option C — Pure data for model-level tests (no DI):
final factory = SeedFactory(config: SeedPipelineConfig(seed: 42, userCount: 0));
final users = [SeedUser(index: 0, keyPair: MockKeys.hoster, isHost: true, hasEvm: false)];
final listings = factory.buildListings(users);
```

The same pattern should replace `_negotiate()`, `_sellerAck()`, `_cancel()`,
`_commitReservation()`. For reservations at various stages, `TestSeedHelper.freshThread()`
with `ThreadStageSpec` already supports controlling the exact stage progression.

---

## 2. Anti-Pattern: File-Local Fake Stubs

### The Problem

Tiny no-op fake classes are duplicated across 3-4 files each:

| Fake                                                                 | Identical copies in      |
| -------------------------------------------------------------------- | ------------------------ |
| `_FakeMessaging extends Fake implements Messaging {}`                | 4 files                  |
| `_FakeAuth extends Fake implements Auth {}`                          | 3 files                  |
| `_FakeTransitions extends Fake implements ReservationTransitions {}` | 3 files                  |
| `_FakeRelayRequests` (20-line stream wrapper)                        | 2 files (byte-identical) |
| `_FakeEscrowRpc`                                                     | 2 files (byte-identical) |

### The Fix

Create `test/support/fakes.dart` with shared fake stubs:

```dart
// test/support/fakes.dart
export 'package:hostr_sdk/testing/fakes.dart';  // or keep in test/

class FakeMessaging extends Fake implements Messaging {}
class FakeAuth extends Fake implements Auth {}
class FakeTransitions extends Fake implements ReservationTransitions {}
class FakeRelayRequests extends Fake implements Requests { … }
class FakeEscrowRpc { … }
```

The existing `test/unit/fakes/` directory already has `fake_boltz_client.dart`,
`fake_evm_chain.dart`, `fake_swap_operations.dart` — these domain-specific fakes are well
done. The generic stubs should join them.

---

## 3. Anti-Pattern: Integration-Scoped EVM Helpers

### The Problem

Three helper functions are copy-pasted identically across 3 integration test files:

```dart
String _extractTxHash(TransactionInformation info) { … }
String _extractReceiptTxHash(TransactionReceipt receipt) { … }
bool _isReceiptSuccessful(TransactionReceipt receipt) { … }
```

Plus `_waitForReceipt()` in 3 files (with slight timeout variations), and
`_deployTestERC20()` + `_abiEncodeConstructor()` in 2 files.

### The Fix

Move to `test/support/evm_test_helpers.dart`:

```dart
// test/support/evm_test_helpers.dart
String extractTxHash(TransactionInformation info) { … }
bool isReceiptSuccessful(TransactionReceipt receipt) { … }

Future<TransactionReceipt> waitForReceipt(
  Web3Client web3, String txHash, {
  int maxAttempts = 30,
  Duration delay = const Duration(milliseconds: 500),
}) { … }

Future<EthereumAddress> deployTestERC20(
  Web3Client web3,
  Credentials deployer,
  String name, String symbol, int decimals,
) { … }
```

---

## 4. Integration Harness Improvements

### 4.1 — Harness Creation Cost

Some test files use `setUp` (per-test harness), others use `setUpAll` (shared harness).
Per-test creation is correct for isolation but pays the full Anvil + seed + NWC bootstrap
cost per test.

**Recommendation:** Default to `setUpAll` + harness-level `resetState()` method that:

- Clears the `OperationStateStore`
- Resets Anvil to a snapshot (via `anvil.snapshot()` / `anvil.revert()`)
- Clears Boltz pending transactions

This gives isolation without re-bootstrapping. The harness should expose:

```dart
/// Revert chain state + clear stores. Call from setUp for test isolation
/// without the cost of full harness re-creation.
Future<void> resetToCleanState() async {
  await anvil.revert(_snapshotId);
  _snapshotId = await anvil.snapshot();
  await anvilRootstock.revert(_rootstockSnapshotId);
  _rootstockSnapshotId = await anvilRootstock.snapshot();
  await clearBoltzPendingEvmTransactions();
  // clear local stores …
}
```

### 4.2 — Trade Fixture Shorthand

The arrange phase in most EVM integration tests follows the same 5-step sequence:

```dart
final trade = await harness.seeds.freshTrade(hostHasEvm: true);
await harness.signInAndConnectNwc(user: trade.host.keyPair, appNamePrefix: 'test');
await harness.anvil.setBalance(address: evmAddr, amountWei: amount);
// resolve escrow service…
// resolve chain config…
```

**Recommendation:** Add a `harness.arrangeSwapTest()` and `harness.arrangeEscrowTest()`
helper that bundles these steps:

```dart
/// Returns a fully-arranged EVM test context: signed in, funded, NWC connected.
Future<ArrangedEvmTest> arrangeEvmTest({
  bool withNwc = true,
  BigInt? fundAmountWei,
}) async { … }

class ArrangedEvmTest {
  final TestTrade trade;
  final KeyPair fundedKey;
  final String evmAddress;
}
```

### 4.3 — Boltz Pending Transaction Cleanup

`clearBoltzPendingEvmTransactions()` shells out to `docker exec` + `psql`. This is fragile
and slow. Consider adding a REST endpoint to the Boltz test harness, or at minimum cache
the result of the first call per test run if the table is already empty.

### 4.4 — Timeout Standardization

Timeouts range from 15s to 5 minutes with no clear rationale:

| Timeout | Usage                                          |
| ------- | ---------------------------------------------- |
| 15s     | swap_in_test (tight — flaky risk)              |
| 20-30s  | swap_out tests                                 |
| 60s     | escrow fund tests                              |
| 120s    | escrow_fund_test (pre-funded — should be fast) |
| 5min    | paymaster test                                 |

**Recommendation:** Define named constants in the harness:

```dart
static const swapTimeout = Duration(seconds: 30);
static const escrowTimeout = Duration(seconds: 60);
static const paymasterTimeout = Duration(minutes: 3);
```

---

## 5. Arrange / Assert Patterns

### 5.1 — Stream Watching (Good ✅)

Most integration tests correctly collect states via stream listening:

```dart
final emittedStates = <SwapInState>[];
operation.stream.listen(emittedStates.add);
await operation.run();
expect(emittedStates.whereType<SwapInCompleted>(), isNotEmpty);
```

This is the right approach. One improvement: use a `Completer` or `StreamMatcher` instead
of relying on the stream closing synchronously.

### 5.2 — Timing-Based Waits (Bad ❌)

Several unit tests use `Future.delayed(Duration(milliseconds: 20–800))` for async settling:

| File                                  | Delay |
| ------------------------------------- | ----- |
| `threads_message_threading_test.dart` | 20ms  |
| `review_verification_test.dart`       | 800ms |
| `heartbeats_test.dart`                | 50ms  |

**Fix:** Use `pumpEventQueue()` or `expectLater(stream, emitsInOrder(…))` instead of
sleeping. For stream-based tests, `await stream.first` or
`await Future.microtask(() {})` flushes the microtask queue deterministically.

### 5.3 — Assertion Granularity

`background_worker_test.dart`'s `run()` test asserts 5 orthogonal things. This is
acceptable for an orchestration test but makes failures ambiguous. Consider splitting into
5 tests with a shared `setUpAll` that runs the worker once.

### 5.4 — `GateHarness` Testing the Wrong Thing

`auto_withdraw_service_test.dart` defines a `GateHarness` that **reimplements the gate
logic** from `AutoWithdrawService`, then tests the harness. If the real service diverges
from the harness, tests pass but production breaks.

**Fix:** Test the real `AutoWithdrawService` with mocked dependencies, not a parallel
implementation.

---

## 6. Test Organisation

### 6.1 — Directory Structure

```
test/
├── integration/
│   └── usecase/
│       ├── escrow/          # EMPTY — escrow_claim_release_test exists but dir is empty
│       ├── evm/             # 11 files — good coverage of swap/fund flows
│       └── reservation/     # 1 file (reservation_pairs_test)
├── support/
│   ├── in_memory_hydrated_storage.dart
│   └── integration_test_harness.dart   # re-export only
└── unit/
    ├── fakes/               # 3 domain-specific fakes — GOOD
    └── usecase/
        ├── background_worker/   # 1 file
        ├── escrow/              # 1 file
        ├── evm/                 # 3 files
        ├── gift_wraps/          # 1 file (only 1 test)
        ├── heartbeat/           # 1 file
        ├── messaging/           # 1 file
        ├── requests/            # 1 file
        ├── reservations/        # 6 files — BEST COVERED MODULE
        ├── reviews/             # 1 file
        └── trades/              # 1 file
```

### 6.2 — Observations

- **No `test/support/fixtures/` or `test/support/factories/`** — shared test data has no
  home, so every file creates its own helpers.
- **`reservation_pairs_test.dart` exists in BOTH `unit/` and `integration/`** — the
  integration version includes 1 on-chain escrow test group that requires Docker; the other
  7 groups are pure logic that could be unit tests. Move the pure-logic groups to the unit
  file, keep only the on-chain group in integration.
- **`escrow_claim_release_test.dart`** is referenced in the integration dir but the escrow
  subdirectory is empty — this was likely moved to the `evm/` directory.
- **`swap_recovery_service_test.dart`** (189 lines) largely duplicates
  **`swap_store_test.dart`** (344 lines) — the recovery service file tests basic
  read/write/prune on `OperationStateStore` which is already thoroughly covered in
  `swap_store_test.dart`. Merge or delete.
- **`listing_availability_test.dart`** (97 lines) is 100% dead code — all tests skipped.
  Either implement or delete.

### 6.3 — Recommended Structure

```
test/
├── support/
│   ├── fakes.dart               # Shared no-op fakes (FakeAuth, FakeMessaging, etc.)
│   ├── evm_test_helpers.dart    # extractTxHash, waitForReceipt, deployTestERC20
│   ├── fixtures.dart            # Re-exports TestSeedHelper + convenience extensions
│   └── integration_test_harness.dart
├── unit/
│   ├── fakes/                   # Domain-specific fakes (Boltz, EvmChain, etc.)
│   └── usecase/                 # Mirror source structure
└── integration/
    └── usecase/
```

---

## 7. Missing Test Coverage

### 7.1 — Modules with Zero Tests

These **22 usecase modules** have no unit or integration tests:

| Module                         | Source Files                                 | Priority    |
| ------------------------------ | -------------------------------------------- | ----------- |
| **`payments/`**                | 9 files (bolt11, lnurl, zap, pay operations) | 🔴 Critical |
| **`nwc/`**                     | 3 files (cubit, connection management)       | 🔴 Critical |
| **`auth/`**                    | 3 files (signin, identity resolution)        | 🔴 Critical |
| **`trade_account_allocator/`** | 2 files (HD index allocation)                | 🔴 Critical |
| **`escrow_methods/`**          | 1 file                                       | 🟡 Medium   |
| **`escrow_trusts/`**           | 1 file                                       | 🟡 Medium   |
| **`escrows/`**                 | 1 file                                       | 🟡 Medium   |
| **`listings/`**                | 1 file                                       | 🟡 Medium   |
| **`user_subscriptions/`**      | 2 files                                      | 🟡 Medium   |
| **`verification/`**            | 1 file                                       | 🟡 Medium   |
| **`zaps/`**                    | 1 file                                       | 🟡 Medium   |
| **`badge_awards/`**            | 1 file                                       | 🟢 Low      |
| **`badge_definitions/`**       | 1 file                                       | 🟢 Low      |
| **`blossom/`**                 | 1 file                                       | 🟢 Low      |
| **`calendar/`**                | 1 file                                       | 🟢 Low      |
| **`lnurl/`**                   | 1 file                                       | 🟢 Low      |
| **`location/`**                | 1 file                                       | 🟢 Low      |
| **`metadata/`**                | 1 file                                       | 🟢 Low      |
| **`relays/`**                  | 4 files                                      | 🟢 Low      |
| **`reservation_requests/`**    | 1 file                                       | 🟢 Low      |
| **`storage/`**                 | 1 file                                       | 🟢 Low      |
| **`trade_audit/`**             | 1 file                                       | 🟢 Low      |

### 7.2 — Partially Tested Modules

| Module                   | What's Tested                                                                         | What's Missing                                                                                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`evm/operations/`**    | swap_store, swap_recovery, auto_withdraw (unit); swap_in/out, recoverer (integration) | `operation_machine.dart`, `operation_tracker.dart`, `swap_in_tracker.dart`, `swap_out_tracker.dart`, `funds_monitor_service.dart` — none unit-tested |
| **`evm/capabilities/`**  | Tested only via integration tests                                                     | `swap_funding_requirement.dart`, `chain_discovery.dart`, `erc20_token_resolver.dart` — no unit tests                                                 |
| **`escrow/operations/`** | `escrow_verification.dart` (unit)                                                     | `escrow_fund_operation.dart`, `escrow_fund_preparer.dart`, `escrow_claim_operation.dart`, `escrow_withdraw_operation.dart` — integration-only        |
| **`messaging/`**         | Thread creation / dedup                                                               | `messaging.dart` (the main Messaging usecase) — untested                                                                                             |
| **`trades/`**            | barter_policy (unit)                                                                  | `trade.dart` state machine, `payment_proof_orchestrator.dart`, all 5 action files — untested                                                         |

### 7.3 — Util Files Without Tests

| Util                     | Tested? |
| ------------------------ | ------- |
| `token_amount_ext.dart`  | ❌      |
| `coinlib_gift_wrap.dart` | ❌      |
| `crypto_provider.dart`   | ❌      |
| `evm_signature.dart`     | ❌      |
| `ndk_filter.dart`        | ❌      |
| `network_error.dart`     | ❌      |
| `bloc_x.dart`            | ❌      |

### 7.4 — Missing Integration Scenarios

| Scenario                                     | Status                                |
| -------------------------------------------- | ------------------------------------- |
| Escrow claim flow (seller claims funds)      | ❌ Missing                            |
| Escrow release / refund flow                 | ❌ Missing                            |
| Swap-in with ERC-20 tokens (not just native) | ❌ Missing (only fee estimate exists) |
| Escrow fund failure / revert scenarios       | ❌ Missing                            |
| Swap timeout / refund path                   | ❌ Missing                            |
| NWC connection loss / reconnect              | ❌ Missing                            |
| Concurrent swap operations                   | ❌ Missing                            |

---

## 8. Dead / Skipped Tests

| File                                         | Issue                                                                                                                                                                              |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `listing_availability_test.dart`             | **100% dead** — 97 lines, all tests `skip:`ed. Helpers duplicated from another file. Delete or implement.                                                                          |
| `reservations_validator_mock_data_test.dart` | **4 of 5 tests skipped** — escrow proof validation stubs never implemented. The one active test (cancelled-commitment filtering) should be moved to `reservation_pairs_test.dart`. |
| `swap_recovery_service_test.dart`            | **~80% overlap** with `swap_store_test.dart` — tests basic store round-trips already covered. Keep only the recovery-specific logic; delete duplicate store tests.                 |
| `paymaster_tbtc_claim_test.dart`             | Doc comment says "Temporary integration test — remove once proven." — decide whether to keep.                                                                                      |
| `escrow_claim_release_test.dart`             | Referenced in directory listing but file/directory is empty.                                                                                                                       |

---

## 9. Action Plan

### Phase 1 — Deduplication (Immediate, Low Risk)

| #   | Action                                                                                                                                      | Impact                                                           |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| 1.1 | Create `test/support/fakes.dart` with `FakeAuth`, `FakeMessaging`, `FakeTransitions`, `FakeRelayRequests`, `FakeEscrowRpc`                  | Eliminates ~15 duplicate class definitions                       |
| 1.2 | Create `test/support/evm_test_helpers.dart` with `extractTxHash`, `isReceiptSuccessful`, `waitForReceipt`, `deployTestERC20`                | Eliminates ~300 duplicated lines across 5 integration files      |
| 1.3 | Create `test/support/fixtures.dart` that re-exports `TestSeedHelper` + adds convenience extension for overriding listing/reservation fields | Single import for all test data                                  |
| 1.4 | Migrate all `_listing()` / `_negotiate()` / `_sellerAck()` / `_cancel()` call-sites to use `TestSeedHelper` or `SeedFactory` + overrides    | Eliminates 10 duplicate listing builders, 9 reservation builders |
| 1.5 | Delete `listing_availability_test.dart` (100% dead code)                                                                                    | -97 lines                                                        |
| 1.6 | Merge `swap_recovery_service_test.dart` into `swap_store_test.dart`, keep only recovery-specific tests                                      | -100 lines                                                       |

### Phase 2 — Harness Improvements (Medium Risk)

| #   | Action                                                                                      | Impact                                                              |
| --- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 2.1 | Add `harness.resetToCleanState()` with Anvil snapshot/revert                                | Enables `setUpAll` + per-test isolation without re-bootstrapping    |
| 2.2 | Add `harness.arrangeEvmTest()` shorthand                                                    | Reduces 5-line arrange blocks to 1 line across 11 integration tests |
| 2.3 | Define timeout constants (`swapTimeout`, `escrowTimeout`, `paymasterTimeout`)               | Consistency; easier to tune in CI                                   |
| 2.4 | Replace `Future.delayed` waits with `pumpEventQueue` or stream matchers                     | Eliminates flaky timing in 3-4 unit tests                           |
| 2.5 | Rewrite `auto_withdraw_service_test.dart` to test the real service instead of `GateHarness` | Catches production logic drift                                      |

### Phase 3 — Coverage Expansion (High Value)

| #   | Action                                                                                | Impact                        |
| --- | ------------------------------------------------------------------------------------- | ----------------------------- |
| 3.1 | Unit tests for `payments/` operation state machines (bolt11, lnurl, zap)              | Most complex untested module  |
| 3.2 | Unit tests for `operation_machine.dart` — CAS transitions, terminal state handling    | Core infrastructure           |
| 3.3 | Unit tests for `auth/` — signin, identity resolution, key management                  | Security-critical             |
| 3.4 | Unit tests for `trade_account_allocator/` — HD index allocation, collision prevention | Fund-safety-critical          |
| 3.5 | Unit tests for `token_amount_ext.dart` and new `TokenAmount.fromInt/fromBigInt`       | New code from recent refactor |
| 3.6 | Integration test for escrow claim + release flows                                     | Major gap                     |
| 3.7 | Integration test for swap timeout / refund path                                       | Major gap                     |

### Phase 4 — Organisation (Cleanup)

| #   | Action                                                                                       | Impact                                      |
| --- | -------------------------------------------------------------------------------------------- | ------------------------------------------- |
| 4.1 | Move pure-logic groups from `integration/reservation/reservation_pairs_test.dart` to `unit/` | 7 of 8 groups don't need Docker             |
| 4.2 | Move `unit/fakes/` to `test/support/fakes/` alongside the new shared fakes                   | Single location for all test infrastructure |
| 4.3 | Delete or implement `reservations_validator_mock_data_test.dart` skipped tests               | -4 dead stubs                               |
| 4.4 | Decide fate of `paymaster_tbtc_claim_test.dart` ("temporary" per doc comment)                | Reduce maintenance burden                   |
| 4.5 | Add `gift_wraps_test.dart` edge cases (error handling, parsing failures)                     | Currently only 1 test in file               |
