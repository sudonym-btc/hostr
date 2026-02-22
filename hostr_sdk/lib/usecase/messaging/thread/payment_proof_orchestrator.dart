import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01EventModel;
import 'package:rxdart/rxdart.dart';

@injectable
class ThreadPaymentProofOrchestrator {
  final ThreadTrade trade;
  final TradeSubscriptions subscriptions;
  final Auth auth;
  final Reservations reservations;
  final CustomLogger logger;

  ThreadPaymentProofOrchestrator({
    @factoryParam required this.trade,
    @factoryParam required this.subscriptions,
    required this.auth,
    required this.reservations,
    required this.logger,
  });

  Future<void> start() async {
    logger.d(
      'Starting payment proof orchestrator for thread ${trade.thread.anchor}',
    );

    try {
      await subscriptions.reservationStream!.status
          .whereType<StreamStatusLive>()
          .first;
    } catch (_) {
      // Stream was closed (trade deactivated) before going live.
      return;
    }

    if (subscriptions.reservationStream!.list.value.isNotEmpty) {
      logger.d(
        'Thread ${trade.thread.anchor} already has reservations, skipping proof publication',
      );
      return;
    }

    final PaymentEvent funded;
    try {
      funded = await subscriptions.paymentEvents!.replay
          .where((event) => event is PaymentFundedEvent)
          .first;
    } catch (_) {
      // Stream was closed (trade deactivated) before a funded event arrived.
      return;
    }

    final listing = await trade.getListing();
    final hoster = await trade.getListingProfile();

    if (listing == null || hoster == null) {
      logger.w(
        'Cannot publish proof for thread ${trade.thread.anchor}: context missing',
      );
      return;
    }
    if (listing.pubKey == auth.getActiveKey().publicKey) {
      logger.d(
        'We are the host for thread ${trade.thread.anchor}, skipping proof publication',
      );
      return;
    }

    final proof = PaymentProof(
      listing: listing,
      hoster: hoster,
      zapProof: funded is ZapFundedEvent
          ? ZapProof(receipt: Nip01EventModel.fromEntity(funded.event))
          : null,
      escrowProof: funded is EscrowFundedEvent
          ? EscrowProof(
              txHash: funded.transactionHash,
              hostsTrustedEscrows:
                  funded.escrowService!.parsedContent.sellerTrusts,
              hostsEscrowMethods:
                  funded.escrowService!.parsedContent.sellerMethods,
              escrowService: funded.escrowService!.parsedContent.service,
            )
          : null,
    );

    final reservation = await reservations.createSelfSigned(
      activeKeyPair: await trade.activeKeyPair(),
      reservationRequest: trade.thread.state.value.lastReservationRequest,
      proof: proof,
    );
    logger.d('Created self-signed reservation: ${reservation.id}');
  }
}
