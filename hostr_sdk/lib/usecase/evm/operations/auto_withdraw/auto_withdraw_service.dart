import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../util/bitcoin_amount.dart';
import '../../../../util/custom_logger.dart';
import '../../../user_config/user_config_store.dart';
import '../../evm.dart';
import '../swap_out/swap_out_state.dart';
import '../swap_store.dart';
import 'escrow_lock_registry.dart';

/// Watches the EVM balance across all supported chains and automatically
/// triggers a swap-out to Lightning when conditions are met.
///
/// ### Gates (all must pass before a swap-out is initiated)
///
/// 1. **Enabled** — `HostrUserConfig.autoWithdrawEnabled` is `true`.
/// 2. **No escrow locks** — [EscrowLockRegistry] has no active locks.
/// 3. **No active swaps** — [SwapStore] has no non-terminal swap records.
/// 4. **Minimum balance** — balance ≥ `autoWithdrawMinimumSats`.
/// 5. **Fee ratio** — estimated fees / balance ≤ [maxFeeRatio].
///
/// The service debounces balance changes ([debounceDuration]) and enters a
/// cooldown after every attempt (success or failure) ([cooldownDuration]).
@singleton
class AutoWithdrawService {
  /// How long to wait after a balance change before checking gates.
  static const debounceDuration = Duration(seconds: 5);

  /// How long to wait after a swap-out attempt before trying again.
  static const cooldownDuration = Duration(seconds: 300);

  /// Maximum fee-to-balance ratio tolerated for an auto-withdrawal.
  static const double maxFeeRatio = 0.10;
  final Evm _evm;
  final SwapStore _swapStore;
  final EscrowLockRegistry _lockRegistry;
  final UserConfigStore _userConfigStore;
  final CustomLogger _logger;

  StreamSubscription<BitcoinAmount>? _balanceSub;
  Timer? _cooldownTimer;
  bool _swapInProgress = false;

  AutoWithdrawService(
    this._evm,
    this._swapStore,
    this._lockRegistry,
    this._userConfigStore,
    this._logger,
  );

  // ── Public API ──────────────────────────────────────────────────────────

  /// Start listening for balance changes and auto-withdrawing.
  ///
  /// Idempotent — calling [start] while already running is a no-op.
  void start() {
    if (_balanceSub != null) return;

    _balanceSub = _evm
        .subscribeBalance()
        .debounceTime(debounceDuration)
        .listen(
          _onBalanceChanged,
          onError: (e) => _logger.w('AutoWithdraw balance stream error: $e'),
          onDone: () {
            _logger.w(
              'AutoWithdraw: balance stream completed unexpectedly, '
              'subscription lost',
            );
            _balanceSub = null;
          },
        );

    _logger.i('AutoWithdrawService started');
  }

  /// Stop listening. Safe to call even if not started.
  void stop() {
    _balanceSub?.cancel();
    _balanceSub = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _swapInProgress = false;
    _logger.i('AutoWithdrawService stopped');
  }

  /// Force an immediate check (e.g. after an escrow claim completes).
  ///
  /// Skips the debounce but still respects all gates.
  Future<void> checkNow() async {
    final balance = await _evm.getBalance();
    await _onBalanceChanged(balance);
  }

  // ── Internal ────────────────────────────────────────────────────────────

  Future<void> _onBalanceChanged(BitcoinAmount balance) async {
    final config = await _userConfigStore.state;

    // Gate 1: Enabled?
    if (!config.autoWithdrawEnabled) return;

    // Guard: already swapping?
    if (_swapInProgress) return;

    // Guard: in cooldown?
    if (_cooldownTimer?.isActive ?? false) {
      _logger.d('AutoWithdraw skipped: cooldown active');
      return;
    }

    // Gate 2: Any escrow operations in flight?
    if (await _lockRegistry.hasActiveLocks) {
      final ids = await _lockRegistry.activeTradeIds;
      _logger.d('AutoWithdraw skipped: escrow lock(s) held for $ids');
      return;
    }

    // Gate 3: Any active (non-terminal) swaps already running?
    final activeSwaps = await _swapStore.getActive();
    if (activeSwaps.isNotEmpty) {
      _logger.d('AutoWithdraw skipped: ${activeSwaps.length} active swap(s)');
      return;
    }

    // Gate 4: Balance above minimum?
    final minimumBalance = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      config.autoWithdrawMinimumSats,
    );
    if (balance < minimumBalance) {
      _logger.d(
        'AutoWithdraw skipped: balance ${balance.getInSats} sats '
        'below minimum ${config.autoWithdrawMinimumSats}',
      );
      return;
    }

    // Iterate each chain independently (sequential to avoid NWC invoice conflicts)
    for (final chain in _evm.supportedEvmChains) {
      if (_swapInProgress) break;

      try {
        // Gate 5: Fee ratio acceptable?
        final swapOp = chain.swapOutAll();
        final fees = await swapOp.estimateFees();
        final netAmount = fees.balance - fees.totalFees;

        if (netAmount <= BitcoinAmount.zero()) {
          _logger.d(
            'AutoWithdraw skipped on ${chain.runtimeType}: '
            'fees exceed balance',
          );
          continue;
        }

        final feeRatio = fees.totalFees.getInSats == BigInt.zero
            ? 0.0
            : fees.totalFees.getInSats.toDouble() /
                  fees.balance.getInSats.toDouble();

        if (feeRatio > maxFeeRatio) {
          _logger.d(
            'AutoWithdraw skipped on ${chain.runtimeType}: fee ratio '
            '${(feeRatio * 100).toStringAsFixed(1)}% exceeds max '
            '${(maxFeeRatio * 100).toStringAsFixed(1)}%',
          );
          continue;
        }

        // All gates passed — execute swap-out
        _swapInProgress = true;
        _logger.i(
          'AutoWithdraw: initiating swap-out of '
          '${fees.balance.getInSats} sats on ${chain.runtimeType}',
        );

        final op = chain.swapOutAll();
        await op.execute();

        if (op.state is SwapOutCompleted) {
          _logger.i('AutoWithdraw: swap-out completed on ${chain.runtimeType}');
        } else if (op.state is SwapOutFailed) {
          final failed = op.state as SwapOutFailed;
          _logger.e(
            'AutoWithdraw: swap-out failed on ${chain.runtimeType}: '
            '${failed.error}',
          );
        }
      } catch (e) {
        _logger.e('AutoWithdraw: swap-out failed on ${chain.runtimeType}: $e');
      } finally {
        _swapInProgress = false;
        _cooldownTimer = Timer(cooldownDuration, () {});
      }
    }
  }
}
