import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01EventModel;
import 'package:rxdart/rxdart.dart';

class ThreadPaymentProofOrchestrator {
  final Thread thread;
  final ThreadSubscriptions subscriptions;
  final ThreadContext context;
  final Reservations reservations;
  final CustomLogger logger;

  ThreadPaymentProofOrchestrator({
    required this.thread,
    required this.subscriptions,
    required this.context,
    required this.reservations,
    required this.logger,
  });

  Future<void> syncAndPublishProofs() async {
    await subscriptions.reservationStream.status
        .whereType<StreamStatusLive>()
        .first;

    if (subscriptions.state.value.reservations.isNotEmpty) {
      logger.d(
        'Thread ${thread.anchor} already has reservations, skipping proof publication',
      );
      return;
    }

    final funded = await subscriptions.paymentEvents.replay
        .where((event) => event is PaymentFundedEvent)
        .first;

    final listing = await context.getListing();
    final hoster = await context.getListingProfile();
    if (listing == null || hoster == null) {
      logger.w(
        'Cannot publish proof for thread ${thread.anchor}: context missing',
      );
      return;
    }

    final proof = SelfSignedProof(
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
      reservationRequest: thread.state.value.lastReservationRequest,
      proof: proof,
    );
    logger.d('Created self-signed reservation: ${reservation.id}');
  }
}
