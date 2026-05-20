import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  testWidgets('TradeHeaderView tolerates negotiation state before requests', (
    tester,
  ) async {
    final listing = Listing.create(
      pubKey: MockKeys.hoster.publicKey,
      dTag: 'listing-empty-negotiation',
      title: 'Test stay',
      description: 'desc',
      images: const [],
      price: [
        Price(
          amount: DenominatedAmount(
            value: BigInt.from(100000),
            denomination: 'BTC',
            decimals: 8,
          ),
          frequency: Frequency.daily,
        ),
      ],
      location: 'test',
      type: ListingType.house,
      specifications: Specifications(),
      negotiable: true,
    );
    final subscriptionsLive = BehaviorSubject<bool>.seeded(true);
    addTearDown(subscriptionsLive.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TradeHeaderView(
            showImages: false,
            tradeState: TradeReady(
              listing: listing,
              sellerProfile: null,
              sellerEvmAddress: null,
              sellerPubkey: MockKeys.hoster.publicKey,
              role: TradeRole.guest,
              tradeId: 'trade-empty-negotiation',
              listingAnchor: listing.anchor!,
              start: null,
              end: null,
              amount: null,
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
              streams: TradeStreams(
                paymentEvents: StreamWithStatus<PaymentEvent>(),
                reservationStream:
                    StreamWithStatus<Validation<ReservationGroup>>(),
                transitionsStream: StreamWithStatus<ReservationTransition>(),
                subscriptionsLive: subscriptionsLive,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Test stay'), findsOneWidget);
    expect(find.text('Amount pending'), findsNothing);
  });

  testWidgets(
    'TradeHeaderView hides negotiation controls when payment exists',
    (tester) async {
      final listing = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-paid-negotiation',
        title: 'Paid stay',
        description: 'desc',
        images: const [],
        price: [
          Price(
            amount: DenominatedAmount(
              value: BigInt.from(100000),
              denomination: 'BTC',
              decimals: 8,
            ),
            frequency: Frequency.daily,
          ),
        ],
        location: 'test',
        type: ListingType.house,
        specifications: Specifications(),
        negotiable: true,
      );
      final reservation = Reservation.create(
        pubKey: MockKeys.guest.publicKey,
        dTag: 'trade-paid-negotiation',
        listingAnchor: listing.anchor!,
      );
      final paymentEvents = StreamWithStatus<PaymentEvent>();
      final subscriptionsLive = BehaviorSubject<bool>.seeded(true);
      addTearDown(paymentEvents.close);
      addTearDown(subscriptionsLive.close);
      paymentEvents.add(
        PaymentReleasedEvent(tradeId: 'trade-paid-negotiation'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TradeHeaderView(
              showImages: false,
              tradeState: TradeReady(
                listing: listing,
                sellerProfile: null,
                sellerEvmAddress: null,
                sellerPubkey: MockKeys.hoster.publicKey,
                role: TradeRole.guest,
                tradeId: 'trade-paid-negotiation',
                listingAnchor: listing.anchor!,
                start: null,
                end: null,
                amount: null,
                stage: NegotiationStage(
                  reservationRequests: [reservation],
                  overlapLock: (
                    isLoading: false,
                    isBlocked: false,
                    reason: null,
                  ),
                  policy: const NegotiationPolicy(
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
                streams: TradeStreams(
                  paymentEvents: paymentEvents,
                  reservationStream:
                      StreamWithStatus<Validation<ReservationGroup>>(),
                  transitionsStream: StreamWithStatus<ReservationTransition>(),
                  subscriptionsLive: subscriptionsLive,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Amount pending'), findsNothing);
    },
  );
}
