# Seed Pipeline & Mock Infrastructure — Architecture Redesign

## Table of Contents

1. [Current Architecture & What's Wrong](#1-current-architecture--whats-wrong)
2. [Target Architecture](#2-target-architecture)
3. [The Three Output Channels](#3-the-three-output-channels)
4. [The Dependency Problem (Chain-Dependent Data)](#4-the-dependency-problem-chain-dependent-data)
5. [Proposed Interfaces](#5-proposed-interfaces)
6. [MockChainBackend — The In-Memory Escrow Simulator](#6-mockchainbackend--the-in-memory-escrow-simulator)
7. [MockNip05Backend](#7-mocknip05backend)
8. [Full Rewrite Plan — File-by-File](#8-full-rewrite-plan--file-by-file)
9. [Migration Path for Existing Consumers](#9-migration-path-for-existing-consumers)
10. [End-to-End Example: Integration Test](#10-end-to-end-example-integration-test)
11. [End-to-End Example: Screenshot Pipeline](#11-end-to-end-example-screenshot-pipeline)
12. [End-to-End Example: Dev Backend Seeder](#12-end-to-end-example-dev-backend-seeder)
13. [Escrow Flow Coverage Matrix](#13-escrow-flow-coverage-matrix)

---

## 1. Current Architecture & What's Wrong

### How it works today

```
SeedPipelineConfig
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│  SeedPipeline (seed_pipeline.dart)                      │
│                                                         │
│  _runPipeline():                                        │
│    1. buildUsers()         ─── pure                     │
│    2. _fundUsers()         ─── calls AnvilClient        │
│    3. buildProfiles()      ─── pure                     │
│    4. buildEscrow*()       ─── pure                     │
│    5. buildListings()      ─── pure                     │
│    6. _setupLnbits()       ─── calls LnbitsDatasource   │
│    7. buildThreads()       ─── pure                     │
│    8. buildOutcomePlans()  ─── pure                     │
│    9. buildOutcomes()      ─── calls MultiEscrow.*      │
│   10. buildMessages()      ─── pure (NIP-17 crypto)     │
│   11. buildReviews()       ─── pure                     │
│                                                         │
│  Emits: SeedStreams (ReplaySubject<Nip01Event>)         │
│         + chainTx, userFunded, nip05Created, done       │
└─────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────┐     ┌───────────────────────┐
│  BroadcastIsolate│     │  CLI print summary     │
│  → NDK → Relay   │     │                        │
└──────────────────┘     └───────────────────────┘
```

### The problems

| Problem                                                                      | Why it hurts                                                                                                                                                                                                                             |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Infrastructure is hardcoded into the pipeline**                            | `_fundUsers` calls `AnvilClient`, `_setupLnbits` calls `LnbitsDatasource`, `buildOutcomes` calls `MultiEscrow` contract methods directly. You can't replace these with mocks without subclassing the whole pipeline.                     |
| **`SeedFactory` can't produce completed reservations with realistic proofs** | `SeedFactory.buildAll()` explicitly says "no outcomes — all pending". The `buildMockReservation()` helper produces a reservation with a fake tx hash but it doesn't exercise the chain interaction pattern at all.                       |
| **No `FakeMultiEscrow`**                                                     | `FakeEvmChain`/`FakeEtherSwap` only cover Boltz swap recovery. There's no in-memory `createTrade`/`claim`/`arbitrate`/`release` simulator.                                                                                               |
| **The outcome stage reads chain state to decide what to do**                 | `buildOutcomes` Phase 2a scans on-chain logs to detect pre-existing trades, then adjusts plans accordingly. A mock must replicate this log-scan → decision → execute → receipt pipeline.                                                 |
| **The data produced depends on WHERE it goes**                               | A `Reservation` with `EscrowProof` contains a `txHash` that came from a real contract call. In mock mode you still need a `txHash` — just one produced by the fake chain. The event shape is the same; the source of truth differs.      |
| **Broadcast is tangled into the pipeline**                                   | The pipeline emits to `SeedStreams.events` and a separate `BroadcastIsolate` consumes them. But the broadcast strategy (relay vs `InMemoryRequests` vs file) should be a consumer choice, not pipeline plumbing.                         |
| **`TestSeedHelper` / `AppTestSeeder` are workarounds, not a design**         | They exist because the pipeline was built relay-first, and mock usage was bolted on after. Every new test type adds another seeding helper class.                                                                                        |
| **No single `consume()` method**                                             | Tests do `factory.buildAll()` then `requests.seedEvents(data.allEvents)`. Integration tests do `SeedPipeline.run()` then feed streams to a `BroadcastIsolate`. Screenshot tests do yet another thing. The consumption pattern is ad-hoc. |

---

## 2. Target Architecture

> **Updated (A1/A4):** The `consume(onEvent, onChainOp, ...)` callback pattern is superseded by the `Seeder` + `SeedSink` pattern. See A1 for the full eager-emission model.

```
SeederConfig
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│  Seeder (rewritten — the ONLY class)                      │
│                                                           │
│  Seeder(config).seed(sink)                                │
│                                                           │
│  Emits each instruction individually via sink methods     │
│  the instant its dependencies are satisfied.              │
│  Independent instruction chains run concurrently.         │
│                                                           │
│  Returns: Future<SeedResult>                              │
│           (aggregated data + summary)                     │
└───────────────────────────────────────────────────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
   ┌─────────┐      ┌──────────────┐     ┌─────────────┐
   │ Real NDK │      │ Real Anvil + │     │ Real LNbits │
   │ Broadcast│      │ MultiEscrow  │     │ REST API    │
   └─────────┘      └──────────────┘     └─────────────┘
           └────────────────┼────────────────┘
                    InfrastructureSink

   ┌──────────────┐  ┌───────────────┐   ┌──────────────┐
   │InMemoryReq.  │  │FakeEscrowLedg.│   │FakeIdentity  │
   │  .addEvent() │  │  (in-memory)  │   │Registry      │
   └──────────────┘  └───────────────┘   └──────────────┘
           └────────────────┼────────────────┘
                       TestSink
```

### Key design principles

1. **The seeder produces INTENTS, not results.** For chain operations, it calls `sink.submitTrade(SubmitTrade(...))`. For events, `sink.publish(event)`. The sink decides whether to execute against Anvil or record in a mock.

2. **The seeder receives RESULTS back for chain ops.** `sink.submitTrade()` returns a `TradeResult` (tx hash) which the seeder uses to build the next event (e.g., `EscrowProof.txHash`). Publish calls are fire-and-forget.

3. **One port, typed methods.** All output goes through `SeedSink` — a single interface with typed methods (`publish`, `submitTrade`, `settleTrade`, `fund`, `registerIdentity`). No raw callbacks.

4. **Eager emission, not phases.** Each instruction fires the instant its dependencies are met. Independent branches (per-user, per-thread) run concurrently via `Future.wait`. Only real data dependencies cause blocking.

5. **Configuration is unchanged.** `SeedPipelineConfig` (→ `SeederConfig`) already has everything we need.

---

## 3. The Three Output Channels

### Channel 1: `onEvent` — Nostr events

```dart
typedef OnEventCallback = Future<void> Function(Nip01Event event);
```

Events emitted: profiles, escrow services/trusts/methods, listings, DMs (gift-wrapped), reservation requests, reservations, reservation transitions, zap receipts, reviews.

**Real consumer:** `ndk.broadcast(event, specificRelays: [relay])`
**Mock consumer:** `inMemoryRequests.addEvent(event)`

### Channel 2: `onChainOp` — EVM chain operations

```dart
sealed class ChainOperation { ... }

class CreateTradeOp extends ChainOperation {
  final String tradeId;
  final String buyerAddress;
  final String sellerAddress;
  final String arbiterAddress;
  final BigInt value;         // msg.value in wei
  final int unlockAt;         // epoch seconds
  final int escrowFeeBps;
  final Credentials buyerCredentials;
}

class SettleTradeOp extends ChainOperation {
  // One of: ClaimOp, ArbitrateOp, ReleaseOp
}

class FundAddressOp extends ChainOperation {
  final String address;
  final BigInt amountWei;
}

// Result returned by the consumer:
class ChainOpResult {
  final String txHash;
  final bool success;
  final int? blockNumber;
  final DateTime? blockTimestamp;
}
```

**Real consumer:** Execute against `Web3Client` + `MultiEscrow` contract, return receipt.
**Mock consumer:** Record in `MockChainBackend`, generate deterministic tx hash, return immediately.

### Channel 3: `onNip05` — NIP-05/Lightning address setup

```dart
class Nip05SetupRequest {
  final String username;
  final String domain;
  final String pubkey;
}

class Lud16SetupRequest {
  final String username;
  final String domain;
}
```

**Real consumer:** Call `LnbitsDatasource.setupNip05ByDomain(...)` / `setupUsernamesByDomain(...)`.
**Mock consumer:** Register in `MockVerification` (which already returns `valid: true` for everything, but could be made smarter).

### Channel 4 (optional): `onFunding` — EVM address funding

```dart
class FundingRequest {
  final String address;
  final BigInt amountWei;
  final SeedUser user;
}
```

**Real consumer:** `AnvilClient.setBalance(address, amountWei)`.
**Mock consumer:** No-op, or record in a balance map.

---

## 4. The Dependency Problem (Chain-Dependent Data)

This is the hard part. The pipeline is NOT a simple linear sequence of independent stages. There are **feedback loops**:

```
buildOutcomePlans()                        ← pure, no dependency
        │
        ▼
   For each plan where useEscrow == true:
        │
        ├── emit CreateTradeOp ──────────► consumer executes ──► returns ChainOpResult
        │                                                              │
        ◄──────────────────── plan.createTxHash = result.txHash ◄──────┘
        │
        ├── (if needsSettlement):
        │   emit SettleTradeOp ──────────► consumer executes ──► returns ChainOpResult
        │
        ▼
   buildReservation() uses plan.createTxHash to construct EscrowProof
        │
        ▼
   emit Reservation event via onEvent
```

### Solution: the seeder drives per-thread pipelines concurrently via the sink

> **Updated (A1):** No explicit `consume()` with raw callbacks. The seeder calls individual `SeedSink` methods eagerly. Each thread's chain (request → trade → settle → reservation → review) runs independently. See A1 for the full `Seeder.seed(SeedSink)` implementation.

The seeder emits each instruction the instant its dependencies are satisfied. For chain ops that produce feedback (tx hash), the seeder `await`s the sink's response, then immediately emits the dependent instruction:

```dart
// Inside Seeder.seed() — each thread runs concurrently via Future.wait:
final threadFutures = threads.map((thread) async {
  final plan = buildOutcomePlan(thread);

  if (plan.useEscrow) {
    // Emit createTrade, await result — blocks only THIS thread:
    final result = await sink.submitTrade(SubmitTrade.from(plan));
    plan.createTxHash = result.txHash;

    if (plan.needsSettlement) {
      final settleResult = await sink.settleTrade(SettleTrade.from(plan));
      plan.settleTxHash = settleResult.txHash;
    }
  }

  // NOW build reservation with the real (or mock) tx hash:
  final reservation = buildReservation(thread, plan);
  await sink.publish(reservation);
});

await Future.wait(threadFutures);
```

### Why this works for both real and mock

| Scenario                   | `SeedSink` implementation                                                                                       | What happens                                                  |
| -------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| **Dev seeder**             | `InfrastructureSink` — calls `MultiEscrow.createTrade(...)`, awaits receipt, returns `TradeResult(txHash: ...)` | Real on-chain trade, real tx hash in the reservation          |
| **Integration test**       | Same `InfrastructureSink` but pointed at a local Anvil node                                                     | Real local chain, real tx hash                                |
| **Unit test / screenshot** | `TestSink` — `FakeEscrowLedger.createTrade(op)` records trade in memory, returns deterministic hash             | No chain needed, `EscrowProof.txHash` is a deterministic fake |

---

## 5. Proposed Interfaces

### `Seeder` (replaces `SeedFactory` + `SeedPipeline`)

> **Updated (A1/A4):** Replaces the `consume(onEvent, onChainOp)` callback signature with `seed(SeedSink)`.

```dart
class Seeder {
  final SeederConfig config;

  Seeder({required this.config});

  /// Run all data generation and push instructions through the sink.
  ///
  /// Independent instruction chains (per-user profiles, per-thread
  /// trade pipelines) run concurrently via Future.wait.
  /// Chain operations that return feedback (tx hashes) are awaited
  /// individually — only the dependent thread blocks, not the whole pipeline.
  ///
  /// Returns aggregate data once all instructions complete.
  Future<SeedResult> seed(SeedSink sink);

  /// Convenience: build all pure-data stages without any chain interaction.
  /// All threads remain in "pending" state.
  /// Equivalent to calling seed() with a no-op sink.
  Future<SeedResult> buildAll({DateTime? now});
}
```

### `SeedResult` (replaces `SeedPipelineData`)

```dart
class SeedResult {
  final List<SeedUser> users;
  final List<ProfileMetadata> profiles;
  final List<Listing> listings;
  final List<SeedThread> threads;
  // ... same fields as SeedPipelineData ...

  /// All events in broadcast order.
  List<Nip01Event> get allEvents;

  /// Summary statistics.
  SeedSummary get summary;

  /// All chain operations that were requested (for verification).
  List<ChainOperation> get chainOps;
}
```

### `ChainOperation` sealed hierarchy

```dart
sealed class ChainOperation {
  String get description;
}

class FundAddressOp extends ChainOperation {
  final String address;
  final BigInt amountWei;
  final SeedUser? user;
}

class CreateTradeOp extends ChainOperation {
  final String tradeId;
  final String tradeSalt;
  final String buyerEvmAddress;
  final String sellerEvmAddress;
  final String arbiterEvmAddress;
  final BigInt valueMsats;
  final int unlockAtEpoch;
  final int escrowFeeBps;

  /// The credentials needed to sign the createTrade tx.
  /// (Derived from the guest's Nostr private key.)
  final EthPrivateKey buyerKey;

  /// Contract address to call.
  final String contractAddress;
}

class ClaimTradeOp extends ChainOperation {
  final String tradeId;
  final EthPrivateKey hostKey;
  final String contractAddress;
}

class ArbitrateTradeOp extends ChainOperation {
  final String tradeId;
  final int splitFactorBps;
  final EthPrivateKey arbiterKey;
  final String contractAddress;
}

class ReleaseTradeOp extends ChainOperation {
  final String tradeId;
  final EthPrivateKey hostKey;
  final String contractAddress;
}

class GetBlockTimestampOp extends ChainOperation {}
```

### `ChainOpResult`

```dart
class ChainOpResult {
  final String? txHash;
  final bool success;
  final DateTime? blockTimestamp;

  /// For GetBlockTimestampOp
  const ChainOpResult.timestamp(this.blockTimestamp)
      : txHash = null, success = true;

  /// For transaction operations
  const ChainOpResult.tx({required this.txHash, this.success = true})
      : blockTimestamp = null;
}
```

---

## 6. MockChainBackend — The In-Memory Escrow Simulator

This is the **key new class** that doesn't exist today. It simulates the `MultiEscrow` contract in memory.

```dart
/// In-memory simulation of the MultiEscrow contract.
///
/// Tracks trades, balances, and timestamps. Produces deterministic
/// tx hashes. Use this in unit tests, widget tests, and screenshot
/// pipelines where you need completed escrow flows without a chain.
class MockChainBackend {
  final Map<String, MockTrade> _trades = {};
  final Map<String, BigInt> _balances = {};
  DateTime _chainTime;
  int _nonce = 0;

  MockChainBackend({DateTime? initialTime})
      : _chainTime = initialTime ?? DateTime.now().toUtc();

  /// Execute a chain operation and return a result.
  ///
  /// This is the callback you pass to `SeedFactory.consume(onChainOp:)`.
  Future<ChainOpResult> execute(ChainOperation op) async {
    return switch (op) {
      FundAddressOp(:final address, :final amountWei) =>
          _fund(address, amountWei),
      CreateTradeOp() => _createTrade(op),
      ClaimTradeOp() => _claim(op),
      ArbitrateTradeOp() => _arbitrate(op),
      ReleaseTradeOp() => _release(op),
      GetBlockTimestampOp() =>
          ChainOpResult.timestamp(_chainTime),
    };
  }

  ChainOpResult _fund(String address, BigInt amount) {
    _balances[address] = (_balances[address] ?? BigInt.zero) + amount;
    return ChainOpResult.tx(txHash: _nextTxHash());
  }

  ChainOpResult _createTrade(CreateTradeOp op) {
    if (_trades.containsKey(op.tradeId)) {
      // Idempotent — return existing tx hash (mirrors real contract behavior)
      return ChainOpResult.tx(txHash: _trades[op.tradeId]!.createTxHash);
    }
    final txHash = _nextTxHash();
    _trades[op.tradeId] = MockTrade(
      tradeId: op.tradeId,
      buyer: op.buyerEvmAddress,
      seller: op.sellerEvmAddress,
      arbiter: op.arbiterEvmAddress,
      value: op.valueMsats,
      unlockAt: op.unlockAtEpoch,
      createTxHash: txHash,
      status: TradeStatus.active,
    );
    return ChainOpResult.tx(txHash: txHash);
  }

  ChainOpResult _claim(ClaimTradeOp op) {
    final trade = _trades[op.tradeId];
    if (trade == null) throw StateError('Trade ${op.tradeId} not found');
    if (trade.status != TradeStatus.active) {
      throw StateError('Trade already settled: ${trade.status}');
    }
    final nowEpoch = _chainTime.millisecondsSinceEpoch ~/ 1000;
    if (nowEpoch < trade.unlockAt) {
      throw StateError('Trade not yet unlocked');
    }
    trade.status = TradeStatus.claimed;
    trade.settleTxHash = _nextTxHash();
    return ChainOpResult.tx(txHash: trade.settleTxHash!);
  }

  ChainOpResult _arbitrate(ArbitrateTradeOp op) {
    final trade = _trades[op.tradeId]!;
    trade.status = TradeStatus.arbitrated;
    trade.settleTxHash = _nextTxHash();
    return ChainOpResult.tx(txHash: trade.settleTxHash!);
  }

  ChainOpResult _release(ReleaseTradeOp op) {
    final trade = _trades[op.tradeId]!;
    trade.status = TradeStatus.released;
    trade.settleTxHash = _nextTxHash();
    return ChainOpResult.tx(txHash: trade.settleTxHash!);
  }

  /// Advance mock chain time (mirrors Anvil's evm_increaseTime).
  void advanceTime(Duration duration) {
    _chainTime = _chainTime.add(duration);
  }

  String _nextTxHash() {
    final n = _nonce++;
    return '0x${n.toRadixString(16).padLeft(64, '0')}';
  }

  // ── Query API (for test assertions) ──

  MockTrade? getTrade(String tradeId) => _trades[tradeId];
  List<MockTrade> get allTrades => _trades.values.toList();
  BigInt getBalance(String address) => _balances[address] ?? BigInt.zero;
}

enum TradeStatus { active, claimed, arbitrated, released }

class MockTrade {
  final String tradeId;
  final String buyer, seller, arbiter;
  final BigInt value;
  final int unlockAt;
  final String createTxHash;
  TradeStatus status;
  String? settleTxHash;
}
```

### What this gives you

- **`SeedFactory(config).consume(onChainOp: mockChain.execute)`** produces fully realistic `Reservation` events with `EscrowProof` containing deterministic-but-valid tx hashes.
- Tests can inspect `mockChain.allTrades` to verify the correct trades were created.
- Tests can call `mockChain.advanceTime(...)` before running the factory's claim operations.
- The mock enforces the same constraints as the real contract (can't claim before unlock, can't settle twice, etc.).

---

## 7. MockNip05Backend

```dart
/// In-memory NIP-05 / LUD-16 registry.
///
/// Records setup requests. Integrates with MockVerification
/// so that NIP-05 lookups for seeded users actually resolve.
class MockNip05Backend {
  final Map<String, String> _nip05Registry = {};  // "user@domain" → pubkey
  final Set<String> _lud16Registry = {};           // "user@domain"

  Future<void> handle(Nip05SetupRequest req) async {
    _nip05Registry['${req.username}@${req.domain}'] = req.pubkey;
    _lud16Registry.add('${req.username}@${req.domain}');
  }

  bool hasNip05(String nip05) => _nip05Registry.containsKey(nip05);
  String? pubkeyFor(String nip05) => _nip05Registry[nip05];
  bool hasLud16(String lud16) => _lud16Registry.contains(lud16);
}
```

When paired with the existing `MockVerification` (which always returns `valid: true`), this is often sufficient. For more advanced tests that need realistic NIP-05 resolution, the `MockVerification` could be enhanced to consult the `MockNip05Backend`:

```dart
class SmartMockVerification extends Verification {
  final MockNip05Backend backend;

  @override
  Future<Nip05VerificationResult> verifyNip05({nip05, pubkey}) async {
    final registered = backend.pubkeyFor(nip05);
    return Nip05VerificationResult(valid: registered == pubkey);
  }
}
```

---

## 8. Full Rewrite Plan — File-by-File

### Phase 1: Define the interfaces (new files)

| File                                               | Contents                                                  |
| -------------------------------------------------- | --------------------------------------------------------- |
| `hostr_sdk/lib/seed/pipeline/chain_operation.dart` | `ChainOperation` sealed class hierarchy + `ChainOpResult` |
| `hostr_sdk/lib/seed/pipeline/nip05_setup.dart`     | `Nip05SetupRequest`, `Lud16SetupRequest`                  |
| `hostr_sdk/lib/seed/pipeline/seed_result.dart`     | `SeedResult` (replaces `SeedPipelineData` or wraps it)    |

### Phase 2: Create the mock backends (new files)

| File                                                   | Contents                                                                                         |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `hostr_sdk/lib/seed/mocks/mock_chain_backend.dart`     | `MockChainBackend`, `MockTrade`, `TradeStatus`                                                   |
| `hostr_sdk/lib/seed/mocks/mock_nip05_backend.dart`     | `MockNip05Backend`                                                                               |
| `hostr_sdk/lib/seed/mocks/real_chain_backend.dart`     | `RealChainBackend` — wraps `SeedContext` + `Web3Client` + `MultiEscrow` to implement `onChainOp` |
| `hostr_sdk/lib/seed/mocks/real_nip05_backend.dart`     | `RealNip05Backend` — wraps `LnbitsDatasource` to implement `onNip05`                             |
| `hostr_sdk/lib/seed/mocks/real_broadcast_backend.dart` | `RealBroadcastBackend` — wraps `BroadcastIsolate` to implement `onEvent`                         |

### Phase 3: Rewrite `SeedFactory.consume()` (modify existing)

Rewrite `seed_factory.dart`:

- Move `buildAll()` to call `consume()` with no-op callbacks.
- The `consume()` method runs all stages in order, calling callbacks at each step.
- Stages that don't need chain interaction (`buildUsers`, `buildProfiles`, `buildListings`, `buildMessages`, `buildReviews`) call `onEvent` directly.
- The outcome stage emits `ChainOperation` objects and awaits `ChainOpResult` before building reservations.

### Phase 4: Rewrite `build_outcomes.dart` (modify existing)

This is the most significant change. Currently `build_outcomes.dart`:

1. Directly calls `ctx.chainClient()`, `ctx.multiEscrowContract(...)`, `ctx.retryChainCall(...)`.
2. Reads chain logs to detect pre-existing trades.
3. Assigns nonces and sends batched transactions.
4. Waits for chain time to pass unlock timestamps.

After rewrite:

1. `buildOutcomePlans()` — **unchanged** (already pure).
2. New `emitOutcomeOps()` — yields `ChainOperation` objects for each plan.
3. The factory's `consume()` method drives the loop: emit op → await result → record result → emit next op → ... → build reservation events.

The chain-specific code (nonce management, log scanning, retry logic, HTTP client lifecycle) moves to `RealChainBackend`. The factory never touches `Web3Client`.

### Phase 5: Simplify `SeedPipeline` / `RelaySeeder` (modify existing)

`SeedPipeline` becomes a thin convenience wrapper:

```dart
class SeedPipeline {
  final SeedPipelineConfig config;

  SeedStreams run() {
    final streams = SeedStreams();
    final factory = SeedFactory(config: config);
    final chainBackend = RealChainBackend(config: config);
    final nip05Backend = RealNip05Backend(config: config);

    factory.consume(
      onEvent: (event) async => streams.events.add(event),
      onChainOp: chainBackend.execute,
      onNip05: nip05Backend.handle,
      onFunding: (req) async {
        await chainBackend.fund(req);
        streams.userFunded.add((...));
      },
    ).then(
      (result) { streams.done.add(result); streams.dispose(); },
      onError: (e, st) { streams.events.addError(e, st); streams.dispose(); },
    );

    return streams;
  }
}
```

`RelaySeeder` uses `SeedPipeline.run()` as before (no change to the broadcast isolate flow).

### Phase 6: Simplify test helpers (modify existing)

`TestSeedHelper` and `AppTestSeeder` merge into one pattern:

```dart
// In a test:
final factory = SeedFactory(config: SeedPipelineConfig(seed: 42, userCount: 8));
final mockChain = MockChainBackend();
final events = <Nip01Event>[];

final result = await factory.consume(
  onEvent: (e) async => events.add(e),
  onChainOp: mockChain.execute,
);

// Inject into in-memory relay:
requests.seedEvents(events);

// Inspect chain state:
expect(mockChain.allTrades, hasLength(4));
expect(mockChain.getTrade(tradeId)!.status, TradeStatus.claimed);
```

`TestSeedHelper` can remain as a convenience for single-entity creation (`freshHost()`, `freshGuest()`, `freshThread()`) since those don't need chain interaction.

### Phase 7: Delete dead code

| File                                                                              | Action                                     |
| --------------------------------------------------------------------------------- | ------------------------------------------ |
| `seed_pipeline_models.dart` → `SeedStreams`                                       | Keep (used by `SeedPipeline.run()`)        |
| `seed_pipeline_models.dart` → `SeedPipelineData`                                  | Rename to `SeedResult` or keep as internal |
| `seed_context.dart` → chain client methods                                        | Move to `RealChainBackend`                 |
| `seed_context.dart` → `retryChainCall`, `resetChainClient`, `multiEscrowContract` | Move to `RealChainBackend`                 |
| `seed_context.dart` → `waitForChainTimePast`                                      | Move to `RealChainBackend`                 |
| `seed_context.dart` → RNG + timestamp helpers                                     | Keep (still needed by pure stages)         |

### Summary of file changes

| File                          | Change type     | Effort                                                                        |
| ----------------------------- | --------------- | ----------------------------------------------------------------------------- |
| `chain_operation.dart`        | **New**         | Small — sealed class + result types                                           |
| `nip05_setup.dart`            | **New**         | Small — two data classes                                                      |
| `seed_result.dart`            | **New**         | Small — wraps existing `SeedPipelineData`                                     |
| `mock_chain_backend.dart`     | **New**         | Medium — in-memory escrow sim                                                 |
| `mock_nip05_backend.dart`     | **New**         | Small — map-based registry                                                    |
| `real_chain_backend.dart`     | **New**         | Large — extracts chain logic from `build_outcomes.dart` + `seed_context.dart` |
| `real_nip05_backend.dart`     | **New**         | Small — wraps `LnbitsDatasource`                                              |
| `real_broadcast_backend.dart` | **New**         | Small — wraps `BroadcastIsolate`                                              |
| `seed_factory.dart`           | **Rewrite**     | Large — add `consume()` method                                                |
| `build_outcomes.dart`         | **Rewrite**     | Large — extract chain calls, keep plan logic                                  |
| `seed_pipeline.dart`          | **Simplify**    | Medium — becomes thin wrapper over `consume()`                                |
| `seed_context.dart`           | **Trim**        | Medium — remove chain client management                                       |
| `test_seed_helper.dart`       | **Simplify**    | Small — can use `consume()` internally                                        |
| `seed_pipeline_models.dart`   | **Minor edits** | Small — add `ChainOperation` tracking                                         |
| `relay_seed.dart`             | **Minor edits** | Small — adapt to new `SeedPipeline`                                           |

---

## 9. Migration Path for Existing Consumers

### `AppTestSeeder` / widget tests

**Before:**

```dart
final seeder = AppTestSeeder();
final data = await seeder.seedAll(requests);
// All threads pending — no completed reservations
```

**After:**

```dart
final factory = SeedFactory(config: SeedPipelineConfig(seed: 42, userCount: 8));
final mockChain = MockChainBackend();
final events = <Nip01Event>[];

final result = await factory.consume(
  onEvent: (e) async => events.add(e),
  onChainOp: mockChain.execute,
);
requests.seedEvents(events);
// NOW threads have completed reservations with escrow proofs!
```

### `IntegrationTestHarness` / integration tests

**Before:**

```dart
final harness = await IntegrationTestHarness.create(seed: 42);
// Uses TestSeedHelper for individual fixtures
// Manually calls MultiEscrow contract methods for escrow tests
```

**After:**

```dart
final harness = await IntegrationTestHarness.create(seed: 42);
final factory = SeedFactory(config: config);
final realChain = RealChainBackend(config: config);

final result = await factory.consume(
  onEvent: (e) async => await ndk.broadcast(e),
  onChainOp: realChain.execute,
  onNip05: (req) async => await lnbits.setup(req),
  onFunding: (req) async => await anvil.setBalance(req.address, req.amountWei),
);
```

### `RelaySeeder` / CLI dev seeder

**Before:** Complex `SeedPipeline._runPipeline()` with inline infrastructure calls.
**After:** `SeedPipeline.run()` which calls `SeedFactory.consume()` with real backends. The broadcast isolate attaches to `SeedStreams.events` as before.

### Screenshot pipeline

**Before:** Custom seeding code in each screenshot test.
**After:**

```dart
final factory = SeedFactory(config: SeedPipelineConfig(
  seed: 42, userCount: 8, hostRatio: 0.5,
  threadStages: ThreadStageSpec.allCompleted(),
));
final mockChain = MockChainBackend();
final events = <Nip01Event>[];

await factory.consume(
  onEvent: (e) async => events.add(e),
  onChainOp: mockChain.execute,
);
requests.seedEvents(events);
// All screenshots show completed reservations with escrow proofs
```

---

## 10. End-to-End Example: Integration Test

```dart
void main() {
  late IntegrationTestHarness harness;
  late SeedFactory factory;
  late MockChainBackend mockChain;

  setUp(() async {
    harness = await IntegrationTestHarness.create(seed: 42);
    mockChain = MockChainBackend();
    factory = SeedFactory(
      config: SeedPipelineConfig(
        seed: 42,
        userCount: 4,
        hostRatio: 0.5,
        threadStages: ThreadStageSpec(
          completedRatio: 1.0,
          paidViaEscrowRatio: 1.0,
        ),
      ),
    );
  });

  test('escrow fund → claim → verify reservation', () async {
    final result = await factory.consume(
      onEvent: (e) async => harness.requests.addEvent(e),
      onChainOp: mockChain.execute,
    );

    // All trades created in the mock chain
    final trades = mockChain.allTrades;
    expect(trades.every((t) => t.status != TradeStatus.active), isTrue);

    // All reservations have escrow proofs with tx hashes
    for (final thread in result.threads) {
      if (thread.paidViaEscrow) {
        final proof = thread.reservation!.proof!.escrowProof!;
        expect(proof.txHash, isNotEmpty);
        expect(mockChain.getTrade(/*tradeId*/)?.createTxHash, proof.txHash);
      }
    }

    // Events are in InMemoryRequests — UI queries work
    final listings = harness.requests.query<Listing>(
      filter: Filter(kinds: [Listing.kKind]),
    );
    expect(await listings.toList(), hasLength(greaterThan(0)));
  });
}
```

---

## 11. End-to-End Example: Screenshot Pipeline

```dart
Future<SeedResult> seedForScreenshots(InMemoryRequests requests) async {
  final factory = SeedFactory(
    config: SeedPipelineConfig(
      seed: 42,
      userCount: 8,
      hostRatio: 0.5,
      threadStages: ThreadStageSpec.allCompleted(),
    ),
  );
  final mockChain = MockChainBackend();
  final events = <Nip01Event>[];

  final result = await factory.consume(
    onEvent: (e) async => events.add(e),
    onChainOp: mockChain.execute,
  );

  requests.seedEvents(events);
  return result;
}
```

---

## 12. End-to-End Example: Dev Backend Seeder

```dart
// In relay_seed.dart / CLI entry point:
Future<void> runDevSeeder(SeedPipelineConfig config) async {
  final factory = SeedFactory(config: config);
  final realChain = RealChainBackend(
    rpcUrl: config.rpcUrl,
    contractAddress: resolveContractAddress(),
  );
  final realNip05 = RealNip05Backend(config: config);
  final broadcaster = await BroadcastIsolate.spawn(
    relayUrl: config.relayUrl!,
  );

  var eventIndex = 0;

  final result = await factory.consume(
    onEvent: (event) async {
      await broadcaster.submit(eventIndex++, event);
    },
    onChainOp: realChain.execute,
    onNip05: realNip05.handle,
    onFunding: (req) async {
      await realChain.fund(req);
      print('Funded ${req.address} with ${req.amountWei} wei');
    },
    onLog: print,
  );

  final broadcastResult = await broadcaster.finish();
  print('Broadcast: ${broadcastResult.successCount} ok, '
        '${broadcastResult.failureCount} failed');
  print(result.summary.toJson());
}
```

---

## 13. Escrow Flow Coverage Matrix

What each backend type covers:

| Flow step                  |        `MockChainBackend`        |  `RealChainBackend` (Anvil)   | Notes                                 |
| -------------------------- | :------------------------------: | :---------------------------: | ------------------------------------- |
| `fundAddress`              |        ✅ record balance         |     ✅ `anvil_setBalance`     |                                       |
| `createTrade`              |       ✅ in-memory record        | ✅ `MultiEscrow.createTrade`  | Mock enforces no-duplicate            |
| `claim` (after unlock)     | ✅ check `unlockAt` vs mock time | ✅ real contract + chain time | Mock needs `advanceTime()`            |
| `arbitrate`                |        ✅ record outcome         |       ✅ real contract        |                                       |
| `releaseToCounterparty`    |        ✅ record outcome         |       ✅ real contract        |                                       |
| Log scan (existing trades) |      ✅ query `_trades` map      |       ✅ `getLogs(...)`       | Mock returns synthetic logs           |
| `getBlockTimestamp`        |      ✅ return `_chainTime`      |  ✅ `getBlockInformation()`   |                                       |
| Nonce management           |   ❌ not needed (no real txs)    |   ✅ `getTransactionCount`    |                                       |
| Retry on stale HTTP        |          ❌ not needed           |      ✅ `retryChainCall`      |                                       |
| SwapIn (Boltz submarine)   |         ❌ out of scope          |    ❌ not in seed pipeline    | Separate `FakeSwapInOperation` exists |
| SwapOut (Boltz reverse)    |         ❌ out of scope          |    ❌ not in seed pipeline    | Separate test infrastructure          |
| RIF Relay meta-tx          |         ❌ out of scope          |    ❌ not in seed pipeline    | Production only                       |

### What about SwapIn during escrow fund?

In production, `EscrowFundOperation` triggers a `SwapInOperation` (Lightning → on-chain) whose `onClaim` callback does `claimSwapAndFund` in one transaction. This is an **app-level operation**, not a seed pipeline concern.

For **integration tests that need to test the full fund flow** (SwapIn + EscrowFund):

- Use the existing `FakeSwapInOperation` / `FakeEvmChain` for unit tests.
- Use `IntegrationTestHarness` + real Anvil + real Boltz for E2E.
- The seed pipeline produces the _data_ (listings, threads, reservation requests) that feed into the fund flow — it doesn't need to _execute_ the fund flow itself.

For **integration tests that need a seeded world with completed escrow trades** (e.g., testing the claim/release UI):

- `MockChainBackend` handles this — the seed pipeline creates the trade via the mock, and the resulting `EscrowProof.txHash` is valid within the mock's namespace.
- If the test then needs to _actually_ claim on-chain, swap to `RealChainBackend` for that specific operation.

---

## Appendix: What stays the same

- `SeedPipelineConfig` — unchanged.
- `ThreadStageSpec` — unchanged.
- `SeedUserSpec` — unchanged.
- All pure-data stages (`build_users.dart`, `build_profiles.dart`, `build_listings.dart`, `build_threads.dart`, `build_messages.dart`, `build_reviews.dart`, `build_reservation_transitions.dart`) — unchanged.
- `SeedContext` random/timestamp helpers — unchanged (chain client methods removed).
- `TestSeedHelper` — simplified but API-compatible for single-entity creation.
- `InMemoryRequests` — unchanged (it's already the right abstraction).
- `MockVerification` — unchanged (or optionally enhanced with `MockNip05Backend`).
- `BroadcastIsolate` — unchanged (it's already the right abstraction for relay broadcast).
- `FakeEvmChain` / `FakeSwapInOperation` — unchanged (separate concern: swap recovery testing).

---

## Addendum: Follow-Up Questions

### A1. Eager Emission, Not Stages — Batching Is the Sink's Problem

#### The problem with stage-based grouping

The original proposal grouped instructions into named "phases" (`Phase "profiles"`, `Phase "create-trades"`, etc.) that the seeder would hand to the sink as lists. This is wrong for two reasons:

1. **It forces artificial serialization.** Profile A and Listing B might have no dependency between them, but a stage model emits all profiles before any listings. The seeder is deciding execution order when it shouldn't.
2. **It duplicates the batching decision.** If the seeder groups by phase, and the sink also wants to re-batch (e.g. buffer 50 events then relay-broadcast), you get two layers of batching logic that fight each other.

#### Core principle: emit each instruction the instant its dependencies are satisfied

The seeder is a **dependency graph executor**, not a phase runner. Each instruction has prerequisites (other instructions that must complete first). The seeder kicks off every instruction whose prerequisites are met, concurrently. When a prerequisite completes (especially chain ops that return a `TradeResult`), the seeder immediately emits any newly-unblocked instructions.

The sink receives individual instructions one at a time. If it wants to batch, it buffers internally.

#### The dependency graph

```
User keys (pure, synchronous)
   │
   ├──► Profile event ──────────────┐
   │       │                        │
   │       ├──► Listing event ──────┤
   │       │       │                │
   │       │       ├──► Thread/Request events
   │       │       │       │
   │       │       │       ├──► DM events (gift-wrapped, async crypto)
   │       │       │       │
   │       │       │       ├──► [if escrow] SubmitTrade ──await──► TradeResult
   │       │       │       │                                           │
   │       │       │       │       ┌───────────────────────────────────┘
   │       │       │       │       │
   │       │       │       │       ├──► [if settle] SettleTrade ──await──► TradeResult
   │       │       │       │       │                                          │
   │       │       │       │       ├──► Reservation event (uses txHash) ◄─────┘
   │       │       │       │       │
   │       │       │       │       └──► ReservationTransition events
   │       │       │       │
   │       │       │       ├──► [if zap] ZapRequest + ZapReceipt events (pure)
   │       │       │       │       │
   │       │       │       │       └──► Reservation event (uses zapReceipt)
   │       │       │       │
   │       │       │       └──► Review event (after reservation)
   │       │       │
   │       ├──► EscrowTrust event
   │       ├──► EscrowMethod event
   │       │
   │       ├──► FundWallet (no downstream deps, fire-and-forget)
   │       └──► RegisterIdentity (no downstream deps, fire-and-forget)
   │
   └──► EscrowService event
       └──► EscrowProfile event
```

Crucially: **independent branches run concurrently.** Thread A's `SubmitTrade` and Thread B's `SubmitTrade` are in-flight at the same time. The seeder doesn't wait for all trades to complete before starting settlements — it starts Thread A's `SettleTrade` the moment Thread A's `SubmitTrade` returns, even if Thread B is still pending.

#### `SeedSink` — singular methods, not batch methods

```dart
/// The port through which the seeder pushes side effects.
///
/// Every method takes a single instruction. The implementation decides
/// whether to execute immediately, buffer, rate-limit, etc.
///
/// Chain-op methods return a result because the seeder needs feedback
/// (tx hash) to build downstream events. Event/identity methods are
/// fire-and-forget from the seeder's perspective (the sink may still
/// await delivery internally).
abstract class SeedSink {
  /// Publish a single Nostr event.
  Future<void> publish(Nip01Event event);

  /// Submit a trade to the escrow contract. Returns the tx hash.
  Future<TradeResult> submitTrade(SubmitTrade intent);

  /// Settle an existing trade (claim / arbitrate / release).
  Future<TradeResult> settleTrade(SettleTrade intent);

  /// Fund an EVM address.
  Future<void> fund(FundWallet intent);

  /// Register a NIP-05 / LUD-16 identity.
  Future<void> registerIdentity(RegisterIdentity intent);
}
```

#### How the seeder drives concurrency

The seeder doesn't batch — it launches concurrent `Future`s and awaits them in the right dependency order:

```dart
Future<SeedResult> seed(SeedSink sink) async {
  // ── Pure data generation (synchronous) ────────────────────
  final users = buildUsers();
  final hosts = users.where((u) => u.isHost).toList();
  final guests = users.where((u) => !u.isHost).toList();

  // ── Fan out: every user's pipeline runs concurrently ──────
  // Profiles, escrow config, listings — all independent of each other.
  final profileFutures = users.map((u) async {
    final profile = await buildProfile(u);
    await sink.publish(profile);
    return profile;
  });

  final escrowProfileFuture = buildEscrowProfile()
      .then((p) async { await sink.publish(p); return p; });

  final escrowServiceFuture = buildEscrowServices()
      .then((list) async { for (final s in list) await sink.publish(s); return list; });

  // Funding + identity registration: fire-and-forget, no downstream deps.
  final fundingFutures = users.map((u) async {
    if (!config.fundProfiles) return;
    await sink.fund(FundWallet(address: u.evmAddress, amount: config.fundAmount));
  });

  final identityFutures = users.map((u) async {
    if (!u.setupLnbits) return;
    await sink.registerIdentity(RegisterIdentity.fromProfile(u));
  });

  // Await profiles — listings depend on host profiles existing.
  final profiles = await Future.wait(profileFutures);
  final escrowServices = await escrowServiceFuture;

  // Trusts/methods depend on profiles.
  final trustFutures = users.map((u) async {
    final trust = await buildEscrowTrust(u);
    await sink.publish(trust);
    return trust;
  });
  final methodFutures = users.map((u) async {
    final method = await buildEscrowMethod(u);
    await sink.publish(method);
    return method;
  });

  // Listings depend on host profiles.
  final listingFutures = hosts.map((host) async {
    final listings = buildListings(host);
    for (final l in listings) await sink.publish(l);
    return listings;
  });
  final allListings = (await Future.wait(listingFutures)).expand((l) => l).toList();

  // ── Per-thread pipelines: fully concurrent ────────────────
  // Each thread runs its own chain: request → DMs → trade → settle → reservation → review.
  final threadFutures = buildThreadAssignments(guests, allListings).map((assignment) async {
    final thread = await buildThread(assignment);

    // DMs: independent of outcome, start immediately.
    final dmFuture = buildMessages(thread).then((msgs) async {
      for (final m in msgs) await sink.publish(m);
    });

    // Outcome: depends on plan.
    final plan = buildOutcomePlan(thread);

    if (plan.useEscrow) {
      // Submit trade — blocks until tx confirmed (real) or recorded (mock).
      final createResult = await sink.submitTrade(SubmitTrade.from(plan));
      plan.createTxHash = createResult.txHash;

      // Settlement — blocks until complete.
      if (plan.needsSettlement) {
        final settleResult = await sink.settleTrade(SettleTrade.from(plan));
        plan.settleTxHash = settleResult.txHash;
      }
    } else {
      // Zap path: build receipt events (pure).
      final (zapRequest, zapReceipt) = buildZapReceipt(thread);
      await sink.publish(zapRequest);
      await sink.publish(zapReceipt);
    }

    // Reservation: needs txHash (escrow) or zapReceipt (zap).
    final reservation = buildReservation(thread, plan);
    await sink.publish(reservation);

    // Transitions.
    for (final t in buildTransitions(thread)) {
      await sink.publish(t);
    }

    // DMs must finish before we can build escrow-selected messages.
    await dmFuture;
    final escrowMsgs = await buildEscrowSelectedMessages(thread);
    for (final m in escrowMsgs) await sink.publish(m);

    // Review: after reservation.
    if (plan.shouldReview) {
      await sink.publish(buildReview(thread));
    }

    return thread;
  });

  final threads = await Future.wait(threadFutures);

  // Await fire-and-forget side effects.
  await Future.wait([...fundingFutures, ...identityFutures]);
  await Future.wait(trustFutures);
  await Future.wait(methodFutures);

  return SeedResult(users: users, profiles: profiles, threads: threads, ...);
}
```

**What's happening here:**

- 50 user profiles emit concurrently.
- Listings emit the instant their host's profile is done.
- Every thread's pipeline (DMs + trade + settlement + reservation + review) runs independently.
- Thread A's settlement starts while Thread B's trade creation is still in-flight.
- Funding and identity registration run fully in parallel, no one waits for them.

#### The sink buffers if it wants to

The seeder calls `sink.publish(event)` 300 times concurrently. A `TestSink` handles each one synchronously (adds to `InMemoryRequests`). An `InfrastructureSink` can internally buffer and batch:

```dart
class InfrastructureSink implements SeedSink {
  final _publishQueue = <Nip01Event>[];
  final _semaphore = Semaphore(maxConcurrent: 5);
  Timer? _flushTimer;

  @override
  Future<void> publish(Nip01Event event) async {
    // Acquire a semaphore slot, then broadcast.
    await _semaphore.acquire();
    try {
      await broadcaster.submit(event);
    } finally {
      _semaphore.release();
    }
  }

  @override
  Future<TradeResult> submitTrade(SubmitTrade intent) async {
    // Nonce management is the sink's problem.
    final nonce = await _acquireNonce(intent.senderAddress);
    final txHash = await contract.createTrade(
      intent.toArgs(),
      credentials: intent.credentials,
      transaction: Transaction(nonce: nonce, value: intent.value, ...),
    );
    await _waitForReceipt(txHash);
    return TradeResult(txHash: txHash);
  }
}
```

```dart
class TestSink implements SeedSink {
  final InMemoryRequests requests;
  final FakeEscrowLedger escrow;
  final FakeIdentityRegistry identities;

  @override
  Future<void> publish(Nip01Event event) async {
    requests.addEvent(event);
  }

  @override
  Future<TradeResult> submitTrade(SubmitTrade intent) async {
    return escrow.createTrade(intent);
  }

  @override
  Future<TradeResult> settleTrade(SettleTrade intent) async {
    return escrow.settle(intent);
  }

  @override
  Future<void> fund(FundWallet intent) async {
    escrow.setBalance(intent.address, intent.amount);
  }

  @override
  Future<void> registerIdentity(RegisterIdentity intent) async {
    identities.register(intent);
  }
}
```

#### Why this is better than phases

| Phases model                                                                                | Eager-emit model                                                      |
| ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| All profiles → all listings → all threads → all trades → all settlements → all reservations | Each thread's full lifecycle runs independently and concurrently      |
| A slow trade creation blocks _all_ reservations                                             | A slow trade creation blocks only _that thread's_ reservation         |
| Seeder decides batch size                                                                   | Sink decides batch size                                               |
| Artificial serialization points between phases                                              | Only real data dependencies cause waiting                             |
| 50 users × 10 threads = 500 trade creations in one `Future.wait` (may overwhelm Anvil)      | 500 trade creations fan out naturally, sink rate-limits via semaphore |
| Adding a new instruction type requires editing the phase grouping logic                     | Adding a new instruction type is just a new `SeedSink` method         |

---

### A2. In-Memory EVM Chain Mock — Can We Avoid Rolling Our Own?

#### The Dart ecosystem has nothing

After exhaustive search: **there is no Dart package that provides an in-memory EVM execution environment.** No Ganache-dart, no Hardhat-dart, no `ethereum_test` mock. The Dart EVM ecosystem consists of:

- `web3dart` — JSON-RPC client only (no chain simulation)
- `ethereum` — another JSON-RPC client
- `wallet` — key derivation and signing

All EVM test tooling in the ecosystem (Hardhat, Ganache, Anvil, Revm) is written in JavaScript, TypeScript, or Rust. The Dart world has always relied on running a **real local node** (Ganache/Anvil in Docker) for chain-level testing.

#### Three options evaluated

| Option                        | Approach                                                                                                                                                                                        | Pros                                                                             | Cons                                                                                                                                                  |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A. Application-level mock** | Mock at our contract's semantic level (trades, balances, timestamps). Don't simulate EVM opcodes.                                                                                               | Simple, fast, no dependencies, covers exactly our contract.                      | Must be maintained when contract changes. Not a general EVM sim.                                                                                      |
| **B. Embedded Anvil via FFI** | Bundle Anvil (Rust) as a native library, call via `dart:ffi`.                                                                                                                                   | Full EVM fidelity, same tool as dev stack.                                       | Massive FFI complexity, platform-specific builds, defeats the purpose of "no Docker".                                                                 |
| **C. JSON-RPC mock server**   | Run a `shelf` HTTP server that responds to `eth_sendRawTransaction`, `eth_getTransactionReceipt`, `eth_getLogs` etc. with canned or stateful responses. Point `Web3Client` at `localhost:PORT`. | `web3dart` works unmodified, test code uses real `Web3Client` → higher fidelity. | Must implement enough JSON-RPC methods to not crash. Tx hashes must be valid-looking. Receipt fields must be well-formed. Ongoing maintenance burden. |

#### Recommendation: Option A with Option C as a future enhancement

**Option A (application-level mock) is the right choice.** Here's why:

1. **Your contract surface is small.** `MultiEscrow` has 6 write methods and 4 read methods. The mock only needs to simulate those 10 behaviors, not the entire EVM.

2. **`EscrowProof.txHash` is never verified on-chain by the app.** The `Reservation.validate()` escrow path is a `// TODO` stub — it just sets `escrowProof: true`. The tx hash is stored as a plain `String` in the Nostr event and never parsed by `web3dart` classes downstream.

3. **Deterministic tx hashes are safe.** The pipeline only reads `receipt.status` from `TransactionReceipt` — and that's in the real chain path only. The mock path never constructs `TransactionReceipt` objects. Tx hashes are just strings.

4. **Contract changes are rare and you already version-lock them.** `MultiEscrow.g.dart` is generated from the ABI. When the contract changes, the `.g.dart` changes, and the mock's 10 methods get a compile error — you fix them at the same time. This is manageable.

#### Why Option C is overkill today but worth noting

A JSON-RPC mock server would let you test the _actual_ `RealChainBackend` (with its nonce management, retry logic, receipt polling) against a fake chain. This is valuable if you suspect those plumbing layers have bugs. But:

- The plumbing is already tested against real Anvil in integration tests.
- The seed pipeline's goal is to produce realistic _data_, not to test chain plumbing.
- Option C would require implementing `eth_sendRawTransaction` (which means parsing RLP-encoded transactions, recovering the sender, validating signatures) — that's 80% of an EVM reimplementation.

If you ever want Option C, the cleanest path is to **spawn a real Anvil process** (not Docker — just the binary) in test setup. Anvil starts in ~100ms and uses ~10MB RAM. But that's a separate concern from the seed pipeline mock.

#### How to handle the `web3dart` type fragility concern

Your worry about `TransactionInformation`, `TransactionReceipt` etc. throwing if fields are imperfect is valid _in general_ but not a problem here because:

| Type                            | Where it's constructed                                        | Mock exposure                                                                                                                                                                                   |
| ------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `TransactionReceipt`            | Only by `web3dart` JSON-RPC parsing (`getTransactionReceipt`) | **Never** — the mock doesn't construct `TransactionReceipt`. It returns `ChainOpResult(txHash: "0x...")`.                                                                                       |
| `EthereumAddress`               | By `EthereumAddress.fromHex(hex)` — validates 40 hex chars    | The mock's `MockTrade.buyer/seller/arbiter` store raw strings. `EthereumAddress.fromHex` is only called in the factory stage that derives addresses from keys (pure code, no mock involvement). |
| `Credentials` / `EthPrivateKey` | By `deriveEvmKey(nostrPrivateKey)`                            | Same — derived in the pure stage, passed _into_ the `ChainOperation` descriptor. The mock receives the op, ignores the credentials, records the trade.                                          |

**Net: the mock never interacts with `web3dart` types.** It operates entirely at the `ChainOperation` / `ChainOpResult` level (plain Dart strings and ints). The type boundary between `web3dart` and the mock is the `SeedSink` interface.

---

### A3. Mock LNURL/Lightning Backend — Producing Realistic Zap Receipts

#### What the current pipeline does

`_buildZapReceipt` in `build_outcomes.dart` constructs two events:

1. **Zap Request (kind 9734)** — signed by the guest:
   - Tags: `p` (recipient), `amount`, `e` (trade ID), `l` (listing anchor), `lnurl`
   - Content: `"Seed zap request"`

2. **Zap Receipt (kind 9735)** — signed by the host (acting as LNURL backend):
   - Tags: `bolt11` (fake invoice), `preimage` (fake), `amount`, `p`/`P` (recipient/sender), `e` (zap request event ID), `l`, `lnurl`, `description` (serialized zap request JSON)
   - Content: `"Seed zap payment"`

#### What the app validates

From `Reservation.validate()`:

- `receipt.amountSats >= expected`
- `receipt.recipient == listing.pubKey`
- `proof.hoster.pubKey == listing.pubKey`
- `receipt.lnurl == Metadata.fromEvent(proof.hoster).lud16`

#### What a mock LNURL backend needs to produce

The mock doesn't need a real Lightning node. It needs to:

1. **Accept a zap request** (the pipeline produces this).
2. **Return a kind-9735 event** with matching tags.
3. **The `bolt11` and `preimage` can be stubs** — the app only reads `amountSats`, `recipient`, `sender`, `lnurl` from the receipt.

This is already what `_buildZapReceipt` does. The issue is that it's **hardcoded into `build_outcomes.dart`** instead of being delegable.

#### Proposed `MockIdentityBackend`

The NIP-05 / LUD-16 / Zap concern should be unified into a single identity backend because they're all facets of the same thing: "this user has a Lightning address and a NIP-05 identifier":

```dart
/// In-memory identity and Lightning address backend.
///
/// Replaces LnbitsDatasource for tests.
/// Produces mock zap receipts when asked.
/// Integrates with MockVerification.
class MockIdentityBackend {
  final Map<String, IdentityRecord> _identities = {};

  /// Register a NIP-05 + LUD-16 identity.
  void register(IdentitySetup setup) {
    final key = '${setup.username}@${setup.domain}';
    _identities[key] = IdentityRecord(
      username: setup.username,
      domain: setup.domain,
      pubkey: setup.pubkey,
    );
  }

  /// Check NIP-05 validity — delegates to registry.
  bool verifyNip05(String nip05, String pubkey) {
    return _identities[nip05]?.pubkey == pubkey;
  }

  /// Check LUD-16 reachability — always true if registered.
  bool verifyLud16(String lud16) => _identities.containsKey(lud16);

  /// All registered identities (for test assertions).
  List<IdentityRecord> get allIdentities => _identities.values.toList();
}

class IdentityRecord {
  final String username;
  final String domain;
  final String pubkey;
  const IdentityRecord({
    required this.username,
    required this.domain,
    required this.pubkey,
  });
}
```

**Zap receipts stay in the factory.** The `_buildZapReceipt` logic is pure (no I/O) — it constructs deterministic kind-9734/9735 events from seed data. It doesn't need a mock backend. It just needs to be part of the factory's output, not tied to the outcome stage. The mock identity backend's role is to make `verifyNip05` and `verifyLud16` return correct answers for seeded users — which feeds into `Reservation.validate()`.

---

### A4. Architecture Critique & Ideal Rewrite Naming

#### What's non-standard about the current naming

| Current                                                   | Problem                                                                                                                 | Industry standard                                                  |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| `SeedFactory`                                             | "Factory" implies object creation, but this class is an orchestrator that runs a multi-stage pipeline.                  | **`Seeder`** or **`DataGenerator`** or **`TestDataPipeline`**      |
| `SeedPipeline`                                            | Confusing because `SeedFactory` already does most of the work. `SeedPipeline` is really "SeedFactory + infrastructure". | Shouldn't exist as a separate class.                               |
| `SeedContext`                                             | Mixes three concerns: RNG state, timestamp helpers, AND chain client management.                                        | Split into `SeedRng` (pure) and `ChainClient` (infra).             |
| `SeedStreams`                                             | `ReplaySubject` streams are an implementation detail leaking into the API. Callers shouldn't need to know about RxDart. | The `SeedSink` pattern (push, don't pull).                         |
| `buildOutcomes()` / `buildMessages()` / `buildListings()` | Free functions in separate files that take `ctx` as the first argument. This is a poor man's method dispatch.           | Methods on a class, or a proper stage pipeline pattern.            |
| `TestSeedHelper` / `AppTestSeeder`                        | Two different wrappers for the same thing with slightly different APIs.                                                 | One class: **`TestDataSeeder`** or just use the `Seeder` directly. |
| `MockChainBackend` (proposed)                             | "Backend" is vague.                                                                                                     | **`InMemoryEscrow`** or **`FakeEscrowLedger`**                     |
| `onChainOp` / `ChainOperation`                            | "Operation" is overloaded (already used for `SwapInOperation`, `EscrowFundOperation`).                                  | **`ChainIntent`** / **`ChainCommand`** / **`EvmCall`**             |
| `ChainOpResult`                                           | Generic.                                                                                                                | **`EvmReceipt`** or **`TxResult`**                                 |

#### Ideal architecture if rewriting from scratch

The gold-standard pattern for this type of system is **Hexagonal Architecture** (Ports & Adapters), which you already partially use (`CalendarPort`, `SupportedEscrowContract`):

```
┌──────────────────────────────────────────────────────────────┐
│                        Seeder Core                           │
│                   (Pure Dart, no I/O)                         │
│                                                              │
│   Seeder(config) ──► builds data, emits instructions to      │
│                      the sink one at a time, eagerly,        │
│                      using Future.wait for concurrency        │
│                                                              │
│   Each instruction is a value object:                        │
│     PublishEvent(event)                                      │
│     SubmitTrade(tradeId, buyer, seller, ...)                 │
│     SettleTrade(tradeId, method)                             │
│     RegisterIdentity(username, domain, pubkey)               │
│     FundWallet(address, amount)                              │
└──────────────────────┬───────────────────────────────────────┘
                       │
              ┌────────┴─────────┐
              │    SeedSink      │  ← Port (abstract interface)
              │                  │
              │  publish()       │  ← single event
              │  submitTrade()   │  ← returns TradeResult
              │  settleTrade()   │  ← returns TradeResult
              │  registerIdentity│
              │  fund()          │
              └────────┬─────────┘
                       │
         ┌─────────────┼──────────────┐
         ▼             ▼              ▼
  ┌─────────────┐ ┌──────────┐ ┌──────────────┐
  │ AnvilSink   │ │ TestSink │ │ DryRunSink   │  ← Adapters
  │             │ │          │ │              │
  │ NDK relay   │ │ InMemory │ │ Logs only    │
  │ Web3 chain  │ │ Requests │ │ No side      │
  │ LNbits REST │ │ + FakeLedger│ │ effects     │
  │ AnvilClient │ │ + FakeIds│ │              │
  └─────────────┘ └──────────┘ └──────────────┘
```

#### Naming convention (if permitted a full rewrite)

```
hostr_sdk/lib/seed/
├── seeder.dart                    # Seeder class (the only public entry point)
├── seeder_config.dart             # SeederConfig (was SeedPipelineConfig)
├── seed_rng.dart                  # SeedRng (pure: Random + timestamps)
├── seed_result.dart               # SeedResult (aggregate output)
├── sink/
│   ├── seed_sink.dart             # SeedSink abstract interface (the Port)
│   ├── infrastructure_sink.dart   # Real backends (NDK + Anvil + LNbits)
│   ├── test_sink.dart             # InMemoryRequests + FakeEscrowLedger + FakeIdentities
│   └── dry_run_sink.dart          # Logging only, no side effects
├── model/
│   ├── seed_user.dart
│   ├── seed_thread.dart
│   ├── seed_instruction.dart      # Sealed: PublishEvent | SubmitTrade | ...
│   ├── trade_result.dart          # TradeResult (was ChainOpResult)
│   └── identity_setup.dart
├── stage/                         # Pure-data builder functions (no I/O)
│   ├── users.dart
│   ├── profiles.dart
│   ├── listings.dart
│   ├── threads.dart
│   ├── messages.dart
│   ├── outcomes.dart              # Returns outcome plans + reservation builders (no chain calls)
│   └── reviews.dart
└── fake/
    ├── fake_escrow_ledger.dart    # In-memory MultiEscrow simulator
    ├── fake_identity_registry.dart # In-memory NIP-05/LUD-16 registry
    └── fake_lightning.dart         # Produces mock bolt11/zap receipts (if needed)
```

#### Key naming changes

| Old                                          | New                                                                         | Rationale                                                                                                                                                                                              |
| -------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `SeedFactory`                                | `Seeder`                                                                    | It's a seeder, not a factory.                                                                                                                                                                          |
| `SeedPipeline`                               | Deleted                                                                     | `Seeder` + `InfrastructureSink` replaces it.                                                                                                                                                           |
| `SeedPipelineConfig`                         | `SeederConfig`                                                              | Shorter, obvious.                                                                                                                                                                                      |
| `SeedContext`                                | `SeedRng`                                                                   | Only the pure parts survive.                                                                                                                                                                           |
| `ChainOperation`                             | `sealed class SeedInstruction`                                              | Unified with events and identities.                                                                                                                                                                    |
| `ChainOpResult`                              | `TradeResult`                                                               | Specific to what it is.                                                                                                                                                                                |
| `MockChainBackend`                           | `FakeEscrowLedger`                                                          | "Fake" is the xUnit pattern for a self-verifying test double. "Ledger" describes what it tracks.                                                                                                       |
| `MockNip05Backend`                           | `FakeIdentityRegistry`                                                      | Same.                                                                                                                                                                                                  |
| `MockVerification` → `SmartMockVerification` | `FakeIdentityRegistry` implements `Verification`                            | One class, not two.                                                                                                                                                                                    |
| `SeedStreams`                                | Deleted                                                                     | The `SeedSink` replaces push-based RxDart subjects with pull-based method calls. For legacy consumers that need reactive streams, a `StreamingSink` adapter wraps `SeedSink` and re-emits to subjects. |
| `TestSeedHelper` + `AppTestSeeder`           | `TestSeeder`                                                                | One helper. `TestSeeder(config).seed(requests)` does everything.                                                                                                                                       |
| `build_outcomes.dart` (free function)        | `stage/outcomes.dart` exporting `buildOutcomePlan()` + `buildReservation()` | Pure plan/reservation builders; chain interaction happens via the sink in `Seeder.seed()`                                                                                                              |

#### The test ergonomics you asked for

```dart
// Unit test / widget test / screenshot:
final seeder = Seeder(config: SeederConfig(seed: 42, userCount: 8));
final sink = TestSink();  // InMemoryRequests + FakeEscrowLedger + FakeIdentityRegistry

final result = await seeder.seed(sink);

// Everything is populated — events, completed escrow trades, identities.
// The InMemoryRequests inside `sink` is ready for subscription/query.
// FakeEscrowLedger can be inspected:
expect(sink.escrow.allTrades, hasLength(4));
expect(sink.identities.allRecords, hasLength(8));
```

```dart
// Integration test against real Docker stack:
final seeder = Seeder(config: config);
final sink = InfrastructureSink(
  relay: ndk,
  chain: Web3Client(rpcUrl, httpClient),
  contract: MultiEscrow(address: addr, client: chain),
  anvil: AnvilClient(rpcUri: uri),
  lnbits: LnbitsDatasource(),
  lnbitsConfig: lnbitsConfig,
);

final result = await seeder.seed(sink);
```

```dart
// Dev backend seeder (CLI):
final seeder = Seeder(config: configFromArgs);
final sink = InfrastructureSink.fromEnvironment();

final result = await seeder.seed(sink);
print(result.summary.toJson());
```

```dart
// Multiple mock chains for multi-instance testing:
final chain1 = FakeEscrowLedger();
final chain2 = FakeEscrowLedger();

chain1.mineBlock();  // advance chain1 time by 12s
chain2.advanceTime(Duration(hours: 1));  // chain2 is 1 hour ahead

final sink1 = TestSink(escrow: chain1);
final sink2 = TestSink(escrow: chain2);

await Seeder(config: config1).seed(sink1);
await Seeder(config: config2).seed(sink2);
```
