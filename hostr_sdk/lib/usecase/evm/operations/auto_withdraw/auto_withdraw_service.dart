import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../config.dart';
import '../../../../injection.dart';
import '../../../../util/custom_logger.dart';
import '../../../../util/token_amount_ext.dart';
import '../../../auth/auth.dart';
import '../../../nwc/nwc.dart';
import '../../../payments/payments.dart';
import '../../../user_config/user_config_store.dart';
import '../../evm.dart';
import '../operation_state_store.dart';
import '../swap_out/swap_out_models.dart';
import '../swap_out/swap_out_quote_service.dart';
import '../swap_out/swap_out_state.dart';

/// Watches the EVM balance across all supported chains and automatically
/// triggers a swap-out to Lightning when conditions are met.
///
/// ### Gates (all must pass before a swap-out is initiated)
///
/// 1. **Enabled** — `HostrUserConfig.autoWithdrawEnabled` is `true`.
/// 2. **No escrow locks** — [OperationStateStore] has no non-terminal escrow fund states.
/// 3. **No active swaps** — [OperationStateStore] has no non-terminal swap states.
/// 4. **Minimum balance (per address)** — each individual chain address's
///    balance ≥ [HostrConfig.autoWithdrawMinimumSats] (checked via
///    `getAddressesWithBalance`).
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
  final OperationStateStore _stateStore;
  final UserConfigStore _userConfigStore;
  final HostrConfig _hostrConfig;
  final CustomLogger _logger;

  StreamSubscription<TokenAmount>? _balanceSub;
  Timer? _cooldownTimer;
  bool _swapInProgress = false;

  AutoWithdrawService(
    this._evm,
    this._stateStore,
    this._userConfigStore,
    this._hostrConfig,
    CustomLogger logger,
  ) : _logger = logger.scope('auto-withdraw');

  // ── Public API ──────────────────────────────────────────────────────────

  /// Start listening for balance changes and auto-withdrawing.
  ///
  /// Idempotent — calling [start] while already running is a no-op.
  void start() => _logger.spanSync('start', () {
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
  });

  /// Stop listening. Safe to call even if not started.
  Future<void> stop() => _logger.span('stop', () async {
    await _balanceSub?.cancel();
    _balanceSub = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _swapInProgress = false;
    _logger.d('AutoWithdrawService stopped');
  });

  /// Force an immediate check (e.g. after an escrow claim completes).
  ///
  /// Skips the debounce but still respects all gates.
  Future<void> checkNow() => _logger.span('checkNow', () async {
    final balance = await _evm.getBalance();
    await _onBalanceChanged(balance);
  });

  // ── Internal ────────────────────────────────────────────────────────────

  Future<void> _onBalanceChanged(
    TokenAmount balance,
  ) => _logger.span('_onBalanceChanged', () async {
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
    if (await _stateStore.hasNonTerminal('escrow_fund')) {
      _logger.d('AutoWithdraw skipped: escrow fund operation(s) in flight');
      return;
    }

    // Gate 3: Any active (non-terminal) swaps already running?
    if (await _stateStore.hasNonTerminal('swap_in') ||
        await _stateStore.hasNonTerminal('swap_out')) {
      _logger.d('AutoWithdraw skipped: active swap(s) in progress');
      return;
    }

    final minimumBalance = rbtcFromSatsInt(
      _hostrConfig.autoWithdrawMinimumSats,
    );

    // Iterate each chain independently (sequential to avoid NWC invoice conflicts)
    for (final configured in _evm.configuredChains) {
      if (_swapInProgress) break;
      if (configured.swaps == null) continue; // no swap provider

      try {
        // Get individual address balances for this chain.
        final fundedAddresses = await configured.getAddressesWithBalance();

        // Gate 4: Apply minimum balance per individual address.
        final qualifyingIndices = <int>{};
        for (final entry in fundedAddresses) {
          if (entry.balance >= minimumBalance) {
            qualifyingIndices.add(entry.accountIndex);
            _logger.d(
              'AutoWithdraw: address index ${entry.accountIndex} on '
              '${configured.config.id} qualifies with '
              '${entry.balance.getInSats} sats',
            );
          } else {
            _logger.d(
              'AutoWithdraw skipped address index ${entry.accountIndex} on '
              '${configured.config.id}: balance ${entry.balance.getInSats} sats '
              'below minimum ${_hostrConfig.autoWithdrawMinimumSats}',
            );
          }
        }

        if (qualifyingIndices.isEmpty) {
          _logger.d(
            'AutoWithdraw: no qualifying addresses on ${configured.config.id}',
          );
          continue;
        }

        // Create swap-out operations for all funded addresses.
        final swapOps = await Future.wait(
          fundedAddresses.map((entry) async {
            final evmKey = await _evm.logger.span(
              'getActiveEvmKey',
              () => getIt<Auth>().hd.getActiveEvmKey(
                accountIndex: entry.accountIndex,
              ),
            );
            return configured.swapOut(
              params: SwapOutParams(
                evmKey: evmKey,
                accountIndex: entry.accountIndex,
                amount: null,
              ),
              auth: getIt<Auth>(),
              logger: _logger,
              nwc: getIt<Nwc>(),
              payments: getIt<Payments>(),
              quoteService: getIt<SwapOutQuoteService>(),
            );
          }),
        );

        for (final swapOp in swapOps) {
          if (_swapInProgress) break;

          if (!qualifyingIndices.contains(swapOp.params.accountIndex)) {
            continue;
          }

          try {
            // Gate 5: Fee ratio acceptable?
            final fees = await swapOp.estimateFees();
            final opBalance = swapOp.balance!;
            final networkFees = fees.networkFees;
            final totalFees = TokenAmount.fromDenominated(
              networkFees,
              opBalance.token,
            );
            final netAmount = opBalance - totalFees;

            if (netAmount <= TokenAmount.zero(rbtc)) {
              _logger.d(
                'AutoWithdraw skipped on ${configured.config.id}: '
                'fees exceed balance',
              );
              continue;
            }

            final feeRatio = networkFees.value == BigInt.zero
                ? 0.0
                : networkFees.value.toDouble() / opBalance.getInSats.toDouble();

            if (feeRatio > maxFeeRatio) {
              _logger.d(
                'AutoWithdraw skipped on ${configured.config.id}: fee ratio '
                '${(feeRatio * 100).toStringAsFixed(1)}% exceeds max '
                '${(maxFeeRatio * 100).toStringAsFixed(1)}%',
              );
              continue;
            }

            // All gates passed — execute swap-out for this address
            _swapInProgress = true;
            _logger.i(
              'AutoWithdraw: initiating swap-out of '
              '${opBalance.getInSats} sats on ${configured.config.id}',
            );

            await swapOp.execute();

            if (swapOp.state is SwapOutCompleted) {
              _logger.i(
                'AutoWithdraw: swap-out completed on ${configured.config.id}',
              );
            } else if (swapOp.state is SwapOutFailed) {
              final failed = swapOp.state as SwapOutFailed;
              _logger.e(
                'AutoWithdraw: swap-out failed on ${configured.config.id}: '
                '${failed.error}',
              );
            }
          } catch (e) {
            _logger.e(
              'AutoWithdraw: swap-out failed on ${configured.config.id}: $e',
            );
          } finally {
            _swapInProgress = false;
            _cooldownTimer = Timer(cooldownDuration, () {});
          }
        }
      } catch (e) {
        _logger.e(
          'AutoWithdraw: failed to create swap-out ops on ${configured.config.id}: $e',
        );
      }
    }
  });
}
