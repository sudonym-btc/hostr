import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: AmountInputWidget)
Widget defaultUseCase(BuildContext context) {
  return Align(alignment: Alignment.center, child: AmountInputWidget());
}

@widgetbook.UseCase(name: 'Fixed Currency', type: AmountInputWidget)
Widget fixedAmountUseCase(BuildContext context) {
  return Align(alignment: Alignment.center, child: AmountInputWidget());
}

@widgetbook.UseCase(name: 'Currency chooser', type: AmountInputWidget)
Widget currencyChooserAmountUseCase(BuildContext context) {
  return Align(alignment: Alignment.center, child: AmountInputWidget());
}
