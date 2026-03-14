import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/stream_status.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'actions/trade_action_resolver.dart';
import 'trade.dart';

sealed class TradeState {
  const TradeState();
}

class TradeInitialising extends TradeState {
  const TradeInitialising();
}

class TradeReady extends TradeState {
  final Listing listing;
  final ProfileMetadata? hostProfile;
  final String hostPubKey;
  final TradeRole role;
  final String tradeId;
  final String listingAnchor;
  final DateTime start;
  final DateTime end;
  final Amount? amount;
  final TradeStage stage;
  final List<TradeAction> actions;
  final TradeAvailability availability;
  final String? availabilityReason;
  final TradeStreams streams;

  const TradeReady({
    required this.listing,
    required this.hostProfile,
    required this.hostPubKey,
    required this.role,
    required this.tradeId,
    required this.listingAnchor,
    required this.start,
    required this.end,
    required this.amount,
    required this.stage,
    required this.actions,
    required this.availability,
    this.availabilityReason,
    required this.streams,
  });

  TradeReady copyWith({
    TradeStage? stage,
    List<TradeAction>? actions,
    TradeAvailability? availability,
    String? availabilityReason,
    Amount? amount,
  }) {
    return TradeReady(
      listing: listing,
      hostProfile: hostProfile,
      hostPubKey: hostPubKey,
      role: role,
      tradeId: tradeId,
      listingAnchor: listingAnchor,
      start: start,
      end: end,
      amount: amount ?? this.amount,
      stage: stage ?? this.stage,
      actions: actions ?? this.actions,
      availability: availability ?? this.availability,
      availabilityReason: availabilityReason ?? this.availabilityReason,
      streams: streams,
    );
  }
}

class TradeError extends TradeState {
  final String message;
  const TradeError(this.message);
}

sealed class TradeStage {
  const TradeStage();
}

class NegotiationPolicy {
  final Reservation? latestOffer;
  final Reservation? lastOfferByUs;
  final Reservation? lastOfferByThem;
  final Amount? listingPrice;
  final bool latestOfferSentByUs;
  final bool latestOfferAcceptsPrevious;
  final bool canPay;
  final bool canCounter;
  final Amount? counterMin;
  final Amount? counterMax;

  const NegotiationPolicy({
    required this.latestOffer,
    required this.lastOfferByUs,
    required this.lastOfferByThem,
    required this.listingPrice,
    required this.latestOfferSentByUs,
    required this.latestOfferAcceptsPrevious,
    required this.canPay,
    required this.canCounter,
    required this.counterMin,
    required this.counterMax,
  });
}

class NegotiationStage extends TradeStage {
  final List<Reservation> reservationRequests;
  final ({bool isBlocked, String? reason}) overlapLock;
  final NegotiationPolicy policy;

  const NegotiationStage({
    required this.reservationRequests,
    required this.overlapLock,
    required this.policy,
  });
}

class CommitStage extends TradeStage {
  final ReservationPair reservationPair;
  final List<PaymentEvent> payments;
  final List<ReservationTransition> transitions;

  const CommitStage({
    required this.reservationPair,
    required this.payments,
    required this.transitions,
  });
}

class TradeStreams {
  final StreamWithStatus<PaymentEvent> paymentEvents;
  final StreamWithStatus<Validation<ReservationPair>> reservationStream;
  final StreamWithStatus<ReservationTransition> transitionsStream;
  final ValueStream<bool> subscriptionsLive;

  const TradeStreams({
    required this.paymentEvents,
    required this.reservationStream,
    required this.transitionsStream,
    required this.subscriptionsLive,
  });
}
