import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import '../../../util/main.dart';
import '../../auth/auth.dart';
import '../../background_worker/background_worker.dart';
import '../../nwc/nwc.dart';
import '../../payments/payments.dart';
import '../chain/rootstock/operations/swap_in/swap_in_operation.dart'
    as rootstock_swap_in;
import '../chain/rootstock/operations/swap_out/swap_out_operation.dart'
    as rootstock_swap_out;
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
  final CustomLogger _logger;

  SwapRecoverer(this._store, this._auth, CustomLogger logger)
    : _logger = logger.namespace('swap-recoverer');

  /// Recover all pending swaps (both swap-in and swap-out).
  ///
  /// When [onProgress] is provided, fires real-time notifications at key
  /// swap state transitions. [swapToTradeId] maps a swap's `boltzId` to
  /// its parent escrow `tradeId` so the notification ID stays stable.
  ///
  /// Returns the number of swaps that were resolved (completed, failed,
  /// or refunded). Safe to call repeatedly — idempotent.
  Future<int> recoverAll({
    OnBackgroundProgress? onProgress,
    Map<String, String> swapToTradeId = const {},
  }) async {
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
      _logger.d('SwapRecoverer: pruned ${prunedIn + prunedOut} old entries');
    }

    // Recover swap-ins
    final swapInEntries = await _store.readAll('swap_in');
    for (final json in swapInEntries) {
      try {
        final state = SwapInState.fromJson(json);
        if (state.isTerminal || state is SwapInInitialised) continue;
        if (await _recoverSwapIn(
          state,
          onProgress: onProgress,
          swapToTradeId: swapToTradeId,
        )) {
          resolved++;
        }
      } catch (e) {
        _logger.e('SwapRecoverer: swap-in recovery error: $e');
      }
    }

    // Recover swap-outs
    final swapOutEntries = await _store.readAll('swap_out');
    for (final json in swapOutEntries) {
      try {
        final state = SwapOutState.fromJson(json);
        if (state.isTerminal || state is SwapOutInitialised) continue;
        if (await _recoverSwapOut(state)) resolved++;
      } catch (e) {
        _logger.e('SwapRecoverer: swap-out recovery error: $e');
      }
    }

    if (swapInEntries.isNotEmpty || swapOutEntries.isNotEmpty) {
      _logger.i('SwapRecoverer: resolved $resolved swap(s)');
    }
    return resolved;
  }

  Future<bool> _recoverSwapIn(
    SwapInState state, {
    OnBackgroundProgress? onProgress,
    Map<String, String> swapToTradeId = const {},
  }) async {
    final data = state.data!;
    final evmKey = _auth.getActiveEvmKey(accountIndex: data.accountIndex);

    final cubit = rootstock_swap_in.RootstockSwapInOperation(
      rootstock: getIt<Rootstock>(),
      auth: _auth,
      logger: _logger,
      params: SwapInParams(
        evmKey: evmKey,
        accountIndex: data.accountIndex,
        // Amount is unused during recovery — only recover() is called.
        amount: BitcoinAmount.zero(),
      ),
      initialState: state,
    );

    // Listen for key state transitions and fire progress notifications.
    StreamSubscription? sub;
    if (onProgress != null) {
      final opId = swapToTradeId[data.boltzId] ?? data.boltzId;
      _logger.d(
        'SwapRecoverer: listening for progress on ${data.boltzId} '
        '(notif opId=$opId, initial state=${state.runtimeType})',
      );
      sub = cubit.stream.listen((s) {
        _logger.d('SwapRecoverer: state transition → ${s.runtimeType}');
        final String? message;
        if (s is SwapInAwaitingOnChain) {
          message = 'Invoice paid, awaiting on-chain confirmation\u2026';
        } else if (s is SwapInFunded) {
          message = 'Swap funds received, claiming\u2026';
        } else if (s is SwapInCompleted) {
          message = 'Swap completed';
        } else {
          message = null;
        }
        if (message != null) {
          onProgress(BackgroundNotification(operationId: opId, body: message));
        }
      });
    }

    try {
      return await cubit.recover();
    } finally {
      await sub?.cancel();
      await cubit.close();
    }
  }

  Future<bool> _recoverSwapOut(SwapOutState state) async {
    final data = state.data!;
    final evmKey = _auth.getActiveEvmKey(accountIndex: data.accountIndex);

    final cubit = rootstock_swap_out.RootstockSwapOutOperation(
      rootstock: getIt<Rootstock>(),
      auth: _auth,
      logger: _logger,
      nwc: getIt<Nwc>(),
      payments: getIt<Payments>(),
      quoteService: getIt<SwapOutQuoteService>(),
      params: SwapOutParams(
        evmKey: evmKey,
        accountIndex: data.accountIndex,
        // Amount is unused during recovery — only recover() is called.
        amount: null,
      ),
      initialState: state,
    );

    try {
      return await cubit.recover();
    } finally {
      await cubit.close();
    }
  }
}
