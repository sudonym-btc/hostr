import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:models/stubs/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

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
          blockedReservations: [MOCK_RESERVATIONS.first],
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
          blockedReservations: const [],
          onCancelBlockedReservation: (_) {},
          onBlockDates: () {},
        ),
      ),
    ),
  );
}
