import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import '../chain/rootstock/operations/swap_in/swap_in_operation.dart'
    as rootstock_swap_in;
import '../chain/rootstock/operations/swap_out/swap_out_operation.dart'
    as rootstock_swap_out;

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

  SwapRecoverer(this._store, this._auth, this._logger);

  /// Recover all pending swaps (both swap-in and swap-out).
  ///
  /// Returns the number of swaps that were resolved (completed, failed,
  /// or refunded). Safe to call repeatedly — idempotent.
  Future<int> recoverAll() async {
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
        if (await _recoverSwapIn(state)) resolved++;
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

  Future<bool> _recoverSwapIn(SwapInState state) async {
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

    try {
      return await cubit.recover();
    } finally {
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
