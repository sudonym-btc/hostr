import 'package:models/main.dart';

import '../entity_factory.dart';
import '../seed_pipeline_models.dart';

/// Build deterministic [OrderTransition] events for seeded threads.
///
/// Emits transitions for:
/// - order request creation (guest, negotiate -> negotiate)
/// - finalized order creation/update (guest/host, negotiate -> commit)
/// - cancellation updates (host/guest, * -> cancel)
List<OrderTransition> buildOrderTransitions({
  required List<SeedThread> threads,
  EntityFactory? factory,
}) {
  final f = factory ?? EntityFactory();
  final transitions = <OrderTransition>[];

  for (final thread in threads) {
    final tradeId = thread.request.getDtag();
    if (tradeId == null || tradeId.isEmpty) continue;

    final request = thread.request;

    final requestTransition = f.orderTransition(
      signer: thread.guest.keyPair,
      tradeId: tradeId,
      eventId: request.id,
      listingAnchor: request.parsedTags.listingAnchor,
      transitionType: OrderTransitionType.counterOffer,
      fromStage: OrderStage.negotiate,
      toStage: OrderStage.negotiate,
      commitTermsHash: request.commitHash(),
      createdAt: request.createdAt,
    );

    transitions.add(requestTransition);

    final order = thread.order;
    if (order == null) continue;

    final cancelled = order.stage == OrderStage.cancel;
    final transitionType = cancelled
        ? OrderTransitionType.cancel
        : OrderTransitionType.commit;
    final actor = thread.selfSigned
        ? thread.guest.keyPair
        : thread.host.keyPair;
    final toStage = cancelled ? OrderStage.cancel : OrderStage.commit;

    final orderTransition = f.orderTransition(
      signer: actor,
      tradeId: tradeId,
      eventId: order.id,
      listingAnchor: order.parsedTags.listingAnchor,
      transitionType: transitionType,
      fromStage: OrderStage.negotiate,
      toStage: toStage,
      commitTermsHash: order.commitHash(),
      previousTransitionId: requestTransition.id,
      createdAt: order.createdAt,
    );

    transitions.add(orderTransition);
  }

  return transitions;
}
