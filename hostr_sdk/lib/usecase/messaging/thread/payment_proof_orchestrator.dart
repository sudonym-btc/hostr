import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01EventModel;
import 'package:rxdart/rxdart.dart';

@injectable
class ThreadPaymentProofOrchestrator {
  final ThreadTrade trade;
  final Auth auth;
  final Reservations reservations;
  final CustomLogger logger;

  ThreadPaymentProofOrchestrator({
    @factoryParam required this.trade,
    required this.auth,
    required this.reservations,
    required this.logger,
  });

  /// Starts the orchestrator using the already-resolved [context].
  /// Must only be called after [TradeSubscriptions.start] has completed so
  /// that [trade.subscriptions] stream fields are non-null.
  Future<void> start(TradeContext context) async {
    final subscriptions = trade.subscriptions;

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

    final hasExistingTradeReservation = subscriptions
        .reservationStream!
        .list
        .value
        .whereType<Validation<ReservationPairStatus>>()
        .expand((validation) => [validation.event.buyerReservation])
        .whereType<Reservation>()
        .isNotEmpty;

    if (hasExistingTradeReservation) {
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

    final listing = context.listing;
    final hoster = context.profile;

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
      negotiateReservation: trade.thread.state.value.lastReservationRequest,
      proof: proof,
    );
    logger.d('Created self-signed reservation: ${reservation.id}');
  }
}
