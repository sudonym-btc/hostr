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
    required DateTime start,
    required DateTime end,
    required Amount? amount,
    required String ourPubkey,
    required List<Validation<ReservationPair>> allReservations,
    required List<Validation<ReservationPair>> ownReservations,
    required StreamStatus ownReservationsStatus,
    required List<PaymentEvent> payments,
    required StreamStatus paymentsStatus,
    List<String> addedParticipants = const [],
  }) {
    final validAllListingPairs = allReservations
        .whereType<Valid<ReservationPair>>()
        .map((v) => v.event)
        .where((p) => !p.cancelled)
        .toList();

    final allTradeReservations = ownReservations
        .whereType<Valid<ReservationPair>>()
        .expand((v) => [v.event.sellerReservation, v.event.buyerReservation])
        .whereType<Reservation>()
        .toList();

    final validTradeReservations = ownReservations
        .whereType<Valid<ReservationPair>>()
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
    final hasPayment = payments.isNotEmpty;

    final resolvedActions = <TradeAction>[];

    resolvedActions.addAll(
      PaymentActions.resolve(payments, paymentsStatus, role),
    );

    resolvedActions.addAll(
      ReservationActions.resolve(
        validTradeReservations,
        ownReservationsStatus,
        [...threadState.participantPubkeys, ...addedParticipants],
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
  required List<Validation<ReservationPair>> ownReservations,
  required ({bool isBlocked, String? reason}) overlapLock,
}) {
  if (ownReservations.any((v) => v is Invalid)) {
    return TradeAvailability.invalidReservation;
  }
  if (ownReservations.whereType<Valid<ReservationPair>>().any(
    (v) => v.event.cancelled,
  )) {
    return TradeAvailability.cancelled;
  }
  if (overlapLock.isBlocked) return TradeAvailability.unavailable;
  return TradeAvailability.available;
}

({bool isBlocked, String? reason}) resolveOverlapLock({
  required List<ReservationPair> allListingReservationPairs,
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
      DateTime.utc(value.year, value.month, value.day);

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

  return !(aEnd.isBefore(bStart) || bEnd.isBefore(aStart));
}
