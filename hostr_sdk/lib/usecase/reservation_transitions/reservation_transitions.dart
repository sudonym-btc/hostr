import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../util/main.dart';
import '../crud.usecase.dart';

/// CRUD use-case for append-only [ReservationTransition] events.
///
/// Every reservation stage change (negotiate ↔ counter-offer, negotiate →
/// commit, * → cancel, seller-ack) MUST be recorded as a transition so
/// relays and auditing clients can reconstruct the full history.
@Singleton()
class ReservationTransitions extends CrudUseCase<ReservationTransition> {
  final Ndk _ndk;

  ReservationTransitions({
    required super.requests,
    required super.logger,
    required Ndk ndk,
  }) : _ndk = ndk,
       super(kind: ReservationTransition.kinds[0]);

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
    KeyPair? signerKeyPair,
    String? commitTermsHash,
    String? reason,
    Map<String, dynamic>? updatedFields,
    String? prevTransitionId,
  }) async {
    final tradeId = reservation.getDtag() ?? '';
    final privateKey = signerKeyPair?.privateKey;
    final pubkey = privateKey != null && privateKey.isNotEmpty
        ? signerKeyPair!.publicKey
        : _ndk.accounts.getPublicKey()!;
    final effectivePrevTransitionId =
        prevTransitionId ??
        await _resolvePreviousTransitionId(tradeId: tradeId, pubkey: pubkey);
    final tags = <List<String>>[
      if (tradeId.isNotEmpty) ['t', tradeId],
      ['e', reservation.id],
      if (effectivePrevTransitionId != null)
        ['prev', effectivePrevTransitionId],
      if (reservation.parsedTags.listingAnchor.isNotEmpty)
        [kListingRefTag, reservation.parsedTags.listingAnchor],
    ];

    final unsigned = Nip01Event(
      kind: kNostrKindReservationTransition,
      pubKey: pubkey,
      tags: tags,
      content: ReservationTransitionContent(
        transitionType: transitionType,
        fromStage: fromStage,
        toStage: toStage,
        commitTermsHash: commitTermsHash ?? reservation.commitHash(),
        reason: reason,
        updatedFields: updatedFields,
      ).toString(),
    );
    final transition = ReservationTransition.fromNostrEvent(unsigned);
    final result = await upsert(
      transition,
      signer: privateKey != null && privateKey.isNotEmpty
          ? (event) async => Nip01Utils.signWithPrivateKey(
              event: event,
              privateKey: privateKey,
            )
          : null,
    );
    return result.event;
  }

  Future<String?> _resolvePreviousTransitionId({
    required String tradeId,
    required String pubkey,
  }) async {
    if (tradeId.isEmpty) return null;

    final existing = (await getForReservation(
      tradeId,
    )).where((transition) => transition.pubKey == pubkey).toList();
    if (existing.isEmpty) return null;

    final chain = resolveStateTransitionChain(existing);
    if (!chain.validation.isValid) {
      throw StateError(
        'Cannot append reservation transition: existing transition chain is '
        'invalid (${chain.validation.reason})',
      );
    }

    return chain.transitions.last.id;
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
