import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/reservation_request.dart';
import 'package:hostr_sdk/usecase/messaging/thread/state.dart';
import 'package:hostr_sdk/usecase/messaging/thread/trade_context.dart';
import 'package:hostr_sdk/util/stream_status.dart';
import 'package:hostr_sdk/util/validation_stream.dart';
import 'package:models/main.dart';

import 'payment.dart';
import 'reservation.dart';

// enum ThreadHeaderSource { reservation, reservationRequest, listing }

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
  final ThreadPartyRole? role;
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
  /// Pure function: derives available actions from concrete stream emissions.
  /// All inputs are plain values so this can be composed inside combineLatest.
  static TradeResolution resolve({
    required ThreadState threadState,
    required TradeContext context,
    required String tradeId,
    required DateTime start,
    required DateTime end,
    required Amount? amount,
    required String ourPubkey,
    required List<Validation<ReservationPairStatus>> allReservations,
    required List<Validation<ReservationPairStatus>> ownReservations,
    required StreamStatus ownReservationsStatus,
    required List<PaymentEvent> payments,
    required StreamStatus paymentsStatus,
    List<String> addedParticipants = const [],
  }) {
    final listing = context.listing;
    final role = context.role;

    final validAllListingPairs = allReservations
        .whereType<Valid<ReservationPairStatus>>()
        .map((v) => v.event)
        .where((p) => !p.cancelled)
        .toList();

    final validTradeReservations = ownReservations
        .whereType<Valid<ReservationPairStatus>>()
        .where((v) => !v.event.cancelled)
        .expand((v) => [v.event.sellerReservation, v.event.buyerReservation])
        .whereType<Reservation>()
        .toList();

    final overlapLock = resolveOverlapLock(
      ourReservationDTag: tradeId,
      allListingReservationPairs: validAllListingPairs,
      startDate: start,
      endDate: end,
    );

    final resolvedActions = <TradeAction>[];

    resolvedActions.addAll(
      PaymentActions.resolve(payments, paymentsStatus, role),
    );

    resolvedActions.addAll(
      ReservationActions.resolve(
        validTradeReservations,
        ownReservationsStatus,
        listing,
        [...threadState.participantPubkeys, ...addedParticipants],
        role,
      ),
    );

    // Only emit reservation-request actions if we have no reservation yet.
    if (ownReservationsStatus is StreamStatusLive && ownReservations.isEmpty) {
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
  required List<Validation<ReservationPairStatus>> ownReservations,
  required ({bool isBlocked, String? reason}) overlapLock,
}) {
  if (ownReservations.any((v) => v is Invalid)) {
    return TradeAvailability.invalidReservation;
  }
  if (ownReservations.whereType<Valid<ReservationPairStatus>>().any(
    (v) => v.event.cancelled,
  )) {
    return TradeAvailability.cancelled;
  }
  if (overlapLock.isBlocked) return TradeAvailability.unavailable;
  return TradeAvailability.available;
}

({bool isBlocked, String? reason}) resolveOverlapLock({
  required List<ReservationPairStatus> allListingReservationPairs,
  required DateTime startDate,
  required DateTime endDate,
  required String ourReservationDTag,
}) {
  final overlapsOtherCommitment = allListingReservationPairs.any((pair) {
    if (pair.cancelled) {
      return false;
    }

    final pairStart = pair.start;
    final pairEnd = pair.end;
    if (pairStart == null || pairEnd == null) {
      return false;
    }

    final pairTradeId =
        pair.sellerReservation?.getDtag() ?? pair.buyerReservation?.getDtag();
    if (pairTradeId == null || pairTradeId == ourReservationDTag) {
      return false;
    }

    if (!_overlapsRange(
      startA: startDate,
      endA: endDate,
      startB: pairStart,
      endB: pairEnd,
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
  DateTime normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  var aStart = normalize(startA);
  var aEnd = normalize(endA);
  var bStart = normalize(startB);
  var bEnd = normalize(endB);

  if (aEnd.isBefore(aStart)) {
    final temp = aStart;
    aStart = aEnd;
    aEnd = temp;
  }
  if (bEnd.isBefore(bStart)) {
    final temp = bStart;
    bStart = bEnd;
    bEnd = temp;
  }

  final aEffectiveEnd = aEnd.isAtSameMomentAs(aStart)
      ? aEnd.add(const Duration(days: 1))
      : aEnd;
  final bEffectiveEnd = bEnd.isAtSameMomentAs(bStart)
      ? bEnd.add(const Duration(days: 1))
      : bEnd;

  return aStart.isBefore(bEffectiveEnd) && aEffectiveEnd.isAfter(bStart);
}
