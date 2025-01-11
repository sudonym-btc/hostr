import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ConversationScreen)
Widget conversation(BuildContext context) {
  return ConversationScreen(id: 'abc');
}
