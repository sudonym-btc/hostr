# TODO: EVM Auto-Withdrawal via Swap-Out

Status: **Implemented**

---

## Problem

When a user receives funds on-chain (e.g. escrow claim, refund), the RBTC sits
in their EVM wallet. Users shouldn't have to manually trigger a swap-out every
time — the app should drain EVM balances back to their Lightning wallet
automatically.

Two safety constraints make this non-trivial:

1. **Minimum amount threshold** — Boltz swap-out has fees (miner fee + service
   fee). Small balances would lose a disproportionate percentage to fees. Only
   auto-withdraw when `balance >= configurable minimum`.

2. **Escrow fund collision** — If the user is in the middle of (or about to
   start) an escrow fund operation, that operation needs the on-chain balance.
   Auto-withdrawing would drain the funds and cause the escrow deposit to fail.

---

## Architecture

### New components

```
usecase/evm/operations/auto_withdraw/
├── auto_withdraw_service.dart    # Core service — orchestrates the loop
├── auto_withdraw_config.dart     # Min threshold, polling interval, etc.
├── escrow_lock_registry.dart     # Tracks in-flight escrow operations
└── TODO_AUTO_WITHDRAW.md         # This file
```

### Interaction diagram

```
┌──────────────────┐
│  Balance stream   │  (Evm.subscribeBalance — fires on each new block)
└────────┬─────────┘
         │ balance changed
         ▼
┌──────────────────┐     ┌───────────────────────┐
│ AutoWithdraw      │────▶│  EscrowLockRegistry    │
│ Service           │     │  "any locks held?"     │
└────────┬─────────┘     └───────────────────────┘
         │ no locks && balance >= min
         ▼
┌──────────────────┐     ┌───────────────────────┐
│ SwapStore         │────▶│  Any active swap-outs? │
│ (existing)        │     │  "skip if already      │
└────────┬─────────┘     │   swapping"            │
         │ clear          └───────────────────────┘
         ▼
┌──────────────────┐
│ EvmChain          │
│ .swapOutAll()     │
└──────────────────┘
```

---

## 1. `EscrowLockRegistry` — preventing fund collisions ✅ IMPLEMENTED

A persistent registry that tracks escrow operations which are currently using
(or about to use) the on-chain balance. Persisted to disk via `KeyValueStorage`
so a background worker can read locks even when the foreground app is not active.

Follows the same persistence pattern as `SwapStore`: JSON list under a single
storage key, in-memory cache loaded lazily, flushed to disk after every mutation.

### Files

- `escrow_lock.dart` — `EscrowLock` model with `toJson()`/`fromJson()`
- `escrow_lock_registry.dart` — `@singleton` service with `acquire()`, `release()`,
  `hasActiveLocks`, `totalReservedAmount`, `hasActiveLocksStream`, `pruneOlderThan()`

### Integration

`EscrowFundOperation.execute()` now acquires a lock before starting and releases
it in the `finally` block — covering both the swap-in phase and the deposit.

### Persistence

Locks are **persisted to disk** via `KeyValueStorage` under the key
`escrow_locks`. On app restart, `initialize()` reloads any locks that were held
when the app was killed. Stale locks from crashes can be cleaned up with
`pruneOlderThan()`.

The `SwapRecoveryService` still handles recovering stale swaps independently.

---

## 2. `AutoWithdrawConfig` — user-configurable thresholds ✅ IMPLEMENTED

Auto-withdraw configuration is split between persisted user preferences
(`HostrUserConfig`) and service-level constants (`AutoWithdrawService`).

### Persisted in `HostrUserConfig` (user-facing)

- `autoWithdrawEnabled` (bool, default: `true`)
- `autoWithdrawMinimumSats` (int, default: `10000`)

### Constants on `AutoWithdrawService` (implementation details)

- `debounceDuration` — `Duration(seconds: 5)`
- `cooldownDuration` — `Duration(seconds: 300)`
- `maxFeeRatio` — `0.10`

Config is persisted via `UserConfigStore` (singleton, `KeyValueStorage`-backed)
and is accessible through `hostr.userConfig.state` / `hostr.userConfig.stream`.

The `AutoWithdrawService` reads user preferences from
`userConfig.state` and uses its own constants for operational parameters.

### Fee-awareness

