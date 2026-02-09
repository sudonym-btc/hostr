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

  Future<EscrowFees> estimateFees() async {
    final requiredSwapAmount = await _doesEscrowRequireSwap();
    return EscrowFees(
      estimatedGasFees: await contract.estimateDespositFee(contractParams),
      estimatedSwapFees: requiredSwapAmount > BitcoinAmount.zero()
          ? await chain
                .swapIn(
                  SwapInParams(
                    evmKey: auth.getActiveEvmKey(),
                    amount: requiredSwapAmount,
                  ),
                )
                .estimateFees()
          : BitcoinAmount.zero(),
    );
  }

  Future<void> execute() async {
    try {
      logger.i(
        'Creating escrow for ${params.reservationRequest.id} at ${params.escrowService.parsedContent.contractAddress}',
      );
      await _swapRequiredAmount();
      TransactionInformation tx = await contract.deposit(contractParams);
      emit(EscrowFundCompleted(transactionInformation: tx));
    } catch (error, stackTrace) {
      logger.e('Escrow failed', error: error, stackTrace: stackTrace);
      final e = EscrowFundFailed(error, stackTrace);
      emit(e);
      throw e;
    }
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
      SwapInOperation swap = chain.swapIn(
        SwapInParams(
          evmKey: auth.getActiveEvmKey(),
          amount: requiredAmountInBtc,
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
