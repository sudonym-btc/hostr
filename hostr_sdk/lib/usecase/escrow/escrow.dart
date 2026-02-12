import 'package:hostr_sdk/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

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

  StreamWithStatus<EscrowEvent> checkEscrowStatus(
    EscrowServiceSelected selectedEscrow,
    String tradeId,
  ) {
    logger.i('Checking escrow status for reservation: $tradeId');

    try {
      final contract = evm
          .getChainForEscrowService(selectedEscrow.parsedContent.service)
          .getSupportedEscrowContract(selectedEscrow.parsedContent.service);

      return contract.allEvents(tradeId);
    } catch (e) {
      logger.e(
        'Error getting supported escrow contract for ${selectedEscrow.parsedContent.service}',
        error: e,
      );
      rethrow;
    }
  }
}