Before triggering a swap, the service should call
`Rootstock.getMinimumSwapOut()` to get the current Boltz minimum, and
`SwapOutOperation.estimateFees()` to compute total fees. Only proceed if:

```
balance - totalFees - reservedAmount > 0
```

where `reservedAmount` is `EscrowLockRegistry.totalReservedAmount`. The user
should receive value, not just pay fees.

Consider a **fee ratio guard**: skip if `totalFees / balance > 10%` (or a
configurable percentage). This prevents edge cases where the balance is above
the minimum but fees eat most of it.

---

## 3. `AutoWithdrawService` — the orchestrator ✅ IMPLEMENTED

```dart
@Singleton()
class AutoWithdrawService {
  final Evm evm;
  final Auth auth;
  final SwapStore swapStore;
  final EscrowLockRegistry lockRegistry;
  final CustomLogger logger;

  StreamSubscription<BitcoinAmount>? _balanceSub;
  Timer? _cooldownTimer;
  bool _swapInProgress = false;

  /// Start listening for balance changes and auto-withdrawing.
  void start();

  /// Stop listening. Called on logout / dispose.
  void stop();

  /// Force an immediate check (e.g. after escrow claim completes).
  Future<void> checkNow();
}
```

### Core loop (pseudocode)

```dart
void start() {
  _balanceSub = evm.subscribeBalance()
    .debounceTime(config.debounce)
    .listen(_onBalanceChanged);
}

Future<void> _onBalanceChanged(BitcoinAmount balance) async {
  if (!config.enabled) return;
  if (_swapInProgress) return;
  if (_cooldownTimer?.isActive ?? false) return;

  // Gate 1: Any escrow operations in flight?
  if (lockRegistry.hasActiveLocks) {
    logger.d('Auto-withdraw skipped: escrow lock(s) held for '
        '${lockRegistry.activeTradeIds}');
    return;
  }

  // Gate 2: Any active (non-terminal) swaps already running?
  final activeSwaps = await swapStore.getActive();
  if (activeSwaps.isNotEmpty) {
    logger.d('Auto-withdraw skipped: ${activeSwaps.length} active swap(s)');
    return;
  }

  // Gate 3: Balance above minimum?
  if (balance.toSats() < config.minimumBalanceSats) {
    logger.d('Auto-withdraw skipped: balance ${balance.toSats()} sats '
        'below minimum ${config.minimumBalanceSats}');
    return;
  }

  // Gate 4: Fee ratio acceptable?
  final chain = evm.supportedEvmChains.first; // or iterate all
  final fees = await chain.swapOutAll().estimateFees();
  final netAmount = balance - fees.totalFees;
  if (netAmount <= BitcoinAmount.zero()) {
    logger.d('Auto-withdraw skipped: fees exceed balance');
    return;
  }
  final feeRatio = fees.totalFees.toSats() / balance.toSats();
  if (feeRatio > 0.10) {
    logger.d('Auto-withdraw skipped: fee ratio ${(feeRatio * 100).toStringAsFixed(1)}% too high');
    return;
  }

  // All gates passed — execute swap-out
  _swapInProgress = true;
  try {
    logger.i('Auto-withdraw: initiating swap-out of ${balance.toSats()} sats');
    final swapOp = chain.swapOutAll();
    await swapOp.execute();
    logger.i('Auto-withdraw: swap-out completed');
  } catch (e) {
    logger.e('Auto-withdraw: swap-out failed: $e');
  } finally {
    _swapInProgress = false;
    _cooldownTimer = Timer(config.cooldown, () {});
  }
}
```

### Per-chain withdrawal

Since `Evm.supportedEvmChains` is a list, the service should iterate each chain
independently. A chain with zero balance is skipped. Each chain's
`swapOutAll()` already handles draining the full balance for that chain.

---

## 4. Integration into app lifecycle ✅ IMPLEMENTED

### Startup (`setup.dart` / `Hostr`)

```dart
// After auth is ready, evm is initialised, and swap recovery has run:
if (auth.activeKeyPair != null) {
  getIt<AutoWithdrawService>().start();
}
```

### Auth changes

On login/logout/key-switch, stop and restart:

```dart
auth.activeKeyPairStream.listen((_) {
  getIt<AutoWithdrawService>().stop();
  if (auth.activeKeyPair != null) {
    getIt<AutoWithdrawService>().start();
  }
});
```

