# Code Readability Audit — EVM / Swap / Escrow / Wallet / Token Stack

> **Goal**: Decrease cognitive load, eliminate mixed concerns, enforce DRY,
> and **reduce LOC by ≈ 30 %** across the audited subsystems.
>
> **Constraint**: No backward compatibility required — any interface or data
> shape can change.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Finding 1 — God Class `EvmChain`](#2-finding-1--god-class-evmchain-700-loc)
3. [Finding 2 — Duplicated Decimal Parsing](#3-finding-2--duplicated-decimal-parsing-in-tokenamount--denominatedamount)
4. [Finding 3 — State-Class Boilerplate Explosion](#4-finding-3--state-class-boilerplate-explosion)
5. [Finding 4 — SwapIn / SwapOut Structural Duplication](#5-finding-4--swapin--swapout-structural-duplication)
6. [Finding 5 — Three Escrow Directories](#6-finding-5--three-escrow-directories-with-confusing-naming)
7. [Finding 6 — `MultiEscrowWrapper` Does Too Much](#7-finding-6--multiescrowwrapper-does-too-much-500-loc)
8. [Finding 7 — `OnchainOperationData` Overengineered copyWith](#8-finding-7--onchainoperationdata-overengineered-copywith)
9. [Finding 8 — SwapRegistry Copy-Paste](#9-finding-8--swapregistry-copy-paste)
10. [Finding 9 — Scattered Token-Amount Conversions](#10-finding-9--scattered-token-amount-conversions)
11. [Finding 10 — Misplaced Free Functions in evm_chain.dart](#11-finding-10--misplaced-free-functions-in-evm_chaindart)
12. [Refactoring Roadmap](#12-refactoring-roadmap)
13. [LOC Reduction Estimate](#13-loc-reduction-estimate)

---

## 1. Executive Summary

| Smell                                   | Where                                                                 | Estimated LOC saved     |
| --------------------------------------- | --------------------------------------------------------------------- | ----------------------- |
| God class                               | `evm_chain.dart`                                                      | 200                     |
| Duplicated parsing                      | `token_amount.dart` + `denominated_amount.dart`                       | 60                      |
| State-class `toJson` boilerplate        | `swap_in_state.dart`, `swap_out_state.dart`, `onchain_operation.dart` | 250                     |
| SwapIn ↔ SwapOut structural duplication | `swap_in_*` vs `swap_out_*`                                           | 350                     |
| Three escrow directories                | `escrow/`, `escrows/`, `escrow_methods/`                              | 40 (cognitive, not LOC) |
| MultiEscrowWrapper mixed concerns       | `multi_escrow.dart`                                                   | 150                     |
| OnchainOperationData copyWith methods   | `onchain_operation.dart`                                              | 60                      |
| SwapRegistry copy-paste                 | `swap_registry.dart`                                                  | 80                      |
| Scattered conversion helpers            | `token_amount_ext.dart` + `evm_chain.dart`                            | 30                      |
| Misplaced free functions                | `evm_chain.dart` bottom                                               | 10                      |
| **Total**                               |                                                                       | **≈ 1 230 LOC**         |

Current combined LOC across audited files: **≈ 4 100**. Target: **≈ 2 870** (−30 %).

---

## 2. Finding 1 — God Class `EvmChain` (700+ LOC)

### Problem

`EvmChain` is a single class responsible for:

1. **RPC transport** — Web3Client lifecycle, retry logic, exponential backoff
2. **Block polling** — `_newBlocks` stream, `notifyNewBlock()`
3. **Log batching** — `getLogs`, debounced queue merging, topic deduplication
4. **HD address scanning** — `getNextUnusedAddress`, `getAddressesWithBalance`
5. **Balance queries** — native balance, ERC-20 balance
6. **Token registry** — `resolveToken`, `resolveTokenDecimals`, `resolveBoltzFundingToken`
7. **Swap/quote factories** — `swapIn()`, `swapOut()`, `swapInQuote()`, `swapOutQuote()`
8. **Transaction sending** — AA vs EOA dispatch, `sendCalls()`, EOA gas estimation
9. **Gas estimation** — `estimateGas()` dispatching to AA or EOA
10. **Utility** — `convertWeiToSatoshi`, `convertWeiToBTC` (standalone)

This means every developer touching _any_ EVM concern must load the
entire 700-line file into their head.

### Current (messy)

```dart
class EvmChain {
  // ... transport fields ...
  // ... capability fields ...
  // ... balance monitor ...
  // ... block polling ...
  // ... getLogs batching + queue + timers ...
  // ... HD scanning ...
  // ... balance queries ...
  // ... token registry ...
  // ... swap factories ...
  // ... quote factories ...
  // ... sendCalls / estimateGas / EOA internals ...
}

double convertWeiToSatoshi(BigInt wei) { ... } // why is this here?
double convertWeiToBTC(BigInt wei) { ... }     // and this?
```

### Ideal (clean)

```dart
/// Pure RPC transport with retry + client lifecycle.
class EvmRpcTransport {
  Web3Client get client => ...;
  int get clientGeneration => ...;
  Future<T> callWithRetry<T>(String op, Future<T> Function(Web3Client) fn);
  Stream<int> newBlocks({Duration interval});
  void notifyNewBlock();
  Future<void> dispose();
}

/// Batched getLogs with debounce and topic merging.
class EvmLogsBatcher {
  EvmLogsBatcher(this._transport);
  Future<List<FilterEvent>> getLogs(FilterOptions filter, {EvmLogsBatchHint? hint});
}

/// Lazily resolved token registry.
class EvmTokenRegistry {
  EvmTokenRegistry(this._transport, this._config);
  Future<Token> resolve(String address);
  Token? cached(String address);
  Future<int> resolveDecimals(String address);
}

/// HD address scanning.
class EvmAddressScanner {
  EvmAddressScanner(this._transport, this._auth);
  Future<({EthereumAddress address, int accountIndex})> nextUnused();
  Future<List<...>> addressesWithBalance();
}

/// Thin facade — composes the above.
class EvmChain {
  final EvmChainConfig config;
  final EvmRpcTransport transport;
  final EvmLogsBatcher logs;
  final EvmTokenRegistry tokens;
  final EvmAddressScanner scanner;
  final AACapability? aa;
  BoltzSwapProvider? swaps;
  late final EscrowCapability escrow;
  late final EvmBalanceMonitor balanceMonitor;

  // Only delegation — no business logic here
  Future<String> sendCalls(EthPrivateKey signer, Map<String, Call> calls) =>
      aa != null
          ? aa!.sendUserOp(signer, calls)
          : _sendEoaCalls(signer, calls);
}
```

Each extracted class: **80–150 LOC**, easy to test in isolation.

---

## 3. Finding 2 — Duplicated Decimal Parsing in `TokenAmount` & `DenominatedAmount`

### Problem

Both `models/lib/token_amount.dart` and `models/lib/denominated_amount.dart`
contain **identical** private functions:

```dart
// token_amount.dart
BigInt _parseDecimalToBigInt(String input, int decimals) { ... }
String _formatDecimal(BigInt value, int decimals, {int? maxDecimals}) { ... }

// denominated_amount.dart — EXACT SAME CODE
BigInt _parseDecimalToBigInt(String input, int decimals) { ... }
String _formatDecimal(BigInt value, int decimals, {int? maxDecimals}) { ... }
```

That's **≈ 60 duplicated lines**.

### Ideal (clean)

```dart
// models/lib/src/decimal_math.dart
BigInt parseDecimalToBigInt(String input, int decimals) { ... }
String formatDecimal(BigInt value, int decimals, {int? maxDecimals}) { ... }

// token_amount.dart
import 'src/decimal_math.dart' as decimal;
factory TokenAmount.fromDecimal(String s, Token t) =>
    TokenAmount(value: decimal.parseDecimalToBigInt(s, t.decimals), token: t);

// denominated_amount.dart
import 'src/decimal_math.dart' as decimal;
factory DenominatedAmount.fromDecimal(String s, String denom, int dec) =>
    DenominatedAmount(value: decimal.parseDecimalToBigInt(s, dec), ...);
```

---

## 4. Finding 3 — State-Class Boilerplate Explosion

### Problem

Each state hierarchy (`SwapInState`, `SwapOutState`, `OnchainOperationState`)
contains 10–13 `final class` variants. Every data-bearing variant repeats
nearly identical `toJson()` boilerplate:

```dart
final class SwapInRequestCreated extends SwapInState {
  @override final SwapInData data;
  const SwapInRequestCreated(this.data);
  @override String get stateName => 'requestCreated';
  @override Map<String, dynamic> toJson() => {
    'state': 'requestCreated',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

// × 12 variants for SwapIn
// × 12 variants for SwapOut
// × 7 variants for Onchain
// ≈ 250 lines of pure boilerplate
```

### Ideal (clean)

Add a **shared base mixin or intermediate class** for data-bearing states:

```dart
/// Mixin for any state that carries recovery data and uses standard
/// JSON envelope { state, id, isTerminal, updatedAt, ...data }.
mixin DataBearingState<D> on MachineState {
  D get data;
  String get dataId;
  Map<String, dynamic> dataToJson();

  @override
  Map<String, dynamic> toJson() => {
    'state': stateName,
    'id': dataId,
    'isTerminal': isTerminal,
    'updatedAt': DateTime.now().toIso8601String(),
    ...dataToJson(),
  };
}

// Now each variant is ONE LINE of real logic:
final class SwapInRequestCreated extends SwapInState with DataBearingState<SwapInData> {
  @override final SwapInData data;
  const SwapInRequestCreated(this.data);
  @override String get stateName => 'requestCreated';
  @override String get dataId => data.boltzId;
  @override Map<String, dynamic> dataToJson() => data.toJson();
}
```

Better yet, **generate them**. Since each variant only differs by `stateName`
and `isTerminal`, a factory + enum is even leaner:

```dart
enum SwapInStateName {
  requestCreated(terminal: false),
  funded(terminal: false),
  claimed(terminal: false),
  completed(terminal: true),
  // ...
  ;
  final bool terminal;
  const SwapInStateName({required this.terminal});
}

// One generic state class replaces 10 boilerplate classes:
class SwapInDataState extends SwapInState with DataBearingState<SwapInData> {
  final SwapInStateName name;
  @override final SwapInData data;
  @override String get stateName => name.name;
  @override bool get isTerminal => name.terminal;
  // ... done
}
```

This eliminates **≈ 200 LOC** of copy-paste.

---

## 5. Finding 4 — SwapIn / SwapOut Structural Duplication

### Problem

`SwapInData` and `SwapOutData` share **>50 % identical structure**:
boltzId, chainId, accountIndex, creationBlockHeight, lastBoltzStatus,
errorMessage, tokenAddress, toJson, fromJson, copyWith.

The state hierarchies (`SwapInState`, `SwapOutState`) are nearly
isomorphic — both have: Initialised, RequestCreated, AwaitingOnChain,
Funded, Completed, Failed, plus busy-lock variants.

The operation classes (`SwapInOperation`, `SwapOutOperation`) both extend
`OperationMachine`, define nearly identical `steps`, `busyStateFor`,
`emitError`, and `telemetryAttributes`.

**Estimated structural duplication: 350+ LOC.**

### Ideal (clean)

Extract a shared `SwapData` base:

```dart
/// Fields shared by every Boltz swap (in or out).
abstract class BoltzSwapData {
  String get boltzId;
  int get chainId;
  int get accountIndex;
  int? get creationBlockHeight;
  String? get lastBoltzStatus;
  String? get errorMessage;
  String? get tokenAddress;
  Map<String, dynamic> baseToJson();
}

class SwapInData extends BoltzSwapData { ... } // only in-specific fields
class SwapOutData extends BoltzSwapData { ... } // only out-specific fields
```

For states, use the `DataBearingState` mixin from Finding 3 to eliminate
the duplicate `toJson()` scaffolding. The shared set of state names
(initialised, awaitingOnChain, funded, completed, failed) can live in a
common enum.

For operations, extract shared `OperationMachine` setup into a
`BoltzSwapMixin`:

```dart
mixin BoltzSwapMixin<S extends MachineState, E extends Enum>
    on OperationMachine<S, E> {
  Auth get auth;
  EvmChain get chain;

  @override Map<String, Object?> get telemetryAttributes => {
    ...super.telemetryAttributes,
    'hostr.swap.chain_id': chain.config.chainId,
    // ...
  };
}
```

---

## 6. Finding 5 — Three Escrow Directories with Confusing Naming

### Problem

```
usecase/
  escrow/           → EscrowUseCase (facade) + operations/ + supported_escrow_contract/
  escrows/          → Escrows extends CrudUseCase<EscrowService>  (Nostr CRUD)
  escrow_methods/   → EscrowMethods extends CrudUseCase<EscrowMethod> (Nostr CRUD)
```

A developer looking for "escrow logic" has to check three directories.
The naming collision (`escrow/` vs `escrows/`) is particularly confusing.
`Escrows` is a CRUD class for Nostr `kind:30300` events — it has nothing
to do with on-chain escrow operations.

### Ideal (clean)

```
usecase/
  escrow/
    escrow.dart                     → EscrowUseCase (facade)
    escrow_verification.dart
    operations/                     → claim/, fund/, release/, withdraw/
    contract/                       → multi_escrow.dart, registry, bytecodes, eip712
    nostr/                          → escrow_service_crud.dart, escrow_method_crud.dart
```

Rename classes:

- `Escrows` → `EscrowServiceCrud` or `EscrowServiceRepository`
- `EscrowMethods` → `EscrowMethodCrud` or `EscrowMethodRepository`

This is a **cognitive-load** fix — LOC savings are small, but the mental
model simplification is significant.

---

## 7. Finding 6 — `MultiEscrowWrapper` Does Too Much (500+ LOC)

### Problem

`MultiEscrowWrapper` handles:

1. **Contract method building** — `fund()`, `claim()`, `release()`, `arbitrate()`, `withdraw()`
2. **On-chain queries** — `getTrade()`, `canClaim()`, `canRelease()`, `pendingWithdrawal()`
3. **Event log scanning + caching** — `allEvents()`, `_liveEvents()`, `_mapEscrowEvent()`, `_recordTradeEvent()`, `_mergeEvents()`
4. **Custom error decoding** — `_decodeCustomError()`, `_withDecodedCustomError()`
5. **EIP-712 signer initialisation** — `_signer` getter

The event scanning + caching alone is **≈ 200 LOC** and is a completely
separate concern from contract-method building.

### Ideal (clean)

```dart
/// Pure ABI encoding — no RPC calls.
class MultiEscrowCallBuilder {
  Call fund(FundArgs args);
  Call claim({required String tradeId, required EthPrivateKey ethKey});
  Call release(ReleaseArgs args);
  Call withdraw(WithdrawArgs args);
  Call arbitrate({...});
}

/// Read-only queries.
class MultiEscrowReader {
  Future<OnChainTrade?> getTrade(String tradeId);
  Future<bool> canClaim({required String tradeId});
  Future<BigInt> pendingWithdrawal({...});
}

/// Event log scanning with caching.
class EscrowEventScanner {
  StreamWithStatus<EscrowEvent> allEvents(ContractEventsParams params, ...);
  // Contains _liveEvents, _mapEscrowEvent, _recordTradeEvent, _mergeEvents
}

/// Thin façade combining the above.
class MultiEscrowContract extends SupportedEscrowContract<MultiEscrow> {
  final MultiEscrowCallBuilder calls;
  final MultiEscrowReader reader;
  final EscrowEventScanner events;
  // Delegates everything
}
```

---

## 8. Finding 7 — `OnchainOperationData` Overengineered copyWith

### Problem

`OnchainOperationData` declares **six** abstract `copyWith*` methods for
individual fields:

```dart
abstract class OnchainOperationData {
  OnchainOperationData copyWithSwapId(String? swapId);
  OnchainOperationData copyWithTxHash(String? txHash);
  OnchainOperationData copyWithTransactionInformation(TransactionInformation?);
  OnchainOperationData copyWithTransactionReceipt(TransactionReceipt?);
  OnchainOperationData copyWithCalls(Map<String, Call> calls);
  OnchainOperationData copyWithTransport(String? transport);
}
```

`OnchainCallData` then implements all six by delegating to a single
`copyWith(...)`. The abstract base adds **≈ 60 lines** of ceremony
for no real polymorphic benefit.

### Ideal (clean)

Drop the abstract base entirely. Use a single concrete data class:

```dart
class OnchainCallData {
  // ... fields ...
  OnchainCallData copyWith({
    Map<String, Call>? calls,
    String? transport,
    String? swapId,
    String? txHash,
    TransactionInformation? transactionInformation,
    TransactionReceipt? transactionReceipt,
    String? errorMessage,
  }) => OnchainCallData(...);
}
```

If you ever need a second data variant, add it then — not before.

---

## 9. Finding 8 — SwapRegistry Copy-Paste

### Problem

`SwapRegistry` has nearly identical tracking code for swap-in and
swap-out operations:

```dart
// Swap-In tracking (≈ 80 LOC)
final BehaviorSubject<Map<String, SwapInOperation>> _swapIns$ = ...;
final Map<String, StreamSubscription> _swapInWatchers = {};
void registerSwapIn(SwapInOperation operation) { ... }
void _registerSwapInByKey(String key, SwapInOperation operation) { ... }
void _unregisterSwapIn(String boltzId) { ... }
Stream<SwapInOperation?> watchSwapInForParent(String parentOperationId) { ... }

// Swap-Out tracking (≈ 50 LOC) — structurally identical
final BehaviorSubject<Map<String, SwapOutOperation>> _swapOuts$ = ...;
final Map<String, StreamSubscription> _swapOutWatchers = {};
void registerSwapOut(SwapOutOperation operation) { ... }
void _unregisterSwapOut(String boltzId) { ... }
```

### Ideal (clean)

Extract a generic `OperationTracker<T>`:

```dart
class OperationTracker<T extends Cubit> {
  final BehaviorSubject<Map<String, T>> _ops$ = BehaviorSubject.seeded({});
  final Map<String, StreamSubscription> _watchers = {};

  void register(String key, T operation, {bool Function(dynamic)? isTerminal});
  void unregister(String key);
  T? findByPredicate(bool Function(T) predicate);
  Stream<T?> watchByPredicate(bool Function(T) predicate);
  void dispose();
}

@singleton
class SwapRegistry {
  late final OperationTracker<SwapInOperation> swapIns;
  late final OperationTracker<SwapOutOperation> swapOuts;
  // registerSwapIn becomes swapIns.register(...)
  // Done — 130 LOC → 50 LOC
}
```

---

## 10. Finding 9 — Scattered Token-Amount Conversions

### Problem

Token ↔ denomination conversion helpers are spread across **four
locations** with overlapping responsibility:

| Function                           | Location                  | Purpose                         |
| ---------------------------------- | ------------------------- | ------------------------------- |
| `rbtcFromWei(BigInt)`              | `token_amount_ext.dart`   | wei → RBTC TokenAmount          |
| `rbtcFromSats(BigInt)`             | `token_amount_ext.dart`   | sats → RBTC TokenAmount         |
| `rbtcFromSatsInt(int)`             | `token_amount_ext.dart`   | int sats → RBTC TokenAmount     |
| `tokenAmountFromEvm(...)`          | `token_amount_ext.dart`   | address+wei → TokenAmount       |
| `convertWeiToSatoshi(BigInt)`      | `evm_chain.dart` (bottom) | wei → `double` sats             |
| `convertWeiToBTC(BigInt)`          | `evm_chain.dart` (bottom) | wei → `double` BTC              |
| `_amountFromSats(Token, int)`      | `SwapOutQuoteService`     | int sats → TokenAmount          |
| `TokenAmount.fromDenominated(...)` | `token_amount.dart`       | DenominatedAmount → TokenAmount |

`convertWeiToSatoshi` and `convertWeiToBTC` return **`double`**, which
is a precision footgun for financial calculations. They are also
redundant with `TokenAmountEvmExt.inSats`.

### Ideal (clean)

Consolidate into `TokenAmount` and `TokenAmountEvmExt`:

```dart
// On TokenAmount itself (models package, EVM-agnostic):
extension TokenAmountConversions on TokenAmount {
  BigInt get inSats { ... }          // existing
  TokenAmount roundUpToSats();       // existing
  TokenAmount roundDownToSats();     // existing
}

// On the SDK side (EVM-aware):
extension TokenAmountEvmFactory on TokenAmount {
  static TokenAmount nativeFromWei(BigInt wei, {int chainId = 30}) => ...;
  static TokenAmount fromEvmAddress(String addr, BigInt val, {required int chainId}) => ...;
}

// DELETE: convertWeiToSatoshi, convertWeiToBTC, _amountFromSats
// DELETE: rbtcFromSatsInt (just use rbtcFromSats(BigInt.from(n)))
```

---

## 11. Finding 10 — Misplaced Free Functions in evm_chain.dart

### Problem

```dart
// At the very bottom of evm_chain.dart, outside the class:
double convertWeiToSatoshi(BigInt wei) {
  return wei.toDouble() / pow(10, 18 - 8);
}

double convertWeiToBTC(BigInt wei) {
  return wei.toDouble() / pow(10, 18);
}
```

These are:

1. **Misplaced** — they have nothing to do with `EvmChain`
2. **Redundant** — `TokenAmountEvmExt.inSats` does the same thing safely
3. **Precision-unsafe** — `BigInt.toDouble()` loses precision for large values

### Action

Delete them. Replace any call sites with `TokenAmount` methods.

---

## 12. Refactoring Roadmap

### Phase 1 — Quick Wins (≈ 400 LOC saved, 1–2 days)

| #   | Task                                                                                       | Files                                                                 | LOC saved |
| --- | ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- | --------- |
| 1.1 | Extract `_parseDecimalToBigInt` / `_formatDecimal` into `models/lib/src/decimal_math.dart` | `token_amount.dart`, `denominated_amount.dart`                        | 60        |
| 1.2 | Delete `convertWeiToSatoshi` / `convertWeiToBTC` from `evm_chain.dart`                     | `evm_chain.dart` + call sites                                         | 10        |
| 1.3 | Add `DataBearingState` mixin; collapse boilerplate state classes                           | `swap_in_state.dart`, `swap_out_state.dart`, `onchain_operation.dart` | 250       |
| 1.4 | Flatten `OnchainOperationData` → single `OnchainCallData` with one `copyWith`              | `onchain_operation.dart`                                              | 60        |

### Phase 2 — Structural Deduplication (≈ 430 LOC saved, 2–3 days)

| #   | Task                                                                                               | Files                                                     | LOC saved                  |
| --- | -------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | -------------------------- |
| 2.1 | Extract `BoltzSwapData` base from `SwapInData` / `SwapOutData`                                     | `swap_in_state.dart`, `swap_out_state.dart`               | 100                        |
| 2.2 | Extract generic `OperationTracker<T>` from `SwapRegistry`                                          | `swap_registry.dart`                                      | 80                         |
| 2.3 | Split `EvmChain` into `EvmRpcTransport`, `EvmLogsBatcher`, `EvmTokenRegistry`, `EvmAddressScanner` | `evm_chain.dart`                                          | 200 (net, after new files) |
| 2.4 | Consolidate token-amount factories                                                                 | `token_amount_ext.dart`, `evm_chain.dart`, quote services | 50                         |

### Phase 3 — Escrow Refactoring (≈ 200 LOC saved, 2 days)

| #   | Task                                                                                                | Files                      | LOC saved     |
| --- | --------------------------------------------------------------------------------------------------- | -------------------------- | ------------- |
| 3.1 | Merge `escrows/` and `escrow_methods/` into `escrow/nostr/`                                         | directory restructure      | 0 (cognitive) |
| 3.2 | Split `MultiEscrowWrapper` into `MultiEscrowCallBuilder`, `MultiEscrowReader`, `EscrowEventScanner` | `multi_escrow.dart`        | 150           |
| 3.3 | Simplify `EscrowVerification.verify()` into smaller private methods                                 | `escrow_verification.dart` | 50            |

### Phase 4 — Optional Deep Cleanup (≈ 200 LOC saved, 1–2 days)

| #   | Task                                                                                                    | Files                                                       | LOC saved |
| --- | ------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | --------- |
| 4.1 | Extract `BoltzSwapMixin` for shared `OperationMachine` setup                                            | `swap_in_operation.dart`, `swap_out_operation.dart`         | 80        |
| 4.2 | Unify swap quote pattern (shared `SwapQuote` base, common fee calculation)                              | `swap_in_quote_service.dart`, `swap_out_quote_service.dart` | 60        |
| 4.3 | Extract `EscrowMethods._buildAcceptedPaymentForms` into a standalone function                           | `escrows_methods.dart`                                      | 30        |
| 4.4 | Use `freezed` or codegen for `SwapInData` / `SwapOutData` to kill manual `toJson`/`fromJson`/`copyWith` | state files                                                 | 100+      |

---

## 13. LOC Reduction Estimate

| Phase                      | LOC saved   |
| -------------------------- | ----------- |
| Phase 1 — Quick Wins       | 380         |
| Phase 2 — Structural Dedup | 430         |
| Phase 3 — Escrow Refactor  | 200         |
| Phase 4 — Deep Cleanup     | 270         |
| **Total**                  | **≈ 1 280** |

Against ≈ 4 100 LOC currently in scope → **≈ 31 % reduction**.

---

## Appendix — What NOT to Change

The following are already **well-designed** and should be left alone:

- **`OperationMachine`** — Excellent CAS-based state machine with clear
  contracts, good documentation, and proper cross-isolate safety.
- **`AACapability`** — Clean encapsulation of ERC-4337 logic.
- **`BoltzSwapProvider`** — Clean wrapper around `BoltzClient`.
- **`BoltzCallBuilder`** — Good separation of ABI encoding from orchestration.
- **`EvmBalanceMonitor`** — Well-factored reactive balance tracker.
- **`Token` / `TokenAmount` / `DenominatedAmount` core API** — The type
  design is sound; only the duplicated parsing utils and scattered factory
  functions need cleanup.
- **`EscrowCapability`** — Thin, cache-aware, correctly invalidates on
  client rebuild.
- **`SwapFundingRequirement`** — Clear validation model with good error messages.
