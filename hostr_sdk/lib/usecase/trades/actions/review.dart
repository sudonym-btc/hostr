import 'package:models/main.dart';

import '../../../util/stream_status.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../trade.dart';
import 'trade_action_resolver.dart';

class ReviewActions {
  /// Returns [TradeAction.review] when the guest is eligible to leave a review:
  ///
  /// - The local user is the **guest**.
  /// - Reservations have been fetched (stream is live/complete).
  /// - The reservation group has reached a confirmed committed state.
  /// - The reservation stay is over (end date in the past) or has a terminal
  ///   payment state (claimed / released / arbitrated).
  static List<TradeAction> resolve({
    required ReservationGroup reservationGroup,
    required StreamStatus reservationStreamStatus,
    required List<PaymentEvent> payments,
    required TradeRole role,
    List<Review> myReviews = const [],
  }) {
    if (role != TradeRole.guest) return const [];

    final reservationsFresh =
        reservationStreamStatus is StreamStatusLive ||
        reservationStreamStatus is StreamStatusQueryComplete;
    if (!reservationsFresh) return const [];

    if (reservationGroup.reservations.isEmpty) return const [];
    if (!reservationGroup.confirmedCommitted) return const [];

    final reviewWindowOpen =
        (reservationGroup.end?.isBefore(DateTime.now().toUtc()) ?? false) ||
        payments.any(
          (event) =>
              event is PaymentClaimedEvent ||
              event is PaymentReleasedEvent ||
              event is PaymentArbitratedEvent,
        );
    if (!reviewWindowOpen) return const [];

    // Max one review per user per trade: check if we already left one
    // for any reservation in this group.
    final alreadyReviewed = myReviews.any((review) {
      return review.getFirstTag(kReservationRefTag) == reservationGroup.tradeId;
    });
    if (alreadyReviewed) return const [];

    return [TradeAction.review];
  }
}
