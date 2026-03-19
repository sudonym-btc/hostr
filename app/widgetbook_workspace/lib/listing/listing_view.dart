import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

@widgetbook.UseCase(name: 'Body - date selected', type: ListingViewBody)
Widget listingViewBodyDateSelected(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: CustomPadding(
        child: ListingViewBody(
          listing: MOCK_LISTINGS.first,
          selectedDateRange: DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 2)),
          ),
          isOwner: true,
          hostedByText: 'Hosted by',
          hostWidget: const Chip(label: Text('Hoster')),
          reviewsSummaryWidget: const Text(
            '4.8 · 12 reviews · 20 reservations',
          ),
          reviewsListWidget: const SizedBox.shrink(),
          verifiedPairsStream:
              StreamWithStatus<List<Validation<ReservationPair>>>(),
          hostKeyPair: null,
          onCancelBlockedReservation: (_) {},
          onBlockDates: () {},
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Body - no date selected', type: ListingViewBody)
Widget listingViewBodyNoDateSelected(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: CustomPadding(
        child: ListingViewBody(
          listing: MOCK_LISTINGS.first,
          selectedDateRange: null,
          isOwner: false,
          hostedByText: 'Hosted by',
          hostWidget: const Chip(label: Text('Hoster')),
          reviewsSummaryWidget: const Text(
            '4.8 · 12 reviews · 20 reservations',
          ),
          reviewsListWidget: const SizedBox.shrink(),
          verifiedPairsStream:
              StreamWithStatus<List<Validation<ReservationPair>>>(),
          hostKeyPair: null,
          onCancelBlockedReservation: (_) {},
          onBlockDates: () {},
        ),
      ),
    ),
  );
}
