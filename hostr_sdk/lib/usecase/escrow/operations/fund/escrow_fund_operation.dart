import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

@injectable
class EscrowFundOperation extends Cubit<EscrowFundState> {
  final CustomLogger logger;
  final Auth auth;
  final Evm evm;
  late final EvmChain chain;
  late final SupportedEscrowContract contract;
  final EscrowFundParams params;
  late final ContractFundEscrowParams contractParams;
  bool _isExecuting = false;

  EscrowFundOperation(
    this.auth,
    this.evm,
    this.logger,
    @factoryParam this.params,
  ) : super(EscrowFundInitialised()) {
    chain = evm.getChainForEscrowService(params.escrowService);
    contract = chain.getSupportedEscrowContract(params.escrowService);
    contractParams = params.toContractParams(auth.getActiveEvmKey());
  }

  Future<EscrowFundFees> estimateFees() async {
    final requiredSwapAmount = await _doesEscrowRequireSwap();
    final swapFees = requiredSwapAmount > BitcoinAmount.zero()
        ? await chain
              .swapIn(
                SwapInParams(
                  evmKey: auth.getActiveEvmKey(),
                  amount: requiredSwapAmount,
                ),
              )
              .estimateFees()
        : SwapInFees(
            estimatedGasFees: BitcoinAmount.zero(),
            estimatedSwapFees: BitcoinAmount.zero(),
            estimatedRelayFees: BitcoinAmount.zero(),
          );
    return EscrowFundFees(
      estimatedGasFees: await contract.estimateDespositFee(contractParams),
      estimatedSwapFees: swapFees,
    );
  }

  Future<void> execute() async {
    if (_isExecuting) {
      logger.w('Escrow fund already in progress, ignoring duplicate execute()');
      return;
    }
    _isExecuting = true;
    try {
      logger.i(
        'Creating escrow for tradeId ${params.toContractParams(auth.getActiveEvmKey()).tradeId} at ${params.escrowService.parsedContent.contractAddress}',
      );
      await _swapRequiredAmount();
      emit(EscrowFundDepositing());
      TransactionInformation tx = await contract.deposit(contractParams);
      final txHash = _extractTxHash(tx);
      if (txHash != null) {
        emit(EscrowFundDepositing(txHash: txHash));
        final receipt = await chain.awaitReceipt(txHash);
        if (!_isReceiptSuccessful(receipt)) {
          throw StateError(
            'Escrow funding transaction reverted (tx: $txHash, receipt: $receipt)',
          );
        }
        logger.d(
          'Escrow deposit transaction confirmed with hash: $txHash, $receipt',
        );
        logger.d('Receipt ${receipt.blockNumber}');
      } else {
        logger.w(
          'Could not extract tx hash from TransactionInformation, skipping receipt status check',
        );
      }
      logger.d('Escrow funded with transaction: $tx');
      emit(EscrowFundCompleted(transactionInformation: tx));
    } catch (error, stackTrace) {
      logger.e('Escrow failed', error: error, stackTrace: stackTrace);
      final e = EscrowFundFailed(error, stackTrace);
      emit(e);
      throw e;
    } finally {
      _isExecuting = false;
    }
  }

  String? _extractTxHash(TransactionInformation tx) {
    final dynamic d = tx;
    final hash = d.hash?.toString() ?? d.id?.toString();
    if (hash == null || hash.isEmpty) {
      return null;
    }
    return hash;
  }

  bool _isReceiptSuccessful(TransactionReceipt receipt) {
    final dynamic status = (receipt as dynamic).status;
    if (status == null) {
      // Some chains / providers may omit status on very old-style receipts.
      return true;
    }
    if (status is bool) return status;
    if (status is int) return status == 1;
    if (status is BigInt) return status == BigInt.one;

    final normalized = status.toString().toLowerCase();
    return normalized == '1' || normalized == '0x1' || normalized == 'true';
  }

  Future<BitcoinAmount> _doesEscrowRequireSwap() async {
    final balance = await chain.getBalance(auth.getActiveEvmKey().address);
    logger.i('Escrow sender balance: $balance RBTC');

    final transactionFee = await contract.estimateDespositFee(contractParams);

    final leftAfterTrade =
        balance - BitcoinAmount.fromAmount(params.amount) - transactionFee;

    if (leftAfterTrade < BitcoinAmount.zero()) {
      logger.e(
        'Insufficient balance for escrow deposit. Have $balance RBTC, would leave us with $leftAfterTrade',
      );

      return BitcoinAmount.max(
        await chain.getMinimumSwapIn(),
        leftAfterTrade.abs(),
      ).roundUp(BitcoinUnit.sat);
    }
    return BitcoinAmount.zero();
  }

  Future<void> _swapRequiredAmount() async {
    final requiredAmountInBtc = await _doesEscrowRequireSwap();
    if (requiredAmountInBtc > BitcoinAmount.zero()) {
      SwapInOperation swapEstimation = chain.swapIn(
        SwapInParams(
          evmKey: auth.getActiveEvmKey(),
          amount: requiredAmountInBtc,
        ),
      );
      final swapFees = await swapEstimation.estimateFees();
      SwapInOperation swap = chain.swapIn(
        SwapInParams(
          evmKey: auth.getActiveEvmKey(),
          amount: (requiredAmountInBtc + swapFees.totalFees).roundUp(
            BitcoinUnit.sat,
          ),
        ),
      );
      final sub = swap.stream.listen((state) {
        emit(EscrowFundSwapProgress(state));
      });

      try {
        await swap.execute();
      } finally {
        await sub.cancel();
      }
    }
  }
}
