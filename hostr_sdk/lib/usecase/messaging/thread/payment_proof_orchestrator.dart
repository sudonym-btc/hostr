import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01EventModel;

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

  bool _readyStatus(StreamStatus status) {
    return status is StreamStatusLive || status is StreamStatusQueryComplete;
  }

  Future<void> syncAndPublishProofs() async {
    await subscriptions.state.firstWhere((state) {
      return _readyStatus(state.paymentStreamStatus) &&
          _readyStatus(state.reservationStreamStatus);
    });

    if (subscriptions.state.value.reservations.isNotEmpty) {
      return;
    }

    PaymentFundedEvent? funded;
    for (final event in subscriptions.state.value.paymentEvents) {
      if (event is PaymentFundedEvent) {
        funded = event;
        break;
      }
    }

    funded ??= await subscriptions.paymentEvents.stream
        .where((event) => event is PaymentFundedEvent)
        .cast<PaymentFundedEvent>()
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
      threadId: thread.anchor,
      reservationRequest: thread.state.value.lastReservationRequest,
      proof: proof,
    );
    logger.d('Created self-signed reservation: ${reservation.id}');
  }
}
