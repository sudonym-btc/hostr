# Balance Monitoring & Auto-Withdrawal Rework

## Current State — Problems

### 1. Blind HD address polling

`EvmChain.getAddressesWithBalance()` and `getAddressesWithTokenBalances()` scan
all 20 HD-derived addresses on every single block tick, regardless of whether
those addresses have ever received funds. On a 1-second chain like Arbitrum this
is 20 `eth_getBalance` calls per second per chain, most returning zero.

`EvmChain.subscribeTotalBalance()` → calls `getTotalBalance()` → calls
`getAddressesWithBalance()` every block. `Evm._ensureBalanceSubscription()`
aggregates one of these per chain and feeds `Evm.subscribeBalance()`.

`EvmBalanceMonitor` already exists and solves this problem (dirty-address
detection, ERC-20 Transfer log scanning, expansion debouncing) but is
**never instantiated**.

### 2. Total balance includes locked escrow funds

The balance displayed in `MoneyInFlightWidget` can include amounts still sitting
inside escrow contracts awaiting `withdraw()`. Those funds are not spendable
until `WithdrawalOrchestrator` settles them. This inflates the displayed balance
and triggers spurious auto-withdraw attempts.

### 3. Two overlapping services with separate lifecycles

`AutoWithdrawService` watches `Evm.subscribeBalance()` (aggregate total).
`WithdrawalOrchestrator` watches escrow settlement events.
Both ultimately want to sweep funds to Lightning — they share no state, no
coordination, and their ordering is undefined (auto-withdraw may fire before the
orchestrator has executed the on-chain `withdraw()`).

### 4. Escrow event consumers must re-resolve chain + contract

`WithdrawalOrchestrator._tryWithdraw()` calls `_evm.getChainForEscrowService()`
and `configuredChain.escrow.getSupportedEscrowContract()` for every event.
`MultiEscrowWrapper` already holds an `EvmChain` reference and emits these
events, so the chain and contract are available at emit time.

---

## Goals

1. Only track EVM addresses we have reason to believe hold funds.
2. Total-balance stream reflects **spendable** funds only (not escrow-locked).
3. Single service handles both escrow withdrawal and Lightning swap-out,
   in the correct order, with proper coordination.
4. Escrow events carry `EvmChain` and `SupportedEscrowContract` directly.

---

## Proposed Architecture

### Step 1 — Enrich escrow events with chain + contract

Add two fields to `EscrowEvent` (sealed base class):

```dart
sealed class EscrowEvent extends PaymentEvent {
  final EscrowServiceSelected? escrowService;
  final BlockInformation block;
  final EvmChain? chain;                          // NEW
  final SupportedEscrowContract? contract;        // NEW
  ...
}
```

`MultiEscrowWrapper` already holds `final EvmChain? chain` and creates the
contract instance — populate both fields when constructing
`EscrowReleasedEvent`, `EscrowClaimedEvent`, and `EscrowArbitratedEvent`
inside `_mapEscrowEvent()`.

This eliminates the resolution dance in every listener. The fields are nullable
so non-EVM escrow types are unaffected.

---

### Step 2 — Wire `EvmBalanceMonitor` into `EvmChain`

`EvmChain` gets ownership of a single `EvmBalanceMonitor`:

```dart
class EvmChain {
  late final EvmBalanceMonitor balanceMonitor;  // NEW

  // constructor:
  balanceMonitor = EvmBalanceMonitor(chain: this, logger: logger);
}
```

`EvmChain.dispose()` calls `balanceMonitor.dispose()`.

Remove from `EvmChain`:

- `subscribeTotalBalance()` — replaced by monitor
- `getTotalBalance()` — replaced by monitor
- `getAddressesWithBalance()` — kept only for initial seeding (see Step 3)
- `getAddressesWithTokenBalances()` — kept only for initial seeding
- `subscribeBalance(EthereumAddress)` — callers should use monitor directly

`getBalance(EthereumAddress)` and `getERC20Balance()` remain — they are used
internally by the monitor and by quote services.

---

### Step 3 — Smart address seeding strategy

The monitor starts with an empty tracked set. Addresses are added at the
following moments:

