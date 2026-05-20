import 'package:models/main.dart';

import '../../../util/stream_status.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../trade.dart';
import 'trade_action_resolver.dart';

class ReviewActions {
  /// Returns [TradeAction.review] when the guest is eligible to leave a review:
  ///
  /// - The local user is the **guest**.
  /// - Orders have been fetched (stream is live/complete).
  /// - The order group has reached a confirmed committed state.
  /// - The order stay is over (end date in the past) or has a terminal
  ///   payment state (claimed / released / arbitrated).
  static List<TradeAction> resolve({
    required OrderGroup orderGroup,
    required StreamStatus orderStreamStatus,
    required List<PaymentEvent> payments,
    required TradeRole role,
    List<Review> myReviews = const [],
  }) {
    if (role != TradeRole.guest) return const [];

    final ordersFresh =
        orderStreamStatus is StreamStatusLive ||
        orderStreamStatus is StreamStatusQueryComplete;
    if (!ordersFresh) return const [];

    if (orderGroup.orders.isEmpty) return const [];
    if (!orderGroup.confirmedCommitted) return const [];

    final reviewWindowOpen =
        (orderGroup.end?.isBefore(DateTime.now().toUtc()) ?? false) ||
        payments.any(
          (event) =>
              event is PaymentClaimedEvent ||
              event is PaymentReleasedEvent ||
              event is PaymentArbitratedEvent,
        );
    if (!reviewWindowOpen) return const [];

    // Max one review per user per trade: check if we already left one
    // for any order in this group.
    final alreadyReviewed = myReviews.any((review) {
      return review.getFirstTag(kOrderRefTag) == orderGroup.tradeId;
    });
    if (alreadyReviewed) return const [];

    return [TradeAction.review];
  }
}
