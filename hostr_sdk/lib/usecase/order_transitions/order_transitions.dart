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
class OrderTransitions extends CrudUseCase<ReservationTransition> {
  final Ndk _ndk;

  OrderTransitions({
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
    final privateKey = signerKeyPair?.privateKey;
    final customSigner = privateKey != null && privateKey.isNotEmpty
        ? Bip340EventSigner(
            privateKey: privateKey,
            publicKey: signerKeyPair!.publicKey,
          )
        : null;
    final result = await _ndk.marketplace.orderTransitions.record(
      order: MarketplaceOrder.fromEvent(reservation),
      transitionType: MarketplaceOrderTransitionType.values.firstWhere(
        (type) => type.name == transitionType.name,
      ),
      fromStage: MarketplaceOrderStage.values.firstWhere(
        (stage) => stage.name == fromStage.name,
      ),
      toStage: MarketplaceOrderStage.values.firstWhere(
        (stage) => stage.name == toStage.name,
      ),
      customSigner: customSigner,
      commitTermsHash: commitTermsHash ?? reservation.commitHash(),
      reason: reason,
      updatedFields: updatedFields,
      prevTransitionId: prevTransitionId,
    );
    return ReservationTransition.fromNostrEvent(result.transition);
  }

  /// Query all transitions for a given trade id (`d` tag).
  Future<List<ReservationTransition>> getForReservation(String tradeId) async {
    final transitions = await _ndk.marketplace.orderTransitions
        .queryByTradeId(tradeId)
        .future;
    return [
      for (final transition in transitions)
        ReservationTransition.fromNostrEvent(transition),
    ];
  }

  /// Subscribe to live transitions for a given trade id (`d` tag).
  StreamWithStatus<ReservationTransition> subscribeForReservation(
    String tradeId,
  ) {
    return subscribe(
      Filter(kinds: ReservationTransition.kinds, dTags: [tradeId]),
      name: 'reservation-transitions-$tradeId',
    );
  }
}
