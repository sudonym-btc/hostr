import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: AmountInput)
Widget defaultUseCase(BuildContext context) {
  return Align(alignment: Alignment.center, child: AmountInput());
}

@widgetbook.UseCase(name: 'Fixed Currency', type: AmountInput)
Widget fixedAmountUseCase(BuildContext context) {
  return Align(alignment: Alignment.center, child: AmountInput());
}

@widgetbook.UseCase(name: 'Currency chooser', type: AmountInput)
Widget currencyChooserAmountUseCase(BuildContext context) {
  return Align(alignment: Alignment.center, child: AmountInput());
}
