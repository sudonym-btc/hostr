import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../injection.dart';
import '../../util/main.dart';
import '../evm/evm.dart';
import 'operations/claim/escrow_claim_models.dart';
import 'operations/claim/escrow_claim_operation.dart';
import 'operations/fund/escrow_fund_models.dart';
import 'operations/fund/escrow_fund_preparer.dart';
import 'operations/release/escrow_release_models.dart';
import 'operations/release/escrow_release_operation.dart';
import 'supported_escrow_contract/supported_escrow_contract.dart';

@Singleton()
class EscrowUseCase {
  final CustomLogger _logger;
  final Evm _evm;

  EscrowUseCase({required CustomLogger logger, required Evm evm})
    : _evm = evm,
      _logger = logger.scope('escrow');

  EscrowFundPreparer fund(EscrowFundParams params) =>
      _logger.spanSync('fund', () {
        return getIt<EscrowFundPreparer>(param1: params);
      });

  EscrowClaimOperation claim(EscrowClaimParams params) =>
      _logger.spanSync('claim', () {
        return getIt<EscrowClaimOperation>(param1: params);
      });

  EscrowReleaseOperation release(EscrowReleaseParams params) =>
      _logger.spanSync('release', () {
        return getIt<EscrowReleaseOperation>(param1: params);
      });

  StreamWithStatus<EscrowEvent> checkEscrowStatus(
    EscrowServiceSelected selectedEscrow,
    String tradeId,
  ) => _logger.spanSync('checkEscrowStatus', () {
    _logger.i('Checking escrow status for reservation: $tradeId');

    final contract = _evm
        .getChainForEscrowService(selectedEscrow.service)
        .escrow
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
        _logger.d(
          'Terminal escrow event received for $tradeId — closing stream',
        );
        unawaited(source.close());
      }
    });

    return source;
  });
}
