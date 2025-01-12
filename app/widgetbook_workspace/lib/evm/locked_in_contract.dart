import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'defaultUseCase', type: FilledButton)
Widget lockedInContract(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: FilledButton(child: Text('Sign in'), onPressed: () {}));
}
