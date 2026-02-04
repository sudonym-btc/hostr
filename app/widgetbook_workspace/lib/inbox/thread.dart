import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ThreadScreen)
Widget thread(BuildContext context) {
  context.knobs.boolean(label: 'test');
  // BlocProvider.of<GlobalGiftWrapCubit>(context)
  // .addItem(MOCK_GUEST_RESERVATION_REQUEST[0]);
  return ThreadScreen(anchor: '1');
}
