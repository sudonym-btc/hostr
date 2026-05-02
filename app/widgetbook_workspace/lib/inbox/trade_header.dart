import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

@widgetbook.UseCase(name: 'Trade header (knobs)', type: TradeHeaderView)
Widget tradeHeaderKnobs(BuildContext context) {
  final availability = context.knobs.object.dropdown<TradeAvailability>(
    label: 'Availability',
    initialOption: TradeAvailability.available,
    options: TradeAvailability.values,
    labelBuilder: (v) => v.name,
  );

  final listing = mockListings.first;
  final listingProfile = mockProfiles.firstWhere(
    (p) => p.pubKey == listing.pubKey,
    orElse: () => mockProfiles.first,
  );
  final start = DateTime.now();
  final end = DateTime.now().add(const Duration(days: 2));

  return Scaffold(
    body: SingleChildScrollView(
      child: TradeHeaderView(
        tradeState: TradeReady(
          listing: listing,
          sellerProfile: listingProfile,
          sellerEvmAddress: '0x0000000000000000000000000000000000000000',
          sellerPubkey: listing.pubKey,
          role: TradeRole.guest,
          tradeId: 'mock-trade-id',
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
          availability: availability,
          availabilityReason: availability != TradeAvailability.available
              ? 'This reservation is not available.'
              : null,
          streams: TradeStreams(
            paymentEvents: StreamWithStatus<PaymentEvent>(),
            reservationStream: StreamWithStatus<Validation<ReservationGroup>>(),
            transitionsStream: StreamWithStatus<ReservationTransition>(),
            subscriptionsLive: BehaviorSubject<bool>.seeded(false),
          ),
        ),
      ),
    ),
  );
}
