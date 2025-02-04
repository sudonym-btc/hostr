import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ProfileChipWidget)
Widget listing(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: ProfileChipWidget(id: MOCK_PROFILES[0].pubkey));
}
