import 'package:models/main.dart';

import '../seed_pipeline_models.dart';

/// Build deterministic [ReservationTransition] events for seeded threads.
///
/// Emits transitions for:
/// - reservation request creation (guest, negotiate -> negotiate)
/// - finalized reservation creation/update (guest/host, negotiate -> commit)
/// - cancellation updates (host/guest, * -> cancel)
List<ReservationTransition> buildReservationTransitions({
  required List<SeedThread> threads,
}) {
  final transitions = <ReservationTransition>[];

  for (final thread in threads) {
    final tradeId = thread.request.getDtag();
    if (tradeId == null || tradeId.isEmpty) continue;

    final request = thread.request;

    final requestTransition = ReservationTransition(
      pubKey: thread.guest.keyPair.publicKey,
      createdAt: request.createdAt,
      tags: ReservationTransitionTags([
        ['t', tradeId],
        ['e', request.id],
        [kListingRefTag, request.parsedTags.listingAnchor],
      ]),
      content: ReservationTransitionContent(
        transitionType: ReservationTransitionType.counterOffer,
        fromStage: ReservationStage.negotiate,
        toStage: ReservationStage.negotiate,
        commitTermsHash: request.parsedContent.commitHash(),
      ),
    ).signAs(thread.guest.keyPair, ReservationTransition.fromNostrEvent);

    transitions.add(requestTransition);

    final reservation = thread.reservation;
    if (reservation == null) continue;

    final cancelled =
        reservation.parsedContent.cancelled ||
        reservation.parsedContent.stage == ReservationStage.cancel;
    final transitionType = cancelled
        ? ReservationTransitionType.cancel
        : (thread.selfSigned
              ? ReservationTransitionType.commit
              : ReservationTransitionType.sellerAck);
    final actor = thread.selfSigned
        ? thread.guest.keyPair
        : thread.host.keyPair;
    final toStage = cancelled
        ? ReservationStage.cancel
        : ReservationStage.commit;

    final reservationTransition = ReservationTransition(
      pubKey: actor.publicKey,
      createdAt: reservation.createdAt,
      tags: ReservationTransitionTags([
        ['t', tradeId],
        ['e', reservation.id],
        ['prev', requestTransition.id],
        [kListingRefTag, reservation.parsedTags.listingAnchor],
      ]),
      content: ReservationTransitionContent(
        transitionType: transitionType,
        fromStage: ReservationStage.negotiate,
        toStage: toStage,
        commitTermsHash: reservation.parsedContent.commitHash(),
      ),
    ).signAs(actor, ReservationTransition.fromNostrEvent);

    transitions.add(reservationTransition);
  }

  return transitions;
}
