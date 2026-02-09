import 'package:hostr_sdk/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../../util/main.dart';
import '../auth/auth.dart';
import '../escrow_trusts/escrow_trusts.dart';
import '../escrows/escrows.dart';
import '../evm/evm.dart';
import 'operations/fund/escrow_fund_models.dart';
import 'operations/fund/escrow_fund_operation.dart';
import 'supported_escrow_contract/supported_escrow_contract.dart';

@Singleton()
class EscrowUseCase {
  final CustomLogger logger;
  final Auth auth;
  final Escrows escrows;
  final EscrowTrusts escrowTrusts;
  final Evm evm;

  EscrowUseCase({
    required this.logger,
    required this.auth,
    required this.escrows,
    required this.escrowTrusts,
    required this.evm,
  });

  EscrowFundOperation fund(EscrowFundParams params) {
    return getIt<EscrowFundOperation>(param1: params);
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
