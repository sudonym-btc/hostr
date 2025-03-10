import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:models/main.dart';

@widgetbook.UseCase(name: 'Default', type: ListingScreen)
Widget listing(BuildContext context) {
  getIt<NostrService>().broadcast(event: MOCK_LISTINGS[0].nip01Event);
  getIt<NostrService>()
      .broadcast(event: MOCK_PROFILES[0]..sign(MockKeys.hoster.privateKey!));
  return ListingScreen(
    a: MOCK_LISTINGS[0].anchor,
  );
}
