import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/presentation/reservation_published_popup_listener.dart';
import 'package:hostr/presentation/screens/shared/startup_gate.dart';
import 'package:hostr/presentation/signer_request_popup_listener.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

@widgetbook.UseCase(name: 'Trip booked', type: TripBookedPopupPage)
Widget tripBookedPopup(BuildContext context) {
  return TripBookedPopupView(
    tradeSummary: TradeHeaderView(
      tradeState: _mockBookedTrade(),
      showActions: false,
    ),
    onDone: () {},
  );
}

@widgetbook.UseCase(name: 'Bunker connect failure', type: BunkerRecoveryView)
Widget bunkerConnectFailure(BuildContext context) {
  return SizedBox.expand(
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: BunkerRecoveryView(
        state: const BunkerSessionRecoveryRequired(
          pubkey:
              '0000000000000000000000000000000000000000000000000000000000000000',
          message:
              'The remote signer did not respond. It may be offline, locked, or the session may have been ended.',
        ),
        onRetry: () async {},
        onSignOut: () async {},
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Awaiting bunker confirmation - commit',
  type: SignerRequestPopupPage,
)
Widget awaitingBunkerCommitConfirmation(BuildContext context) {
  return SignerRequestPopupPage(
    kind: kNostrKindCommitAuthorization,
    method: 'sign_event',
    createdAt: _waitingSince(),
    eventPreview:
        'Authorize payment commitment for the selected reservation terms.',
    onKeepWaiting: () {},
    onCancel: () {},
  );
}

@widgetbook.UseCase(
  name: 'Awaiting bunker confirmation - trade key',
  type: SignerRequestPopupPage,
)
Widget awaitingBunkerTradeKeyConfirmation(BuildContext context) {
  return SignerRequestPopupPage(
    kind: kNostrKindTradeKeyAuthorization,
    method: 'sign_event',
    createdAt: _waitingSince(),
    eventPreview: 'Authorize this trade key for the current reservation.',
    onKeepWaiting: () {},
    onCancel: () {},
  );
}

@widgetbook.UseCase(
  name: 'Awaiting bunker confirmation - reservation',
  type: SignerRequestPopupPage,
)
Widget awaitingBunkerReservationConfirmation(BuildContext context) {
  return SignerRequestPopupPage(
    kind: kNostrKindReservation,
    method: 'sign_event',
    createdAt: _waitingSince(),
    eventPreview:
        'Reservation update for Apr 25 - Apr 27 with the latest booking terms.',
    onKeepWaiting: () {},
    onCancel: () {},
  );
}

DateTime _waitingSince() => DateTime.now().subtract(const Duration(seconds: 8));

TradeReady _mockBookedTrade() {
  final scenario = mockThreadScenarios.first;
  final listing = scenario.listing;
  final listingProfile = mockProfiles.firstWhere(
    (p) => p.pubKey == listing.pubKey,
    orElse: () => mockProfiles.first,
  );
  final start = DateTime.now().add(const Duration(days: 7));
  final end = start.add(const Duration(days: 2));

  return TradeReady(
    listing: listing,
    sellerProfile: listingProfile,
    sellerEvmAddress: '0x0000000000000000000000000000000000000000',
    sellerPubkey: listing.pubKey,
    role: TradeRole.guest,
    tradeId: scenario.id,
    listingAnchor: listing.anchor ?? 'mock-anchor',
    start: start,
    end: end,
    amount: listing.prices.first.amount,
    stage: const NegotiationStage(
      reservationRequests: [],
      overlapLock: (isLoading: false, isBlocked: false, reason: null),
      policy: NegotiationPolicy(
        latestOffer: null,
        lastOfferByUs: null,
        lastOfferByThem: null,
        listingPrice: null,
        latestOfferSentByUs: false,
        latestOfferAcceptsPrevious: false,
        canPay: false,
        canCounter: false,
        counterMin: null,
        counterMax: null,
      ),
    ),
    actions: const [],
    availability: TradeAvailability.available,
    availabilityReason: null,
    streams: TradeStreams(
      paymentEvents: StreamWithStatus<PaymentEvent>(),
      reservationStream: StreamWithStatus<Validation<ReservationGroup>>(),
      transitionsStream: StreamWithStatus<ReservationTransition>(),
      subscriptionsLive: BehaviorSubject<bool>.seeded(true),
    ),
  );
}
