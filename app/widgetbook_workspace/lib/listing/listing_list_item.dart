import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

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
