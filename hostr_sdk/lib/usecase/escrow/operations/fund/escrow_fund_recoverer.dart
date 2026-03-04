import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart';

import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import '../../../evm/evm.dart';
import '../../../evm/operations/operation_state_store.dart';
import '../../supported_escrow_contract/supported_escrow_contract_registry.dart';
import 'escrow_fund_operation.dart';
import 'escrow_fund_registry.dart';
import 'escrow_fund_state.dart';

/// Recovers pending escrow fund operations on app start.
///
/// Loads persisted [EscrowFundState]s from [OperationStateStore], checks
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
  final Evm _evm;
  final CustomLogger _logger;
  final EscrowFundRegistry _registry;

  EscrowFundRecoverer(
    this._store,
    this._auth,
    this._evm,
    this._logger,
    this._registry,
  );

  /// Recover all pending escrow fund operations.
  ///
  /// Returns the number of operations that were resolved.
  Future<int> recoverAll() async {
    // Prune terminal entries older than 30 days.
    final pruned = await _store.pruneTerminal(
      'escrow_fund',
      const Duration(days: 30),
    );
    if (pruned > 0) {
      _logger.d('EscrowFundRecoverer: pruned $pruned old entries');
    }

    final entries = await _store.readAll('escrow_fund');
    if (entries.isEmpty) return 0;

    _logger.i(
      'EscrowFundRecoverer: found ${entries.length} escrow fund state(s)',
    );
    int resolved = 0;

    for (final json in entries) {
      try {
        final state = EscrowFundState.fromJson(json);
        if (state.isTerminal || state is EscrowFundInitialised) continue;
        if (await _recoverOne(state)) resolved++;
      } catch (e) {
        _logger.e('EscrowFundRecoverer: error: $e');
      }
    }

    _logger.i('EscrowFundRecoverer: resolved $resolved operation(s)');
    return resolved;
  }

  Future<bool> _recoverOne(EscrowFundState state) async {
    final data = state.data!;

    // Resolve the chain and escrow contract from persisted data.
    final chain = await _evm.getClientForChainId(data.chainId);
    final contract = SupportedEscrowContractRegistry.getSupportedContract(
      'MultiEscrow',
      chain.client,
      EthereumAddress.fromHex(data.contractAddress),
    );

    if (contract == null) {
      _logger.e(
        'EscrowFundRecoverer: no contract found for ${data.contractAddress}',
      );
      return false;
    }

    final cubit = EscrowFundOperation.forRecovery(
      _auth,
      _evm,
      _logger,
      recoveryChain: chain,
      recoveryContract: contract,
      initialState: state,
    );

    final tradeId = data.tradeId;
    _registry.register(tradeId, cubit);

    try {
      await cubit.recover();
      return cubit.state.isTerminal;
    } catch (_) {
      // Registry auto-unregisters on terminal / error / done.
      rethrow;
    }
  }
}
