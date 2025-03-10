import 'package:flutter/material.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:intl/intl.dart';
import 'package:models/main.dart';

const buttons = [
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  '.',
  0,
  'backspace',
];

var format = (bool fiat) => NumberFormat.currency(
    locale: "en_US", name: null, symbol: '', decimalDigits: fiat ? 2 : 0);

var compactFormat = (bool fiat) => NumberFormat.compact(locale: "en_US");

formatAmount(Amount amount, {exact = false}) {
  String prefix =
      amount.currency.prefix == '' ? '' : '${amount.currency.prefix} ';
  var f = exact
      ? format(amount.currency != Currency.BTC)
      : compactFormat(amount.currency != Currency.BTC);
  var val = amount.currency != Currency.BTC
      ? amount.value
      : amount.value * btcSatoshiFactor;
  return '$prefix${f.format(val)}${amount.currency.suffix}';
}

String trimTrailingZeros(String value) {
  if (value.contains('.')) {
    value = value.replaceAll(RegExp(r'0*$'), '');
    value = value.replaceAll(RegExp(r'\.$'), '');
  }
  return value;
}

class AmountInputWidget extends FormField<Amount> {
  final List<Currency> currencies = Currency.values;
  final Currency? outputCurrency = null;
  final Amount? min = null;
  final Amount? max = null;

  AmountInputWidget({super.key, initialValue})
      : super(
          initialValue:
              initialValue ?? Amount(currency: Currency.BTC, value: 0),
          builder: (field) {
            return Expanded(
                child: Column(
              children: [
                Expanded(
                    flex: 1,
                    child: Center(
                        child: Text(
                            style: TextStyle(fontSize: 34),
                            formatAmount(field.value!)))),
                Expanded(
                    flex: 1,
                    child: CustomPadding.vertical(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2,
                            ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              Widget buttonContent;
                              if (index < 11) {
                                buttonContent = Text(
                                  buttons[index].toString(),
                                  style: TextStyle(
                                      fontSize: 24, color: Colors.white),
                                );
                              } else if (index == 11) {
                                buttonContent = Icon(
                                  Icons.backspace,
                                  color: Colors.white,
                                );
                              } else {
                                buttonContent =
                                    Container(); // Empty container for the last cell
                              }

                              return GestureDetector(
                                onTap: () {
                                  print(index);
                                  print(
                                      '${field.value!.value.toString()}${buttons[index]}');
                                  if (buttons[index] is int) {
                                    String stringVal = trimTrailingZeros(
                                        field.value!.value.toString());
                                    String newValue =
                                        stringVal + buttons[index].toString();
                                    print('new value: $newValue');

                                    field.didChange(Amount(
                                      currency: field.value!.currency,
                                      value: double.parse(newValue),
                                    ));
                                  }
                                  if (buttons[index] == 'backspace') {
                                    String currentValue =
                                        field.value!.value.toString();
                                    if (currentValue.isNotEmpty) {
                                      String newValue = currentValue.substring(
                                          0, currentValue.length - 1);
                                      print('new value: $newValue');
                                      field.didChange(Amount(
                                        currency: field.value!.currency,
                                        value: double.tryParse(newValue) ?? 0,
                                      ));
                                    }
                                  }
                                },
                                child: MaterialButton(
                                  onPressed: null,
                                  color: Colors.blue,
                                  textColor: Colors.white,
                                  child: buttonContent,
                                  padding: EdgeInsets.all(16),
                                  shape: CircleBorder(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ))
              ],
            ));
          },
        );
}
