import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ListingScreen)
Widget listing(BuildContext context) {
  return ListingScreen(
    a: MOCK_LISTINGS[0].getTags('a').first.first,
  );
}
