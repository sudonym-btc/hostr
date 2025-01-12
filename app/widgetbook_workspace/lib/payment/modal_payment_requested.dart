import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Lightning Address Amount Fixed', type: FilledButton)
Widget amountFixed(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: FilledButton(child: Text('Sign in'), onPressed: () {}));
}

@widgetbook.UseCase(name: 'Lightning Address', type: FilledButton)
Widget lightningAddress(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: FilledButton(child: Text('Sign in'), onPressed: () {}));
}

@widgetbook.UseCase(name: 'Zap', type: FilledButton)
Widget zap(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: FilledButton.icon(
        label: Text('Sign in'),
        icon: Icon(Icons.arrow_forward),
        onPressed: () {},
      ));
}

@widgetbook.UseCase(name: 'Bolt11', type: FilledButton)
Widget bolt11(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: FilledButton.icon(
        label: Text('Sign in'),
        icon: Icon(Icons.arrow_forward),
        onPressed: () {},
      ));
}
