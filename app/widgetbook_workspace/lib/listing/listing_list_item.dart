import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr/presentation/component/providers/nostr/listing_dependencies.provider.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

StreamWithStatus<Validation<T>> _emptyValidatedStream<T>() {
  final stream = StreamWithStatus<Validation<T>>();
  return stream;
}

StreamWithStatus<List<Validation<T>>> _emptyValidatedSnapshotStream<T>() {
  final stream = StreamWithStatus<List<Validation<T>>>();
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
  final dependencies = ListingDependencies(
    listing: MOCK_LISTINGS[0],
    verifiedReviews: _emptyValidatedStream<Review>(),
    verifiedReservationPairs: _emptyValidatedSnapshotStream<ReservationPair>(),
  );

  return ListingListItemView(
    dependencies: dependencies,
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
  final dependencies = ListingDependencies(
    listing: MOCK_LISTINGS[0],
    verifiedReviews: _emptyValidatedStream<Review>(),
    verifiedReservationPairs: _emptyValidatedSnapshotStream<ReservationPair>(),
  );

  return ListingListItemView(
    dependencies: dependencies,
    showPrice: true,
    showFeedback: true,
    smallImage: false,
    showAvailability: false,
    availabilityWidget: null,
    onTap: () {},
  );
}