| Trigger                                                                             | Action                                                                                                                                                       |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Evm.init()` completes                                                              | One-time `getAddressesWithBalance()` scan → `monitor.trackAddress()` for each funded address. Also `trackToken()` for each Boltz ERC-20 token on that chain. |
| `EvmSwapInOperation` reaches `SwapInCompleted`                                      | `chain.balanceMonitor.trackAddress(params.evmKey.address)`                                                                                                   |
| `WithdrawalOrchestrator` / `FundsMonitorService` executes `withdraw()` successfully | `chain.balanceMonitor.trackAddress(destination)`                                                                                                             |
| `BalanceUpdate` fires with `balance.value == BigInt.zero` for a tracked address     | `monitor.untrackAddress(address)` — evict the entry (optional, low priority)                                                                                 |

The initial scan is a one-time cost at startup and touches at most
`_maxScanIndex = 20` addresses. After that, only addresses with known activity
are polled.

---

### Step 4 — `FundsItem` — unified sweepable funds record

Introduce a single value type that represents one sweepable balance slot,
regardless of whether the funds sit in a plain EOA/smart-wallet or inside an
escrow contract awaiting `withdraw()`:

```dart
/// One sweepable balance entry — EOA/smart-wallet or escrow-locked.
class FundsItem {
  /// The EVM address that holds the funds (EOA or smart-wallet).
  final EthereumAddress address;

  /// The HD key pair that controls `address`.
  /// Always present — the swap-out operation signs with this key.
  final EthHdKey keypair;

  final Token token;
  final TokenAmount balance;
  final EvmChain chain;
  final int blockNumber;

  /// Non-null only for escrow-locked funds.
  /// When set, the swap-out operation must call
  /// `contract.withdraw(keypair)` as a pre-lockup call.
  final SupportedEscrowContract? contract;

  /// Present when `contract` is non-null.
  final String? tradeId;
}
```

`FundsMonitorService` (Step 5) owns and emits this type. `Evm` itself no longer
need a `subscribeBalance()` method — the UI and the swap-out path both consume
`FundsMonitorService.fundsStream$` directly.

For the display layer, `Evm` (or a thin helper on `FundsMonitorService`) provides
a derived stream that collapses the list to per-token totals:

```dart
/// Display-only: sum of all FundsItems grouped by token.
Stream<List<TokenAmount>> get displayBalance$ =>
    fundsStream$
        .map((items) => _groupByToken(items))
        .distinct();

List<TokenAmount> _groupByToken(List<FundsItem> items) {
  final map = <Token, TokenAmount>{};
  for (final item in items) {
    map.update(
      item.token,
      (existing) => existing + item.balance,
      ifAbsent: () => item.balance,
    );
  }
  return map.values.toList();
}
```

`MoneyInFlightWidget` subscribes to `displayBalance$` and renders one row per
`TokenAmount` entry, replacing the current single-value display.

---

### Step 5 — `FundsMonitorService` — unified observable + swap-out

Delete `AutoWithdrawService` and `WithdrawalOrchestrator`. Replace with a single
`@singleton` `FundsMonitorService`.

#### Two source streams → one `fundsStream$`

```
Source A — EvmBalanceMonitor.balanceUpdates (EOA / smart-wallet)
  Every BalanceUpdate → resolve keypair for address → emit FundsItem(contract: null)

Source B — EscrowSettlementEvent (Released / Claimed / Arbitrated)
  On each event → pendingWithdrawal() > 0 → emit FundsItem(contract: event.contract)

fundsStream$ = Rx.combineLatest([sourceA$, sourceB$])
  → List<FundsItem>  (one entry per address+token+contract slot)
```

Both sources carry a `keypair` on every item. Source B items carry the
`contract` that will execute `withdraw()` atomically inside the swap-out
operation itself — no separate on-chain step is needed first.

#### Swap-out path

Because every `FundsItem` already has a `keypair` and an optional `contract`,
the sweep logic collapses to a single pass:

```dart
fundsStream$
    .debounceTime(kSwapOutDebounce)
    .listen((items) async {
  for (final item in items) {
    if (!_passesGates(item)) continue;

    final params = SwapOutParams(
      amount:   item.balance,
      chain:    item.chain,
      ethKey:   item.keypair,
      // When funds are escrow-locked, withdraw() runs atomically
      // as a pre-lockup call inside the same swap-out tx batch.
      preLockupCalls: item.contract != null
          ? [item.contract!.withdraw(WithdrawArgs(
              tradeId:     item.tradeId!,
              ethKey:      item.keypair,
              beneficiary: item.keypair.address,
            ))]
          : [],
    );

    await SwapOutOperation(params: params).execute();
  }
});
```

There is no longer a two-phase "withdraw first, then swap" sequence — the
`withdraw()` is bundled into the swap-out operation's tx batch, eliminating the
race condition entirely.

#### Class sketch

```dart
@singleton
class FundsMonitorService {
  // ── Dependencies ──────────────────────────────────────────────────
  final Evm _evm;
  final UserSubscriptions _userSubs;
  final Auth _auth;
  final TradeAccountAllocator _tradeAccountAllocator;
  final UserConfigStore _userConfigStore;
  final HostrConfig _hostrConfig;
  final CustomLogger _logger;

