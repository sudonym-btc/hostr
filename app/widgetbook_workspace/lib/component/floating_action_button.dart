import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: FloatingActionButton)
Widget floatingActionButton(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: FloatingActionButton(child: Text('Sign in'), onPressed: () {}));
}

@widgetbook.UseCase(name: 'Icon', type: FloatingActionButton)
Widget floatingActionButtonIcon(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: FloatingActionButton.extended(
        label: Text('Sign in'),
        icon: Icon(Icons.arrow_forward),
        onPressed: () {},
      ));
}
