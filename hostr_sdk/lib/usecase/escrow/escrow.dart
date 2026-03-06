import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../escrow_trusts/escrow_trusts.dart';
import '../escrows/escrows.dart';
import '../evm/evm.dart';
import 'operations/claim/escrow_claim_models.dart';
import 'operations/claim/escrow_claim_operation.dart';
import 'operations/fund/escrow_fund_models.dart';
import 'operations/fund/escrow_fund_operation.dart';
import 'operations/fund/escrow_fund_registry.dart';
import 'operations/release/escrow_release_models.dart';
import 'operations/release/escrow_release_operation.dart';
import 'supported_escrow_contract/supported_escrow_contract.dart';

@Singleton()
class EscrowUseCase {
  final CustomLogger logger;
  final Auth auth;
  final Escrows escrows;
  final EscrowTrusts escrowTrusts;
  final Evm evm;
  final EscrowFundRegistry escrowFundRegistry;

  EscrowUseCase({
    required this.logger,
    required this.auth,
    required this.escrows,
    required this.escrowTrusts,
    required this.evm,
    required this.escrowFundRegistry,
  });

  EscrowFundOperation fund(EscrowFundParams params) {
    final operation = getIt<EscrowFundOperation>(param1: params);
    final tradeId = params.negotiateReservation.getDtag();
    if (tradeId != null) {
      escrowFundRegistry.register(tradeId, operation);
    }
    return operation;
  }

  EscrowClaimOperation claim(EscrowClaimParams params) {
    return getIt<EscrowClaimOperation>(param1: params);
  }

  EscrowReleaseOperation release(EscrowReleaseParams params) {
    return getIt<EscrowReleaseOperation>(param1: params);
  }

  StreamWithStatus<EscrowEvent> checkEscrowStatus(
    EscrowServiceSelected selectedEscrow,
    String tradeId,
  ) {
    logger.i('Checking escrow status for reservation: $tradeId');

    final contract = evm
        .getChainForEscrowService(selectedEscrow.service)
        .getSupportedEscrowContract(selectedEscrow.service);

    final source = contract.allEvents(
      ContractEventsParams(tradeId: tradeId),
      selectedEscrow,
    );

    // Auto-close after a terminal escrow event so the live EVM WebSocket
    // subscription doesn't run indefinitely in the UserSubscriptions
    // singleton.
    source.stream.listen((event) {
      if (event is EscrowReleasedEvent ||
          event is EscrowClaimedEvent ||
          event is EscrowArbitratedEvent) {
        logger.d(
          'Terminal escrow event received for $tradeId — closing stream',
        );
        source.close();
      }
    });

    return source;
  }
}
