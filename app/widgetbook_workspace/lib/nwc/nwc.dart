import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: NostrWalletConnectWidget)
Widget nwc(BuildContext context) {
  return Scaffold(
      body: Align(
          alignment: Alignment.bottomCenter,
          child: NostrWalletConnectWidget()));
}
