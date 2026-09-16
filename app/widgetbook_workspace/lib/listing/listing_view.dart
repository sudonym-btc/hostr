import 'package:marketplace_evm/marketplace_evm.dart';
import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:marketplace_models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

@widgetbook.UseCase(name: 'Body - date selected', type: ListingViewBody)
Widget listingViewBodyDateSelected(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: CustomPadding(
        child: ListingViewBody(
          listing: mockListings.first,
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
          verifiedGroupsStream: StreamWithStatus<Validation<OrderGroup>>(),
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
          listing: mockListings.first,
          selectedDateRange: null,
          isOwner: false,
          hostedByText: 'Hosted by',
          hostWidget: const Chip(label: Text('Hoster')),
          reviewsSummaryWidget: const Text(
            '4.8 · 12 reviews · 20 reservations',
          ),
          reviewsListWidget: const SizedBox.shrink(),
          verifiedGroupsStream: StreamWithStatus<Validation<OrderGroup>>(),
          hostKeyPair: null,
          onCancelBlockedReservation: (_) {},
          onBlockDates: () {},
        ),
      ),
    ),
  );
}
