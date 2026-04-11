import 'package:models/main.dart';

import '../../../util/stream_status.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../messaging/thread/state.dart';
import '../trade.dart';
import 'payment.dart';
import 'reservation.dart';
import 'reservation_request.dart';

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
  available,
  unavailable,
  cancelled,
  invalidReservation,
  invalidTransitions,
}

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
    required List<Validation<ReservationGroup>> allReservations,
    required List<Validation<ReservationGroup>> ownReservations,
    required StreamStatus ownReservationsStatus,
    required List<PaymentEvent> payments,
    required StreamStatus paymentsStatus,
    List<String> addedParticipants = const [],
  }) {
    final validAllListingPairs = allReservations
        .whereType<Valid<ReservationGroup>>()
        .map((v) => v.event)
        .where((p) => !p.cancelled)
        .toList();

    final allTradeReservations = ownReservations
        .whereType<Valid<ReservationGroup>>()
        .expand((v) => v.event.reservations)
        .toList();

    final validTradeReservations = ownReservations
        .whereType<Valid<ReservationGroup>>()
        .where((v) => !v.event.cancelled)
        .expand((v) => v.event.reservations)
        .toList();

    final overlapLock = resolveOverlapLock(
      ourReservationDTag: tradeId,
      allListingReservationGroups: validAllListingPairs,
      startDate: start,
      endDate: end,
    );
    final hasPayment = payments.isNotEmpty;

    final resolvedActions = <TradeAction>[];

    resolvedActions.addAll(
      PaymentActions.resolve(payments, paymentsStatus, role),
    );

    resolvedActions.addAll(
      ReservationActions.resolve(
        validTradeReservations,
        ownReservationsStatus,
        role,
        allReservations: allTradeReservations,
      ),
    );

    if (ownReservationsStatus is StreamStatusLive &&
        ownReservations.isEmpty &&
        !hasPayment) {
      resolvedActions.addAll(
        ReservationRequestActions.resolve(
          threadState.reservationRequests,
          listing,
          ourPubkey,
          role,
        ),
      );
    }

    final availability = _resolveAvailability(
      ownReservations: ownReservations,
      overlapLock: overlapLock,
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
  required List<Validation<ReservationGroup>> ownReservations,
  required ({bool isBlocked, String? reason}) overlapLock,
}) {
  if (ownReservations.any((v) => v is Invalid)) {
    return TradeAvailability.invalidReservation;
  }
  if (ownReservations.whereType<Valid<ReservationGroup>>().any(
    (v) => v.event.cancelled,
  )) {
    return TradeAvailability.cancelled;
  }
  if (overlapLock.isBlocked) return TradeAvailability.unavailable;
  return TradeAvailability.available;
}

({bool isBlocked, String? reason}) resolveOverlapLock({
  required List<ReservationGroup> allListingReservationGroups,
  required DateTime? startDate,
  required DateTime? endDate,
  required String ourReservationDTag,
}) {
  // No date range – overlap check is not applicable.
  if (startDate == null || endDate == null) {
    return (isBlocked: false, reason: null);
  }

  final overlapsOtherCommitment = allListingReservationGroups.any((group) {
    if (group.cancelled) {
      return false;
    }

    final groupStart = group.start;
    final groupEnd = group.end;
    if (groupStart == null || groupEnd == null) {
      return false;
    }

    final groupTradeId =
        group.sellerReservation?.getDtag() ?? group.buyerReservation?.getDtag();
    if (groupTradeId == null || groupTradeId == ourReservationDTag) {
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
    return (isBlocked: false, reason: null);
  }

  return (isBlocked: true, reason: 'Unavailable');
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
