import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../../../datasources/boltz/boltz.dart';
import '../../../injection.dart';
import '../../../util/main.dart';
import '../chain/evm_chain.dart';
import '../chain/rootstock/operations/swap_in/swap_in_operation.dart'
    as rootstock_swap_in;
import '../chain/rootstock/operations/swap_out/swap_out_operation.dart'
    as rootstock_swap_out;
import 'swap_in/swap_in_models.dart';
import 'swap_out/swap_out_models.dart';
import 'swap_record.dart';
import 'swap_store.dart';

/// Service that runs on app start to recover pending swaps.
///
/// **Why this exists:**
/// Boltz swaps involve multi-step atomic protocols where funds are at risk
/// between steps. If the app crashes, loses network, or the user force-quits
/// mid-swap, we need to:
///
/// - **Swap-In (reverse submarine):** Re-attempt claiming on-chain funds
///   using the persisted preimage. Without this, Boltz will refund itself
///   after the timelock and the user loses their Lightning payment.
///
/// - **Swap-Out (submarine):** Re-attempt refunding locked EVM funds.
///   First tries cooperative refund (immediate, requires Boltz cooperation),
///   then falls back to timelock refund (after expiry block height).
///
/// This service is a thin orchestrator: it loads pending records, resolves
/// the EVM chain, constructs the appropriate swap cubit, and delegates the
/// actual recovery logic to [SwapInOperation.recover] / [SwapOutOperation.recover].
@injectable
class SwapRecoveryService {
  final SwapStore _swapStore;
  final BoltzClient _boltzClient;
  final CustomLogger _logger;

  SwapRecoveryService(this._swapStore, this._boltzClient, this._logger);

  /// Check for pending swaps and attempt recovery.
  ///
  /// Returns the number of swaps that were successfully resolved.
  /// This method is safe to call multiple times (idempotent).
  ///
  /// [chainResolver] maps a chainId to the [EvmChain] that can execute
  /// claim / refund transactions on that network.
  Future<int> recoverPendingSwaps({
    required EthPrivateKey evmKey,
    required Future<EvmChain> Function(int chainId) chainResolver,
  }) async {
    await _swapStore.initialize();

    // Always prune old completed/refunded records (older than 30 days)
    final pruned = await _swapStore.pruneOlderThan(const Duration(days: 30));
    if (pruned > 0) {
      _logger.d('SwapRecovery: pruned $pruned old swap records');
    }

    final pending = await _swapStore.getPendingRecovery();

    if (pending.isEmpty) {
      _logger.d('SwapRecovery: no pending swaps to recover');
      return 0;
    }

    _logger.i('SwapRecovery: found ${pending.length} swap(s) needing recovery');
    int resolved = 0;

    for (final record in pending) {
      try {
        // Resolve the EVM chain for this swap record
        final chain = await chainResolver(record.chainId);

        // Check the current Boltz status via HTTP
        final currentStatus = await _boltzClient.getSwap(id: record.boltzId);
        _logger.d(
          'SwapRecovery: ${record.boltzId} Boltz status: ${currentStatus.status}',
        );

        final bool success;
        switch (record) {
          case SwapInRecord r:
            success = await _recoverSwapIn(
              record: r,
              boltzStatus: currentStatus.status,
              evmKey: evmKey,
              chain: chain,
            );
          case SwapOutRecord r:
            success = await _recoverSwapOut(
              record: r,
              boltzStatus: currentStatus.status,
              evmKey: evmKey,
              chain: chain,
            );
        }
        if (success) resolved++;
      } catch (e) {
        _logger.e('SwapRecovery: failed to recover ${record.boltzId}: $e');
        await _swapStore.updateStatus(
          record.id,
          SwapRecordStatus.needsAction,
          errorMessage: 'Recovery attempt failed: $e',
        );
      }
    }

    _logger.i('SwapRecovery: resolved $resolved of ${pending.length} swaps');
    return resolved;
  }

  // ── Swap-In Recovery ──────────────────────────────────────────────────

  Future<bool> _recoverSwapIn({
    required SwapInRecord record,
    required String boltzStatus,
    required EthPrivateKey evmKey,
    required EvmChain chain,
  }) async {
    final cubit = getIt<rootstock_swap_in.RootstockSwapInOperation>(
      param1: SwapInParams(
        evmKey: evmKey,
        // Amount is unused during recovery — only recover() is called.
        amount: BitcoinAmount.zero(),
      ),
    );
    try {
      return await cubit.recover(
        record: record,
        boltzStatus: boltzStatus,
        chain: chain,
        swapStore: _swapStore,
      );
    } finally {
      await cubit.close();
    }
  }

  // ── Swap-Out Recovery ─────────────────────────────────────────────────

  Future<bool> _recoverSwapOut({
    required SwapOutRecord record,
    required String boltzStatus,
    required EthPrivateKey evmKey,
    required EvmChain chain,
  }) async {
    final cubit = getIt<rootstock_swap_out.RootstockSwapOutOperation>(
      param1: SwapOutParams(
        evmKey: evmKey,
        // Amount is unused during recovery — only recover() is called.
        amount: null,
      ),
    );
    try {
      return await cubit.recover(
        record: record,
        boltzStatus: boltzStatus,
        chain: chain,
        swapStore: _swapStore,
      );
    } finally {
      await cubit.close();
    }
  }
}
