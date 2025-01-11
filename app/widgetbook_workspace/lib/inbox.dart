import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Empty', type: InboxScreen)
Widget inboxEmpty(BuildContext context) {
  return InboxScreen();
}
