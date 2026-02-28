import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

ValidatedStreamWithStatus<T> _emptyValidatedStream<T>() {
  final stream = ValidatedStreamWithStatus<T>();
  stream.setSnapshot(const []);
  return stream;
}

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
  final verifiedReviews = _emptyValidatedStream<Review>();
  final verifiedReservationPairs =
      _emptyValidatedStream<ReservationPairStatus>();

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
    verifiedReviews: verifiedReviews,
    verifiedReservationPairs: verifiedReservationPairs,
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Pure - no date selected', type: ListingListItemView)
Widget listingPureNoDateSelected(BuildContext context) {
  final verifiedReviews = _emptyValidatedStream<Review>();
  final verifiedReservationPairs =
      _emptyValidatedStream<ReservationPairStatus>();

  return ListingListItemView(
    listing: MOCK_LISTINGS[0],
    showPrice: true,
    showFeedback: true,
    smallImage: false,
    showAvailability: false,
    availabilityWidget: null,
    verifiedReviews: verifiedReviews,
    verifiedReservationPairs: verifiedReservationPairs,
    onTap: () {},
  );
}
