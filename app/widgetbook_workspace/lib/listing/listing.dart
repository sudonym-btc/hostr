import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ListingScreen)
Widget listing(BuildContext context) {
  getIt<NostrService>().broadcast(event: MOCK_LISTINGS[0]);
  getIt<NostrService>().broadcast(event: MOCK_PROFILES[0]);
  return ListingScreen(
    a: MOCK_LISTINGS[0].anchor,
  );
}