  // ── Observable ────────────────────────────────────────────────────

  /// All currently sweepable funds across all chains.
  /// Items with contract != null are escrow-locked and require
  /// preLockupCalls in the corresponding swap-out operation.
  late final Stream<List<FundsItem>> fundsStream$;

  /// Display-only: per-token totals derived from fundsStream$.
  late final Stream<List<TokenAmount>> displayBalance$;

  // ── State ─────────────────────────────────────────────────────────
  /// Map of tradeId → FundsItem for currently-known escrow balances.
  final Map<String, FundsItem> _escrowItems = {};
  final BehaviorSubject<List<FundsItem>> _escrowSubject = BehaviorSubject.seeded([]);

  StreamSubscription? _eventSub;
  StreamSubscription? _sweepSub;

  // ── Lifecycle ─────────────────────────────────────────────────────

  void start() {
    _seedMonitors();
    _buildFundsStream();
    _startSweepListener();
  }

  void _buildFundsStream() {
    // Source A: EOA/smart-wallet balances from monitor.
    final eoa$ = Rx.merge(
      _evm.configuredChains.map((c) => c.balanceMonitor.balanceUpdates),
    ).asyncMap((update) async {
      final keypair = await _resolveKeypair(update.address);
      if (keypair == null) return null;
      return FundsItem(
        address:  update.address,
        keypair:  keypair,
        token:    update.token,
        balance:  update.balance,
        chain:    update.chain,
        blockNumber: update.blockNumber,
        contract: null,
      );
    }).whereNotNull();

    // Source B: escrow-locked balances from settlement events.
    _eventSub = _userSubs.paymentEvents$.replayStream
        .whereType<EscrowEvent>()
        .where((e) => e is EscrowReleasedEvent ||
                      e is EscrowClaimedEvent ||
                      e is EscrowArbitratedEvent)
        .listen(_onSettlementEvent);

    // Combine: latest EOA snapshot + latest escrow snapshot.
    fundsStream$ = Rx.combineLatest2(
      eoa$.scan<List<FundsItem>>(_mergeEoaUpdate, []),
      _escrowSubject.stream,
      (eoaItems, escrowItems) => [...eoaItems, ...escrowItems],
    );

    displayBalance$ = fundsStream$
        .map(_groupByToken)
        .distinct();
  }

  // ── Settlement → escrow FundsItem ────────────────────────────────

  Future<void> _onSettlementEvent(EscrowEvent event) async {
    final chain    = event.chain;
    final contract = event.contract;
    if (chain == null || contract == null) return;
    if (_escrowItems.containsKey(event.tradeId)) return;

    final accountIndex = await _tradeAccountAllocator
        .tryFindTradeAccountIndexByTradeId(event.tradeId) ?? 0;
    final keypair  = await _auth.hd.getActiveEvmKey(accountIndex: accountIndex);
    final pending  = await contract.pendingWithdrawal(
      tradeId:     event.tradeId,
      beneficiary: keypair.address,
    );
    if (pending == BigInt.zero) return;

    final item = FundsItem(
      address:     keypair.address,
      keypair:     keypair,
      token:       Token.native(chain.config.chainId), // or ERC-20 as applicable
      balance:     TokenAmount.fromWei(pending, chain.config.nativeToken),
      chain:       chain,
      blockNumber: event.block.number,
      contract:    contract,
      tradeId:     event.tradeId,
    );

    _escrowItems[event.tradeId] = item;
    _escrowSubject.add(_escrowItems.values.toList());
  }

