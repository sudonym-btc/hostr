import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

@widgetbook.UseCase(name: 'Default', type: ListingListItemWidget)
Widget listing(BuildContext context) {
  return ListingListItemWidget(
    listing: MOCK_LISTINGS[0],
    dateRange: DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(Duration(days: 1)),
    ),
  );
}

@widgetbook.UseCase(name: 'Pure - date selected', type: ListingListItemView)
Widget listingPureDateSelected(BuildContext context) {
  return ListingListItemView(
    listing: MOCK_LISTINGS[0],
    showPrice: true,
    showFeedback: true,
    smallImage: false,
    showAvailability: true,
    availabilityWidget: Text(
      'Availability: Available',
      style: Theme.of(context).textTheme.bodySmall,
    ),
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Pure - no date selected', type: ListingListItemView)
Widget listingPureNoDateSelected(BuildContext context) {
  return ListingListItemView(
    listing: MOCK_LISTINGS[0],
    showPrice: true,
    showFeedback: true,
    smallImage: false,
    showAvailability: false,
    availabilityWidget: null,
    onTap: () {},
  );
}
