import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:models/main.dart';

@widgetbook.UseCase(name: 'Default', type: Reserve)
Widget reserve(BuildContext context) {
  return Align(
      alignment: Alignment.center, child: Reserve(listing: MOCK_LISTINGS[0]));
}
