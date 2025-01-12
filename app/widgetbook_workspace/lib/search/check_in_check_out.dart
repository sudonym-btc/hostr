import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: DateRangeButtons)
Widget defaultUseCase(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: DateRangeButtons(
        selectedDateRange: DateTimeRange(
            start: DateTime.now(), end: DateTime.now().add(Duration(days: 1))),
      ));
}
