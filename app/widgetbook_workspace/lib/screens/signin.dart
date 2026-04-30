import 'package:flutter/widgets.dart';
import 'package:hostr/presentation/screens/shared/signin/signin.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: SignInScreen)
Widget signInScreen(BuildContext context) {
  return const SignInScreen();
}
