import 'package:models/main.dart';

import '../entity_factory.dart';
import '../seed_pipeline_models.dart';

/// Build deterministic [ReservationTransition] events for seeded threads.
///
/// Emits transitions for:
/// - reservation request creation (guest, negotiate -> negotiate)
/// - finalized reservation creation/update (guest/host, negotiate -> commit)
/// - cancellation updates (host/guest, * -> cancel)
List<ReservationTransition> buildReservationTransitions({
  required List<SeedThread> threads,
  EntityFactory? factory,
}) {
  final f = factory ?? EntityFactory();
  final transitions = <ReservationTransition>[];

  for (final thread in threads) {
    final tradeId = thread.request.getDtag();
    if (tradeId == null || tradeId.isEmpty) continue;

    final request = thread.request;

    final requestTransition = f.reservationTransition(
      signer: thread.guest.keyPair,
      tradeId: tradeId,
      eventId: request.id,
      listingAnchor: request.parsedTags.listingAnchor,
      transitionType: ReservationTransitionType.counterOffer,
      fromStage: ReservationStage.negotiate,
      toStage: ReservationStage.negotiate,
      commitTermsHash: request.commitHash(),
      createdAt: request.createdAt,
    );

    transitions.add(requestTransition);

    final reservation = thread.reservation;
    if (reservation == null) continue;

    final cancelled = reservation.stage == ReservationStage.cancel;
    final transitionType = cancelled
        ? ReservationTransitionType.cancel
        : ReservationTransitionType.commit;
    final actor = thread.selfSigned
        ? thread.guest.keyPair
        : thread.host.keyPair;
    final toStage = cancelled
        ? ReservationStage.cancel
        : ReservationStage.commit;

    final reservationTransition = f.reservationTransition(
      signer: actor,
      tradeId: tradeId,
      eventId: reservation.id,
      listingAnchor: reservation.parsedTags.listingAnchor,
      transitionType: transitionType,
      fromStage: ReservationStage.negotiate,
      toStage: toStage,
      commitTermsHash: reservation.commitHash(),
      previousTransitionId: requestTransition.id,
      createdAt: reservation.createdAt,
    );

    transitions.add(reservationTransition);
  }

  return transitions;
}
