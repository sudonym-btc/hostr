import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../../../util/main.dart';
import '../../auth/auth.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../reservation_pairs/reservation_pairs.dart';
import '../user_subscriptions.dart';
import 'thread.dart';

/// Per-trade subscription layer that **filters** the shared
/// [UserSubscriptions] streams instead of opening its own Nostr / EVM
/// connections.
///
/// The only stream that still opens a dedicated subscription is
/// [listingReservationsStream], because it queries all reservations for a
/// **listing** (by anchor) rather than the user's own trades.
@injectable
class TradeSubscriptions {
  final Auth auth;
  final Thread thread;
  final CustomLogger logger;
  final ReservationPairs reservationPairs;
  final UserSubscriptions userSubscriptions;

  TradeSubscriptions({
    @factoryParam required this.thread,
    required this.auth,
    required this.logger,
    required this.reservationPairs,
    required this.userSubscriptions,
  });

  final List<StreamSubscription> _subscriptions = [];
  final List<Future<void> Function()> _ownedStreams = [];
  bool _started = false;

  /// Our trade's reservation pair, validated. Derived from the shared
  /// [UserSubscriptions.allMyReservations$] filtered by trade ID.
  StreamWithStatus<Validation<ReservationPairStatus>>? reservationStream;

  /// All reservation pairs for the **listing** (needed by
  /// [TradeActionResolver] to check availability across trades).
  /// This is the only stream that opens its own Nostr subscription.
  StreamWithStatus<Validation<ReservationPairStatus>>?
  listingReservationsStream;

  /// Reviews authored by the current user for this listing.
  StreamWithStatus<Review>? myReviewsStream;

  /// Payment events (zaps + escrow) for this trade.
  StreamWithStatus<PaymentEvent>? paymentEvents;

  /// Reservation transitions for this trade.
  StreamWithStatus<ReservationTransition>? transitionsStream;

  /// Emits `true` once every required subscription has reached
  /// [StreamStatusLive], `false` at all other times (including after [stop]).
  final BehaviorSubject<bool> _isLive = BehaviorSubject.seeded(false);
  ValueStream<bool> get isLive => _isLive;

  void start({required String tradeId, required String listingAnchor}) {
    if (_started) return;
    _started = true;

    logger.d('Starting trade subscriptions for trade $tradeId');

    // ── Listing-level reservations (own subscription) ─────────────────
    listingReservationsStream = reservationPairs.subscribeVerified(
      listingAnchor: listingAnchor,
      forceValidatePredicate: (pair) {
        final pairTradeId =
            pair.sellerReservation?.getDtag() ??
            pair.buyerReservation?.getDtag();
        return pairTradeId == tradeId;
      },
    );
    _ownedStreams.add(listingReservationsStream!.close);

    // ── Trade-level reservations (filtered from UserSubscriptions) ────
    reservationStream = userSubscriptions.allMyReservationPairs$.where(
      (item) => item.event.tradeId == tradeId,
      closeInner: false,
    );
    _ownedStreams.add(reservationStream!.close);

    // ── Reviews (filtered from UserSubscriptions) ─────────────────────
    myReviewsStream = userSubscriptions.myReviews$.where(
      (review) => review.parsedTags.listingAnchor == listingAnchor,
      closeInner: false,
    );
    _ownedStreams.add(myReviewsStream!.close);

    // ── Transitions (filtered from UserSubscriptions) ─────────────────
    transitionsStream = userSubscriptions.allTransitions$.stream.where(
      (t) => t.parsedTags.tradeId == tradeId,
      closeInner: false,
    );
    _ownedStreams.add(transitionsStream!.close);

    // ── Payment events (filtered from UserSubscriptions) ──────────────
    paymentEvents = userSubscriptions.paymentEvents$.where(
      (event) => event.tradeId == tradeId,
      closeInner: false,
    );
    _ownedStreams.add(paymentEvents!.close);

    // ── Liveness ──────────────────────────────────────────────────────
    _subscriptions.add(
      Rx.combineLatest([
        listingReservationsStream!.status,
        reservationStream!.status,
        myReviewsStream!.status,
        transitionsStream!.status,
      ], (statuses) => statuses.every((s) => s is StreamStatusLive)).listen((
        allLive,
      ) {
        if (allLive && !(_isLive.value)) _isLive.add(true);
      }),
    );
  }

  // ── Lifecycle ───────────────────────────────────────────────────────

  Future<void> stop() async {
    if (!_started) return;
    _started = false;

    logger.d('Stopping trade subscriptions');

    for (final sub in _subscriptions) await sub.cancel();
    _subscriptions.clear();

    for (final close in _ownedStreams) await close();
    _ownedStreams.clear();

    listingReservationsStream = null;
    reservationStream = null;
    myReviewsStream = null;
    paymentEvents = null;
    transitionsStream = null;
    _isLive.add(false);
  }

  Future<void> close() async {
    await stop();
    await _isLive.close();
  }
}
