import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../../util/main.dart';
import '../auth/auth.dart';
import '../crud.usecase.dart';

/// CRUD use-case for [ReservationTransition] events (kind 32126).
///
/// Every reservation stage change (negotiate ↔ counter-offer, negotiate →
/// commit, * → cancel, seller-ack) MUST be recorded as a transition so
/// relays and auditing clients can reconstruct the full history.
@Singleton()
class ReservationTransitions extends CrudUseCase<ReservationTransition> {
  final Ndk ndk;
  final Auth auth;

  ReservationTransitions({
    required super.requests,
    required super.logger,
    required this.ndk,
    required this.auth,
  }) : super(kind: ReservationTransition.kinds[0]);

  /// Broadcast a transition event and return it.
  ///
  /// [reservation]       — the reservation being transitioned.
  /// [transitionType]    — what kind of transition this is.
  /// [fromStage]         — the stage before the transition.
  /// [toStage]           — the stage after the transition.
  /// [commitTermsHash]   — the commit-terms hash at the time of transition.
  /// [reason]            — optional human-readable note (e.g. cancellation reason).
  /// [updatedFields]     — snapshot of changed fields for counter-offers.
  /// [prevTransitionId]  — event id of the previous transition in the chain.
  Future<ReservationTransition> record({
    required Reservation reservation,
    required ReservationTransitionType transitionType,
    required ReservationStage fromStage,
    required ReservationStage toStage,
    String? commitTermsHash,
    String? reason,
    Map<String, dynamic>? updatedFields,
    String? prevTransitionId,
  }) async {
    final tradeId = reservation.getDtag() ?? '';
    final tags = <List<String>>[
      if (tradeId.isNotEmpty) ['t', tradeId],
      ['e', reservation.id],
      if (prevTransitionId != null) ['prev', prevTransitionId],
      if (reservation.parsedTags.listingAnchor.isNotEmpty)
        [kListingRefTag, reservation.parsedTags.listingAnchor],
    ];

    final transition = ReservationTransition.fromNostrEvent(
      await ndk.accounts.sign(
        Nip01Event(
          kind: kNostrKindReservationTransition,
          pubKey: ndk.accounts.getPublicKey()!,
          tags: tags,
          content: ReservationTransitionContent(
            transitionType: transitionType,
            fromStage: fromStage,
            toStage: toStage,
            commitTermsHash:
                commitTermsHash ?? reservation.parsedContent.commitHash(),
            reason: reason,
            updatedFields: updatedFields,
          ).toString(),
        ),
      ),
    );

    await upsert(transition);
    return transition;
  }

  /// Query all transitions for a given trade id (t tag).
  Future<List<ReservationTransition>> getForReservation(String tradeId) {
    return list(
      Filter(
        kinds: ReservationTransition.kinds,
        tags: {
          't': [tradeId],
        },
      ),
      name: 'reservation-transitions-get-$tradeId',
    );
  }

  /// Subscribe to live transitions for a given trade id (t tag).
  StreamWithStatus<ReservationTransition> subscribeForReservation(
    String tradeId,
  ) {
    return subscribe(
      Filter(
        kinds: ReservationTransition.kinds,
        tags: {
          't': [tradeId],
        },
      ),
      name: 'reservation-transitions-$tradeId',
    );
  }
}
