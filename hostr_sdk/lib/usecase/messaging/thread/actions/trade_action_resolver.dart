import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/reservation_request.dart';
import 'package:hostr_sdk/usecase/messaging/thread/trade_state.dart';
import 'package:models/main.dart';

import 'payment.dart';
import 'reservation.dart';

// enum ThreadHeaderSource { reservation, reservationRequest, listing }

enum ThreadPartyRole { host, guest }

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

class TradeResolution {
  final ThreadPartyRole? role;
  final List<TradeAction> actions;
  final bool isBlocked;
  final String? blockedReason;

  const TradeResolution({
    this.role,
    required this.actions,
    required this.isBlocked,
    required this.blockedReason,
  });
}

class TradeActionResolver {
  static TradeResolution resolve({
    required ThreadState threadState,
    required TradeState tradeState,
    required TradeSubscriptions subscriptions,
    required String ourPubkey,
  }) {
    final listing = tradeState.listing;
    if (listing == null) {
      return const TradeResolution(
        role: null,
        actions: [],
        isBlocked: false,
        blockedReason: null,
      );
    }
    final role = getRole(hostPubkey: listing.pubKey, ourPubkey: ourPubkey);

    final overlapLock = resolveOverlapLock(
      ourPubkey: ourPubkey,
      allListingReservations: subscriptions.allReservationsStream!.list.value,
      startDate: tradeState.start,
      endDate: tradeState.end,
      salt: tradeState.salt,
    );

    final actions = <TradeAction>[];

    actions.addAll(
      PaymentActions.resolve(
        subscriptions.paymentEvents!.list.value,
        subscriptions.paymentEvents!.status.value,
        role,
        overlapLock.isBlocked,
      ),
    );

    actions.addAll(
      ReservationActions.resolve(
        subscriptions.reservationStream!.list.value,
        subscriptions.reservationStream!.status.value,
        listing,
        [
          ...threadState.participantPubkeys,
          // ...threadState.addedParticipants,
        ],
        role,
      ),
    );

    // Only if we don't have a reservation yet, we can send reservation requests
    if (subscriptions.reservationStream!.status.value is StreamStatusLive &&
        subscriptions.reservationStream!.list.value.isEmpty) {
      actions.addAll(
        ReservationRequestActions.resolve(
          threadState.reservationRequests,
          listing,
          ourPubkey,
          role,
        ),
      );
    }
    return TradeResolution(
      role: role,
      actions: actions,
      isBlocked: overlapLock.isBlocked,
      blockedReason: overlapLock.reason,
    );
  }
}

ThreadPartyRole getRole({
  required String hostPubkey,
  required String ourPubkey,
}) {
  return hostPubkey == ourPubkey ? ThreadPartyRole.host : ThreadPartyRole.guest;
}

({bool isBlocked, String? reason}) resolveOverlapLock({
  required List<Reservation> allListingReservations,
  required DateTime startDate,
  required DateTime endDate,
  required String salt,
  required String ourPubkey,
}) {
  final ourCommitment = ParticipationProof.computeCommitmentHash(
    ourPubkey,
    salt,
  );

  final overlapsOtherCommitment = allListingReservations.any((reservation) {
    if (reservation.parsedContent.cancelled) {
      return false;
    }
    if (!_overlapsRange(
      startA: startDate,
      endA: endDate,
      startB: reservation.parsedContent.start,
      endB: reservation.parsedContent.end,
    )) {
      return false;
    }

    return reservation.parsedTags.commitmentHash != ourCommitment;
  });

  if (!overlapsOtherCommitment) {
    return (isBlocked: false, reason: null);
  }

  return (
    isBlocked: true,
    reason: 'Dates overlap with a reservation for a different guest.',
  );
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
