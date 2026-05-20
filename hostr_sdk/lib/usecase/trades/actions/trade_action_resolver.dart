import 'package:models/main.dart';

import '../../../util/stream_status.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../messaging/thread/state.dart';
import '../trade.dart';
import 'payment.dart';
import 'order.dart';
import 'order_request.dart';

enum TradeAction {
  cancel,
  refund,
  claim,
  messageEscrow,
  accept,
  counter,
  pay,
  review,
}

enum TradeAvailability {
  loading,
  available,
  unavailable,
  cancelled,
  invalidOrder,
  invalidTransitions,
}

typedef OverlapLock = ({bool isLoading, bool isBlocked, String? reason});

class TradeResolution {
  final TradeRole? role;
  final List<TradeAction> actions;
  final TradeAvailability availability;
  final String? availabilityReason;

  bool get isAvailable => availability == TradeAvailability.available;

  const TradeResolution({
    this.role,
    required this.actions,
    required this.availability,
    this.availabilityReason,
  });
}

class TradeActionResolver {
  static TradeResolution resolve({
    required ThreadState threadState,
    required Listing listing,
    required TradeRole role,
    required String tradeId,
    required DateTime? start,
    required DateTime? end,
    required TokenAmount? amount,
    required String ourPubkey,
    required List<Validation<OrderGroup>> allOrders,
    required StreamStatus allOrdersStatus,
    required List<Validation<OrderGroup>> ownOrders,
    required StreamStatus ownOrdersStatus,
    required List<PaymentEvent> payments,
    required StreamStatus paymentsStatus,
    List<String> addedParticipants = const [],
  }) {
    final validAllListingPairs = allOrders
        .whereType<Valid<OrderGroup>>()
        .map((v) => v.event)
        .where((p) => !p.cancelled)
        .toList();

    final allTradeOrders = ownOrders
        .expand((validation) => validation.event.orders)
        .toList();

    final validTradeOrders = ownOrders
        .whereType<Valid<OrderGroup>>()
        .where((v) => !v.event.cancelled)
        .expand((v) => v.event.orders)
        .toList();

    final allOrdersLoaded =
        allOrdersStatus is StreamStatusQueryComplete ||
        allOrdersStatus is StreamStatusLive;
    final overlapLock = allOrdersLoaded
        ? resolveOverlapLock(
            ourOrderDTag: tradeId,
            allListingOrderGroups: validAllListingPairs,
            startDate: start,
            endDate: end,
          )
        : (isLoading: true, isBlocked: false, reason: null);
    final hasPayment = payments.isNotEmpty;
    final latestRequest = threadState.orderRequests.isNotEmpty
        ? threadState.orderRequests.last
        : null;
    final latestRequestCancelled = latestRequest?.stage == OrderStage.cancel;

    final resolvedActions = <TradeAction>[];

    resolvedActions.addAll(
      PaymentActions.resolve(payments, paymentsStatus, role),
    );

    resolvedActions.addAll(
      OrderActions.resolve(
        validTradeOrders,
        ownOrdersStatus,
        role,
        allOrders: allTradeOrders,
      ),
    );

    if (ownOrdersStatus is StreamStatusLive &&
        ownOrders.isEmpty &&
        !hasPayment &&
        !latestRequestCancelled) {
      resolvedActions.addAll(
        OrderRequestActions.resolve(
          threadState.orderRequests,
          listing,
          ourPubkey,
          role,
        ),
      );
    }

    final availability = _resolveAvailability(
      ownOrders: ownOrders,
      overlapLock: overlapLock,
      negotiationCancelled: ownOrders.isEmpty && latestRequestCancelled,
    );

    return TradeResolution(
      role: role,
      actions: resolvedActions,
      availability: availability,
      availabilityReason: switch (availability) {
        TradeAvailability.unavailable => overlapLock.reason,
        _ => null,
      },
    );
  }
}

TradeAvailability _resolveAvailability({
  required List<Validation<OrderGroup>> ownOrders,
  required OverlapLock overlapLock,
  bool negotiationCancelled = false,
}) {
  if (negotiationCancelled) {
    return TradeAvailability.cancelled;
  }
  if (ownOrders.any((v) => v is Invalid)) {
    return TradeAvailability.invalidOrder;
  }
  if (ownOrders.whereType<Valid<OrderGroup>>().any((v) => v.event.cancelled)) {
    return TradeAvailability.cancelled;
  }
  if (overlapLock.isLoading) return TradeAvailability.loading;
  if (overlapLock.isBlocked) return TradeAvailability.unavailable;
  return TradeAvailability.available;
}

OverlapLock resolveOverlapLock({
  required List<OrderGroup> allListingOrderGroups,
  required DateTime? startDate,
  required DateTime? endDate,
  required String ourOrderDTag,
}) {
  // No date range – overlap check is not applicable.
  if (startDate == null || endDate == null) {
    return (isLoading: false, isBlocked: false, reason: null);
  }

  final overlapsOtherCommitment = allListingOrderGroups.any((group) {
    if (group.cancelled) {
      return false;
    }

    final groupStart = group.start;
    final groupEnd = group.end;
    if (groupStart == null || groupEnd == null) {
      return false;
    }

    final groupTradeId =
        group.sellerOrder?.getDtag() ?? group.buyerOrder?.getDtag();
    if (groupTradeId == null || groupTradeId == ourOrderDTag) {
      return false;
    }

    if (!_overlapsRange(
      startA: startDate,
      endA: endDate,
      startB: groupStart,
      endB: groupEnd,
    )) {
      return false;
    }

    return true;
  });

  if (!overlapsOtherCommitment) {
    return (isLoading: false, isBlocked: false, reason: null);
  }

  return (isLoading: false, isBlocked: true, reason: 'Unavailable');
}

bool _overlapsRange({
  required DateTime startA,
  required DateTime endA,
  required DateTime startB,
  required DateTime endB,
}) {
  return Listing.datesOverlap(
    startA: startA,
    endA: endA,
    startB: startB,
    endB: endB,
  );
}
