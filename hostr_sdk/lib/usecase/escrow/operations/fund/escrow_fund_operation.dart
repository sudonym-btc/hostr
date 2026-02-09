import 'package:hostr_sdk/util/main.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import '../../../auth/auth.dart';
import '../../../evm/chain/evm_chain.dart';
import '../../../evm/evm.dart';
import '../../../evm/operations/swap_in/swap_in_models.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import 'escrow_fund_models.dart';
import 'escrow_fund_state.dart';

@injectable
class EscrowFundOperation {
  final CustomLogger logger = CustomLogger();
  final Auth auth;
  final Evm evm;
  late final EvmChain chain;
  late final SupportedEscrowContract contract;
  final EscrowFundParams params;
  late final ContractFundEscrowParams contractParams;

  EscrowFundOperation(this.auth, this.evm, @factoryParam this.params) {
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

  Stream<EscrowFundState> execute() async* {
    try {
      await for (final swapState in _swapRequiredAmount()) {
        yield EscrowFundSwapProgress(swapState.swapState);
      }

      logger.i(
        'Creating escrow for ${params.reservationRequest.id} at ${params.escrowService.parsedContent.contractAddress}',
      );
      TransactionInformation tx = await contract.deposit(contractParams);
      yield EscrowFundCompleted(transactionInformation: tx);
    } catch (error, stackTrace) {
      logger.e('Escrow failed', error: error, stackTrace: stackTrace);
      final e = EscrowFundFailed(error, stackTrace);
      yield e;
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

  Stream<EscrowFundSwapProgress> _swapRequiredAmount() async* {
    final requiredAmountInBtc = await _doesEscrowRequireSwap();
    if (requiredAmountInBtc > BitcoinAmount.zero()) {
      await for (final swapState
          in chain
              .swapIn(
                SwapInParams(
                  evmKey: auth.getActiveEvmKey(),
                  amount: requiredAmountInBtc,
                ),
              )
              .execute()) {
        yield EscrowFundSwapProgress(swapState);
      }
    }
  }
}
