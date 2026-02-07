import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:intl/intl.dart';
import 'package:models/main.dart';

const buttons = [1, 2, 3, 4, 5, 6, 7, 8, 9, '.', 0, 'backspace'];

var format = (bool fiat) => NumberFormat.currency(
  locale: "en_US",
  name: null,
  symbol: '',
  decimalDigits: fiat ? 2 : 0,
);

var compactFormat = (bool fiat) => NumberFormat.compact(locale: "en_US");

String formatAmount(Amount amount, {exact = false}) {
  String prefix = '${amount.currency.prefix} ';
  var amountAsDouble =
      amount.value / BigInt.from(10).pow(amount.currency.decimals);

  if (amount.currency == Currency.BTC) {
    amountAsDouble = amount.value.toDouble();
  }

  final value = trimTrailingZeros(
    exact
        ? format(amount.currency == Currency.USD).format(amountAsDouble)
        : compactFormat(amount.currency == Currency.USD).format(amountAsDouble),
  );
  return '$prefix$value${amount.currency.suffix}';
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
            initialValue ?? Amount(currency: Currency.BTC, value: BigInt.zero),
        builder: (field) {
          final maxDecimals = field.value!.currency == Currency.BTC
              ? 8
              : field.value!.currency.decimals;
          return Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      style: TextStyle(fontSize: 34),
                      formatAmount(field.value!),
                    ),
                  ),
                ),
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
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
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
                                String currentValue = trimTrailingZeros(
                                  field.value!.toDecimalString(
                                    maxDecimals: maxDecimals,
                                  ),
                                );

                                if (buttons[index] is int) {
                                  if (currentValue == '0') {
                                    currentValue = '';
                                  }
                                  final newValue =
                                      currentValue + buttons[index].toString();
                                  field.didChange(
                                    Amount.fromDecimal(
                                      decimal: newValue,
                                      currency: field.value!.currency,
                                    ),
                                  );
                                  return;
                                }

                                if (buttons[index] == '.') {
                                  if (!currentValue.contains('.')) {
                                    final newValue = currentValue.isEmpty
                                        ? '0.'
                                        : '$currentValue.';
                                    field.didChange(
                                      Amount.fromDecimal(
                                        decimal: newValue,
                                        currency: field.value!.currency,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                if (buttons[index] == 'backspace') {
                                  if (currentValue.isNotEmpty) {
                                    final newValue = currentValue.substring(
                                      0,
                                      currentValue.length - 1,
                                    );
                                    field.didChange(
                                      Amount.fromDecimal(
                                        decimal: newValue.isEmpty
                                            ? '0'
                                            : newValue,
                                        currency: field.value!.currency,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: MaterialButton(
                                onPressed: null,
                                color: Colors.blue,
                                textColor: Colors.white,
                                padding: EdgeInsets.all(16),
                                shape: CircleBorder(),
                                child: buttonContent,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
