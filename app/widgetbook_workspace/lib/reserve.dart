import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:hostr/export.dart';

@widgetbook.UseCase(name: 'Default', type: Reserve)
Widget reserve(BuildContext context) {
  return Reserve(
    listing: MOCK_LISTINGS[0],
    dateRange: DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(Duration(days: 1)),
    ),
  );
}
