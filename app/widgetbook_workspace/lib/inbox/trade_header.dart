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
  final availability = context.knobs.list<TradeAvailability>(
    label: 'Availability',
    initialOption: TradeAvailability.available,
    options: TradeAvailability.values,
    labelBuilder: (v) => v.name,
  );

  final listing = MOCK_LISTINGS.first;
  final listingProfile = MOCK_PROFILES.firstWhere(
    (p) => p.pubKey == listing.pubKey,
    orElse: () => MOCK_PROFILES.first,
  );
  final start = DateTime.now();
  final end = DateTime.now().add(const Duration(days: 2));

  return Scaffold(
    body: SingleChildScrollView(
      child: TradeHeaderView(
        tradeState: TradeReady(
          listing: listing,
          hostProfile: listingProfile,
          hostPubKey: listing.pubKey,
          role: TradeRole.guest,
          tradeId: 'mock-trade-id',
          listingAnchor: listing.anchor ?? 'mock-anchor',
          start: start,
          end: end,
          amount: listing.prices.first.amount,
          stage: const NegotiationStage(
            reservationRequests: [],
            overlapLock: (isBlocked: false, reason: null),
          ),
          actions: const [],
          availability: availability,
          availabilityReason: availability != TradeAvailability.available
              ? 'This reservation is not available.'
              : null,
          streams: TradeStreams(
            paymentEvents: StreamWithStatus<PaymentEvent>(),
            reservationStream: StreamWithStatus<Validation<ReservationPair>>(),
            transitionsStream: StreamWithStatus<ReservationTransition>(),
            subscriptionsLive: BehaviorSubject<bool>.seeded(false),
          ),
        ),
      ),
    ),
  );
}
