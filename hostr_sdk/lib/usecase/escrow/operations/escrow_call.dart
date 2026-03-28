import 'package:bloc/bloc.dart';
import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../../util/bloc_x.dart';
import '../../../util/custom_logger.dart';
import '../../auth/auth.dart';
import '../../evm/main.dart';
import '../../trade_account_allocator/trade_account_allocator.dart';
import '../supported_escrow_contract/supported_escrow_contract.dart';
import 'onchain_operation.dart';

/// Lightweight base for escrow contract calls that have **no loss-of-funds
/// risk** (e.g. claim, release).
///
/// Unlike [OnchainOperation] this class:
/// - Has **no persistence** — nothing is written to [OperationStateStore].
/// - Has **no recovery** — if the process dies, the caller retries.
/// - Has **no state machine** — just a linear async flow.
///
/// It *is* a [Cubit<OnchainOperationState>] so it plugs straight into
/// existing `BlocBuilder` UI and `detachOrClose` teardown.
abstract class EscrowCall extends Cubit<OnchainOperationState> {
  final Auth auth;
  final TradeAccountAllocator tradeAccountAllocator;
  final Evm evm;
  final CustomLogger logger;

  late final EvmChain configuredChain;
  late final SupportedEscrowContract contract;
  late final EthPrivateKey signer;
  late final int accountIndex;

  EscrowCall(this.auth, this.tradeAccountAllocator, this.evm, this.logger)
    : super(const OnchainInitialised());

  /// The escrow service this call targets.
  EscrowService get escrowService;

  /// Trade ID for HD account resolution.
  String get tradeId;

  /// Optional pre-flight check (e.g. `canClaim`). Throws to abort.
  Future<void> preflight() async {}

  /// Build the named calls for this operation.
  /// Called after [signer] is resolved.
  Map<String, Call> buildCalls();

  /// Safely tear down when a widget disposes.
  void detach() =>
      detachOrClose((s) => s.isTerminal || s is OnchainInitialised);

  /// Run the full operation: resolve signer → preflight → broadcast → confirm.
  Future<void> execute() async {
    try {
      // ── Prepare ──
      accountIndex =
          await tradeAccountAllocator.tryFindTradeAccountIndexByTradeId(
            tradeId,
          ) ??
          0;
      signer = await auth.hd.getActiveEvmKey(accountIndex: accountIndex);
      await contract.ensureDeployed();
      await preflight();

      // ── Build calls ──
      final calls = buildCalls();

      // ── Broadcast ──
      emit(OnchainTxBroadcast(_data(calls: calls)));
      final txHash = await configuredChain.sendCalls(signer, calls);

      // ── Confirm ──
      emit(OnchainTxSent(_data(calls: calls, txHash: txHash)));
      final receipt = await configuredChain.awaitReceipt(txHash);

      if (!_isReceiptSuccessful(receipt)) {
        emit(
          OnchainError(
            'Transaction reverted: $txHash',
            data: _data(calls: calls, txHash: txHash),
          ),
        );
        return;
      }

      configuredChain.notifyNewBlock();
      emit(
        OnchainTxConfirmed(
          _data(calls: calls, txHash: txHash, receipt: receipt),
        ),
      );
    } catch (e, st) {
      logger.e('EscrowCall failed: $e', error: e, stackTrace: st);
      emit(OnchainError(e));
    }
  }

  OnchainCallData _data({
    required Map<String, Call> calls,
    String? txHash,
    TransactionReceipt? receipt,
  }) => OnchainCallData(
    operationIdValue: tradeId,
    contractAddress: escrowService.contractAddress,
    chainId: escrowService.chainId,
    accountIndex: accountIndex,
    calls: calls,
    transport: 'direct',
    txHash: txHash,
    transactionReceipt: receipt,
  );

  static bool _isReceiptSuccessful(TransactionReceipt receipt) {
    final dynamic status = (receipt as dynamic).status;
    if (status == null) return true;
    if (status is bool) return status;
    if (status is int) return status == 1;
    if (status is BigInt) return status == BigInt.one;
    final normalized = status.toString().toLowerCase();
    return normalized == '1' || normalized == '0x1' || normalized == 'true';
  }
}
