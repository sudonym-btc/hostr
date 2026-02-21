import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: SearchBoxWidget)
Widget defaultUseCase(BuildContext context) {
  return Align(
    alignment: Alignment.center,
    child: SearchBoxWidget(
      filterState: FilterState(location: 'France'),
      dateRangeState: DateRangeState(
        DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now().add(Duration(days: 1)),
        ),
      ),
    ),
  );
}
