import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: FilledButton)
Widget primaryButton(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: FilledButton(child: Text('Sign in'), onPressed: () {}));
}

@widgetbook.UseCase(name: 'Icon', type: FilledButton)
Widget primaryButtonIcon(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: FilledButton.icon(
        label: Text('Sign in'),
        icon: Icon(Icons.arrow_forward),
        onPressed: () {},
      ));
}