### After escrow claim

When `EscrowClaimOperation` completes, the user's on-chain balance increases.
Trigger an immediate check:

```dart
// In claim operation, after successful claim:
getIt<AutoWithdrawService>().checkNow();
```

---

## 5. Files to create

| File                                                                  | Purpose                                 |
| --------------------------------------------------------------------- | --------------------------------------- |
| ~~`usecase/evm/operations/auto_withdraw/auto_withdraw_service.dart`~~ | ✅ Main orchestrator singleton (done)   |
| ~~`usecase/evm/operations/auto_withdraw/auto_withdraw_config.dart`~~  | ✅ Merged into `HostrUserConfig` (done) |
| ~~`usecase/evm/operations/auto_withdraw/escrow_lock_registry.dart`~~  | ✅ Escrow operation lock tracker (done) |
| ~~`usecase/evm/operations/auto_withdraw/escrow_lock.dart`~~           | ✅ Lock model (done)                    |

## 6. Files to modify

| File                                                            | Change                                                                             |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| ~~`usecase/escrow/operations/fund/escrow_fund_operation.dart`~~ | ✅ Acquire/release `EscrowLockRegistry` lock around `execute()` (done)             |
| `usecase/escrow/operations/claim/escrow_claim_operation.dart`   | Call `AutoWithdrawService.checkNow()` after successful claim                       |
| ~~`usecase/evm/main.dart`~~                                     | ✅ Export new auto_withdraw files (done)                                           |
| `usecase/evm/evm.dart`                                          | Optionally expose `startAutoWithdraw()` / `stopAutoWithdraw()` convenience methods |
| `injection.dart` / `injection.config.dart`                      | Register new singletons (auto via `@Singleton()` + build_runner)                   |
| App `setup.dart`                                                | Wire `AutoWithdrawService.start()` into app lifecycle                              |

---

## 7. Edge cases & risks

| Scenario                                                              | Mitigation                                                                                                                                                                                                                  |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| User starts escrow fund while auto-withdraw is mid-swap               | `EscrowFundOperation._doesEscrowRequireSwap()` already checks balance. If auto-withdraw drained it, the escrow fund will trigger a swap-in to top up. But this wastes fees. **→ The lock registry prevents this entirely.** |
| App crashes mid-auto-withdraw swap                                    | `SwapRecoveryService` already handles this on restart. The `SwapRecord` is persisted at every checkpoint.                                                                                                                   |
| Multiple chains have balance simultaneously                           | Iterate chains sequentially, not in parallel, to avoid NWC invoice conflicts (swap-out needs a Lightning invoice).                                                                                                          |
| Boltz is down or rate-limited                                         | `swapOutAll().execute()` will throw. The cooldown timer prevents retry storms. Log the error and wait.                                                                                                                      |
| Balance fluctuates during swap (new block while swapping)             | `_swapInProgress` flag + debounce prevents re-entry. `swapOutAll()` already reads balance at execution time.                                                                                                                |
| User disables auto-withdraw mid-swap                                  | The in-flight swap completes (can't cancel an HTLC). The `enabled` flag is checked before starting new swaps, not during.                                                                                                   |
| Gas fees spike making swap-out uneconomical                           | The fee ratio guard (Gate 4) catches this.                                                                                                                                                                                  |
| Escrow fund needs a swap-in that overshoots, leaving leftover balance | Auto-withdraw will pick this up on the next block and drain it. This is actually a feature — it cleans up dust.                                                                                                             |

---

## 8. Testing plan

1. **Unit test `EscrowLockRegistry`** — acquire, release, concurrent locks,
   idempotent release, stream emissions.
2. **Unit test `AutoWithdrawService`** — mock `Evm`, `SwapStore`,
   `EscrowLockRegistry`. Verify each gate independently:
   - Skips when disabled
   - Skips when lock held
   - Skips when active swap exists
   - Skips when below minimum
   - Skips when fee ratio too high
   - Proceeds and calls `swapOutAll()` when all gates pass
3. **Integration test** — with mock `EvmChain`, simulate balance appearing
   after escrow claim → verify swap-out is triggered after debounce.
4. **Race condition test** — start escrow fund and auto-withdraw
   simultaneously, verify lock prevents collision.
