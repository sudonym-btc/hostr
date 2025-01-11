import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ConversationScreen)
Widget conversation(BuildContext context) {
  return ConversationScreen(id: '1');
}
