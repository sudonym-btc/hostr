import 'package:hostr/core/util/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow/escrow_cubit.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow_trusts/escrows_trusts.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:web3dart/web3dart.dart';

import '../auth/auth.dart';
import '../escrows/escrows.dart';
import '../evm/evm.dart';

@Singleton()
class EscrowUseCase {
  final CustomLogger logger = CustomLogger();
  final Auth auth;
  final Escrows escrows;
  final EscrowTrusts escrowTrusts;
  final Evm evm;

  EscrowUseCase({
    required this.auth,
    required this.escrows,
    required this.escrowTrusts,
    required this.evm,
  });

  Future<BitcoinAmount> doesEscrowRequireSwap(EscrowFundParams params) async {
    final balance = await evm
        .getChainForEscrowService(params.escrowService)
        .getBalance(auth.getActiveEvmKey().address);
    logger.i('Escrow sender balance: $balance RBTC');

    final transactionFee = await evm
        .getChainForEscrowService(params.escrowService)
        .getSupportedEscrowContract(params.escrowService)
        .estimateDespositFee(params.toContractParams(auth.getActiveEvmKey()));

    final leftAfterTrade =
        balance - BitcoinAmount.fromAmount(params.amount) - transactionFee;

    if (leftAfterTrade < BitcoinAmount.zero()) {
      logger.e(
        'Insufficient balance for escrow deposit. Have $balance RBTC, would leave us with $leftAfterTrade',
      );

      return BitcoinAmount.max(
        await evm
            .getChainForEscrowService(params.escrowService)
            .getMinimumSwapIn(),
        leftAfterTrade.abs(),
      ).roundUp(BitcoinUnit.sat);
    }
    return BitcoinAmount.zero();
  }

  Stream<EscrowSwapProgress> swapRequiredAmount(
    EscrowFundParams params,
  ) async* {
    final requiredAmountInBtc = await doesEscrowRequireSwap(params);
    if (requiredAmountInBtc > BitcoinAmount.zero()) {
      yield* evm
          .getChainForEscrowService(params.escrowService)
          .swapIn(key: auth.getActiveEvmKey(), amount: requiredAmountInBtc)
          .map((swap) => EscrowSwapProgress(swap));
    }
  }

  Future<EscrowFees> estimateFees(EscrowFundParams params) async {
    final requiredSwapAmount = await doesEscrowRequireSwap(params);
    return EscrowFees(
      estimatedGasFees: await evm
          .getChainForEscrowService(params.escrowService)
          .getSupportedEscrowContract(params.escrowService)
          .estimateDespositFee(params.toContractParams(auth.getActiveEvmKey())),
      estimatedSwapFees: requiredSwapAmount > BitcoinAmount.zero()
          ? await evm
                .getChainForEscrowService(params.escrowService)
                .estimateSwapInFees(requiredSwapAmount)
          : BitcoinAmount.zero(),
    );
  }

  Stream<EscrowState> fund(EscrowFundParams params) async* {
    try {
      yield* swapRequiredAmount(params);

      logger.i(
        'Creating escrow for ${params.reservationRequest.id} at ${params.escrowService.parsedContent.contractAddress}',
      );
      TransactionInformation tx = await evm
          .getChainForEscrowService(params.escrowService)
          .getSupportedEscrowContract(params.escrowService)
          .deposit(params.toContractParams(auth.getActiveEvmKey()));
      yield EscrowCompleted(transactionInformation: tx);
    } catch (error, stackTrace) {
      logger.e('Escrow failed', error: error, stackTrace: stackTrace);
      final e = EscrowFailed(error, stackTrace);
      yield (e);
      throw e;
    }
  }

  StreamWithStatus<FundedEvent> checkEscrowStatus(
    String tradeId,
    String counterpartyPubkey,
  ) {
    logger.i('Checking escrow status for reservation: $tradeId');

    Future<List<String>> getBothTrustedEscrows() async {
      EscrowTrust? myTrustedEscrows = await escrowTrusts.trusted(
        auth.activeKeyPair!.publicKey,
      );
      EscrowTrust? theirTrustedEscrows = await escrowTrusts.trusted(
        counterpartyPubkey,
      );

      final myTrustedList = myTrustedEscrows == null
          ? null
          : await myTrustedEscrows.toNip51List();
      final theirTrustedList = theirTrustedEscrows == null
          ? null
          : await theirTrustedEscrows.toNip51List();

      final trustedEscrowPubkeys = <String>{
        ...(myTrustedList?.elements ?? []).map((e) => e.value),
        ...(theirTrustedList?.elements ?? []).map((e) => e.value),
      }.toList();

      if (trustedEscrowPubkeys.isEmpty) {
        logger.w('No trusted escrows for either party.');
      }
      return trustedEscrowPubkeys;
    }

    Future<List<SupportedEscrowContract>> getSubscribableContracts() async {
      final supportedContracts = <String, SupportedEscrowContract>{};
      List<String> escrowPubkeys = await getBothTrustedEscrows();
      for (String item in escrowPubkeys) {
        List<EscrowService> escrowServices = await escrows.list(
          Filter(authors: [item]),
        );
        for (var escrow in escrowServices) {
          try {
            final contract = evm
                .getChainForEscrowService(escrow)
                .getSupportedEscrowContract(escrow);
            supportedContracts[contract.address.toString()] = contract;
          } catch (e) {
            logger.e(
              'Error getting supported escrow contract for ${escrow.id}',
              error: e,
            );
          }
        }
      }
      return supportedContracts.values.toList();
    }

    return StreamWithStatus.combineAsync(
      getSubscribableContracts().then(
        (contracts) => contracts
            .map((contract) => contract.fundedEvents(tradeId))
            .toList(),
      ),
    );
  }
}

class EscrowFundParams {
  final EscrowService escrowService;
  final ReservationRequest reservationRequest;
  final ProfileMetadata sellerProfile;
  final Amount amount;

  EscrowFundParams({
    required this.escrowService,
    required this.reservationRequest,
    required this.sellerProfile,
    required this.amount,
  });

  ContractFundEscrowParams toContractParams(EthPrivateKey ethKey) {
    return ContractFundEscrowParams(
      tradeId: reservationRequest.id,
      amount: BitcoinAmount.fromAmount(amount),
      sellerEvmAddress: sellerProfile.evmAddress!,
      arbiterEvmAddress: escrowService.parsedContent.evmAddress,
      ethKey: ethKey,
      timelock: 100,
      // escrowFee: escrowService.parsedContent.fee,
    );
  }
}

class EscrowFees {
  final BitcoinAmount estimatedGasFees;
  final BitcoinAmount estimatedSwapFees;

  EscrowFees({required this.estimatedGasFees, required this.estimatedSwapFees});
}
