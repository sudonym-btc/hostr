import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ProfileChip)
Widget listing(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: ProfileChip(id: MOCK_PROFILES[0].id!));
}
