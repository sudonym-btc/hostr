import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart';

import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import '../../../background_worker/background_worker.dart';
import '../../../evm/evm.dart';
import '../../../evm/operations/operation_state_store.dart';
import '../../../trade_account_allocator/trade_account_allocator.dart';
import '../onchain_operation.dart';
import 'escrow_fund_operation.dart';
import 'escrow_fund_registry.dart';
import 'escrow_fund_state.dart';

/// Recovers pending escrow fund operations on app start.
///
/// Loads persisted escrow fund states from [OperationStateStore], checks
/// whether any nested swap has completed, and resumes the deposit if so.
///
/// **Key design constraint:** This recoverer does NOT recover nested swaps.
/// If the swap is still in progress, the recovery exits immediately — the
/// [SwapRecoverer] handles completing swaps. On the next recovery pass
/// (or when the swap completes), this recoverer will pick up the escrow
/// deposit.
@injectable
class EscrowFundRecoverer {
  final OperationStateStore _store;
  final Auth _auth;
  final TradeAccountAllocator _tradeAccountAllocator;
  final Evm _evm;
  final CustomLogger _logger;
  final EscrowFundRegistry _registry;

  EscrowFundRecoverer(
    this._store,
    this._auth,
    this._tradeAccountAllocator,
    this._evm,
    CustomLogger logger,
    this._registry,
  ) : _logger = logger.scope('fund-recoverer');

  /// Recover all pending escrow fund operations.
  ///
  /// When [onProgress] is provided, fires real-time notifications at key
  /// state transitions (e.g. deposit broadcast, deposit confirmed) using
  /// the escrow `tradeId` as the stable notification ID.
  ///
  /// Returns the number of operations that were resolved.
  Future<int> recoverAll({
    bool isBackground = false,
    OnBackgroundProgress? onProgress,
  }) => _logger.span('recoverAll', () async {
    // Prune terminal entries older than 30 days.
    final pruned = await _store.pruneTerminal(
      'escrow_fund',
      const Duration(days: 30),
    );
    if (pruned > 0) {
      _logger.d('EscrowFundRecoverer: pruned $pruned old entries');
    }

    final entries = await _store.readAll('escrow_fund');
    _logger.i(
      'EscrowFundRecoverer: found ${entries.length} escrow fund state(s)',
    );
    if (entries.isEmpty) return 0;

    int resolved = 0;

    for (final json in entries) {
      try {
        final state = OnchainOperationState.fromJson(
          json,
          EscrowFundData.fromJson,
        );
        if (state.isTerminal || state is OnchainInitialised) continue;
        if (await _recoverOne(
          state,
          isBackground: isBackground,
          onProgress: onProgress,
        ))
          resolved++;
      } catch (e) {
        _logger.e('EscrowFundRecoverer: error: $e');
      }
    }

    _logger.i('EscrowFundRecoverer: resolved $resolved operation(s)');
    return resolved;
  });

  Future<bool> _recoverOne(
    OnchainOperationState state, {
    bool isBackground = false,
    OnBackgroundProgress? onProgress,
  }) => _logger.span('_recoverOne', () async {
    final data = state.data!;

    // Resolve the chain and escrow contract from persisted data.
    final chain = await _evm.getClientForChainId(data.chainId);
    final contract = chain.getSupportedEscrowContractByName(
      'MultiEscrow',
      EthereumAddress.fromHex(data.contractAddress),
    );

    final cubit = EscrowFundOperation.forRecovery(
      _auth,
      _tradeAccountAllocator,
      _evm,
      _logger,
      recoveryChain: chain,
      recoveryContract: contract,
      initialState: state,
    );

    final tradeId = data.operationId;
    _registry.register(tradeId, cubit);

    // Let the operation itself fire progress notifications.
    if (onProgress != null) {
      cubit.onProgress = (id, msg) =>
          onProgress(BackgroundNotification(operationId: id, body: msg));
    }

    try {
      await cubit.recover(isBackground: isBackground);
      return cubit.state.isTerminal;
    } catch (_) {
      // Registry auto-unregisters on terminal / error / done.
      rethrow;
    }
  });
}
