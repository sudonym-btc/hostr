import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';

import '../../../util/main.dart';
import '../../auth/auth.dart';
import '../../background_worker/background_worker.dart';
import '../chain/operations/swap_in/swap_in_operation.dart';
import '../chain/operations/swap_out/swap_out_operation.dart';
import '../main.dart';

/// Recovers pending swap-in and swap-out operations on app start.
///
/// Loads persisted cubit states from [OperationStateStore], reconstructs
/// the appropriate swap cubits in the correct state, and calls [recover()].
///
/// Replaces the former [SwapRecoveryService] which used SwapStore/SwapRecord.
@injectable
class SwapRecoverer {
  final OperationStateStore _store;
  final Auth _auth;
  final Evm _evm;
  final CustomLogger _logger;

  SwapRecoverer(this._store, this._auth, this._evm, CustomLogger logger)
    : _logger = logger.scope('swap-recoverer');

  /// Recover all pending swaps (both swap-in and swap-out).
  ///
  /// When [onProgress] is provided, the swap operations fire real-time
  /// notifications at key state transitions. Nested swaps use their
  /// persisted [SwapInData.parentOperationId] to keep the notification
  /// ID stable across swap → parent-operation stages.
  ///
  /// Returns the number of swaps that were resolved (completed, failed,
  /// or refunded). Safe to call repeatedly — idempotent.
  Future<int> recoverAll({
    bool isBackground = false,
    OnBackgroundProgress? onProgress,
  }) => _logger.span('recoverAll', () async {
    int resolved = 0;

    // Prune terminal entries older than 30 days.
    final prunedIn = await _store.pruneTerminal(
      'swap_in',
      const Duration(days: 30),
    );
    final prunedOut = await _store.pruneTerminal(
      'swap_out',
      const Duration(days: 30),
    );
    if (prunedIn + prunedOut > 0) {
      _logger.d('pruned ${prunedIn + prunedOut} old entries');
    }

    // Recover swap-ins
    final swapInEntries = await _store.readAll('swap_in');
    for (final json in swapInEntries) {
      try {
        final state = SwapInState.fromJson(json);
        if (state.isTerminal || state is SwapInInitialised) continue;
        if (await _recoverSwapIn(
          state,
          isBackground: isBackground,
          onProgress: onProgress,
        )) {
          resolved++;
        }
      } catch (e) {
        _logger.e('swap-in recovery error: $e');
      }
    }

    // Recover swap-outs
    final swapOutEntries = await _store.readAll('swap_out');
    for (final json in swapOutEntries) {
      try {
        final state = SwapOutState.fromJson(json);
        if (state.isTerminal || state is SwapOutInitialised) continue;
        if (await _recoverSwapOut(state, isBackground: isBackground)) {
          resolved++;
        }
      } catch (e) {
        _logger.e('swap-out recovery error: $e');
      }
    }

    if (swapInEntries.isNotEmpty || swapOutEntries.isNotEmpty) {
      _logger.i('resolved $resolved swap(s)');
    }
    return resolved;
  });

  Future<bool> _recoverSwapIn(
    SwapInState state, {
    bool isBackground = false,
    OnBackgroundProgress? onProgress,
  }) => _logger.span('_recoverSwapIn', () async {
    final data = state.data!;

    final configuredChain = _evm.getChainByChainId(data.chainId);
    if (configuredChain == null) {
      throw StateError('No configured EVM chain for chainId ${data.chainId}');
    }

    final evmKey = await _auth.hd.getActiveEvmKey(
      accountIndex: data.accountIndex,
    );

    final cubit = EvmSwapInOperation(
      chain: configuredChain,
      auth: configuredChain.auth,
      logger: configuredChain.logger,
      params: SwapInParams(
        evmKey: evmKey,
        accountIndex: data.accountIndex,
        // Amount is unused during recovery — only recover() is called.
        amountSpec: AmountSpec.output(
          TokenAmount.zero(Token.native(data.chainId)),
        ),
        // Restore parent link from persisted data so notifications
        // update the same OS notification as the parent operation.
        parentOperationId: data.parentOperationId,
        // postClaimCalls are already persisted on SwapInData and
        // restored via initialState — no need to pass again.
      ),
      initialState: state,
    );

    // Let the swap operation itself fire progress notifications.
    if (onProgress != null) {
      cubit.onProgress = (id, msg) =>
          onProgress(BackgroundNotification(operationId: id, body: msg));
    }

    try {
      return await cubit.recover(isBackground: isBackground);
    } finally {
      // Don't close — the tracker holds a reference and unregisters
      // on terminal state. If already terminal, closing is safe.
      if (cubit.state.isTerminal) await cubit.close();
    }
  });

  Future<bool> _recoverSwapOut(
    SwapOutState state, {
    bool isBackground = false,
  }) => _logger.span('_recoverSwapOut', () async {
    final data = state.data!;
    final configuredChain = _evm.getChainByChainId(data.chainId);
    if (configuredChain == null) {
      throw StateError('No configured EVM chain for chainId ${data.chainId}');
    }

    var recoveryState = state;
    if (state is SwapOutWaitingForTimelock) {
      final currentBlock = await configuredChain.getLocktimeBlockNumber();
      if (currentBlock < data.timeoutBlockHeight) {
        _logger.i(
          'swap-out ${data.boltzId} waiting for refund timelock '
          '${data.timeoutBlockHeight} (current: $currentBlock)',
        );
        return false;
      }

      recoveryState = SwapOutFunded(data);
      await _store.write('swap_out', data.boltzId, recoveryState.toJson());
      _logger.i(
        'swap-out ${data.boltzId} timelock reached at block $currentBlock — '
        'resuming refund',
      );
    }

    final evmKey = await _auth.hd.getActiveEvmKey(
      accountIndex: data.accountIndex,
    );

    final cubit = EvmSwapOutOperation(
      chain: configuredChain,
      auth: configuredChain.auth,
      logger: configuredChain.logger,
      nwc: configuredChain.nwc,
      payments: configuredChain.payments,
      quoteService: configuredChain.quoteService,
      params: SwapOutParams(
        evmKey: evmKey,
        accountIndex: data.accountIndex,
        // Amount is unused during recovery — only recover() is called.
      ),
      initialState: recoveryState,
    );

    try {
      return await cubit.recover(isBackground: isBackground);
    } finally {
      if (cubit.state.isTerminal) await cubit.close();
    }
  });
}