  // ── Sweep listener ────────────────────────────────────────────────

  void _startSweepListener() {
    _sweepSub = fundsStream$
        .debounceTime(kSwapOutDebounce)
        .listen((items) async {
      for (final item in items) {
        if (!_passesGates(item)) continue;

        final params = SwapOutParams(
          amount:  item.balance,
          chain:   item.chain,
          ethKey:  item.keypair,
          preLockupCalls: item.contract != null
              ? [item.contract!.withdraw(WithdrawArgs(
                  tradeId:     item.tradeId!,
                  ethKey:      item.keypair,
                  beneficiary: item.keypair.address,
                ))]
              : [],
        );

        await SwapOutOperation(params: params).execute();

        // Evict escrow item after successful swap-out.
        if (item.tradeId != null) {
          _escrowItems.remove(item.tradeId);
          _escrowSubject.add(_escrowItems.values.toList());
        }
      }
    });
  }

  bool _passesGates(FundsItem item) {
    // Gate 1: service enabled?
    // Gate 2: no active swaps for this address?
    // Gate 3: balance >= minimum threshold?
    // Gate 4: estimated fee / balance ratio <= max ratio?
    return true; // detailed logic carries over from AutoWithdrawService
  }
}
```

#### Why the previous two-phase sequencing is no longer needed

Previously the plan required: (1) execute `withdraw()` on-chain, wait for
confirmation, (2) track the destination address, wait for a `BalanceUpdate`,
(3) then trigger swap-out. This created a race window.

Now, `FundsItem` for an escrow slot is emitted as soon as `pendingWithdrawal()`
returns non-zero — _before_ any on-chain tx is sent. The swap-out operation
bundles the `withdraw()` call into its own pre-lockup tx batch. The EVM chain
executes `withdraw() → transfer-to-lockup` atomically within the same
operation, so there is no window for the balance to land somewhere else first.

---

## Files Affected

| File                                                                          | Change                                                                                                                                                                              |
| ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart`     | Add `chain` + `contract` fields to `EscrowEvent`                                                                                                                                    |
| `usecase/escrow/supported_escrow_contract/multi_escrow.dart`                  | Populate new fields in `_mapEscrowEvent()`                                                                                                                                          |
| `usecase/evm/chain/evm_chain.dart`                                            | Add `late final EvmBalanceMonitor balanceMonitor`; remove `subscribeTotalBalance`, `getTotalBalance`, `subscribeBalance(address)`                                                   |
| `usecase/evm/evm.dart`                                                        | Remove `_ensureBalanceSubscription`, `subscribeBalance()`, `getBalance()`, `resetBalance()`; wire monitor `start()` in `init()`; expose `configuredChains` to `FundsMonitorService` |
| `usecase/evm/operations/auto_withdraw/auto_withdraw_service.dart`             | **Delete**                                                                                                                                                                          |
| `usecase/trades/withdrawal_orchestrator.dart`                                 | **Delete**                                                                                                                                                                          |
| `usecase/evm/operations/funds_monitor/funds_item.dart`                        | **New** — `FundsItem` value type                                                                                                                                                    |
| `usecase/evm/operations/funds_monitor/funds_monitor_service.dart`             | **New** — `FundsMonitorService`                                                                                                                                                     |
| `app/lib/presentation/component/widgets/money_in_flight/money_in_flight.dart` | Subscribe to `FundsMonitorService.displayBalance$` (`Stream<List<TokenAmount>>`); render one row per entry                                                                          |
| `hostr.dart`                                                                  | Replace `AutoWithdrawService` + `WithdrawalOrchestrator` start/stop/reset with `FundsMonitorService`                                                                                |
| Build runner                                                                  | Re-run after injectable changes                                                                                                                                                     |

## Out of Scope / Deferred

- Untracking zero-balance addresses after a successful swap-out (low priority;
  the monitor handles stale entries gracefully).
- ERC-20 escrow items in `FundsItem.token` — first pass uses native token only;
  ERC-20 `pendingWithdrawal` support can be added later.
- `SwapOutQuoteService` gate-check logic inside `_passesGates()` — carries over
  verbatim from the current `AutoWithdrawService`.
- `scanAll()` startup catch-up for missed settlement events — the replay stream
  on `paymentEvents$` provides this for free; an explicit scan is not needed.
