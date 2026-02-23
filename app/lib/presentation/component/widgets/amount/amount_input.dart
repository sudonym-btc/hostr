import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
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

final _commaFormat = NumberFormat('#,##0', 'en_US');

String formatAmount(Amount amount, {bool exact = true}) {
  String prefix = '${amount.currency.prefix} ';

  if (amount.currency == Currency.BTC) {
    final sats = amount.value.toInt();
    final value = exact
        ? _commaFormat.format(sats)
        : compactFormat(false).format(sats);
    return '$prefix$value${amount.currency.suffix}';
  }

  var amountAsDouble =
      amount.value / BigInt.from(10).pow(amount.currency.decimals);

  if (!exact) {
    final value = compactFormat(true).format(amountAsDouble);
    return '$prefix$value${amount.currency.suffix}';
  }

  final value = trimTrailingZeros(
    format(amount.currency == Currency.USD).format(amountAsDouble),
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
  final Amount? min;
  final Amount? max;

  AmountInputWidget({super.key, initialValue, this.min, this.max})
    : super(
        initialValue:
            initialValue ?? Amount(currency: Currency.BTC, value: BigInt.zero),
        builder: (field) {
          final amountInput = field.widget as AmountInputWidget;
          final isOutOfRange =
              (amountInput.min != null &&
                  field.value!.value < amountInput.min!.value) ||
              (amountInput.max != null &&
                  field.value!.value > amountInput.max!.value);
          final maxDecimals = field.value!.currency == Currency.BTC
              ? 8
              : field.value!.currency.decimals;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gap.vertical.custom(kSpace8),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatAmount(field.value!),
                      style: Theme.of(field.context).textTheme.displayMedium!
                          .copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOutOfRange
                                ? Theme.of(field.context).colorScheme.error
                                : null,
                          ),
                    ),
                    if (amountInput.min != null || amountInput.max != null)
                      CustomPadding.only(
                        top: kSpace1,
                        child: Text(
                          '${amountInput.min != null ? formatAmount(amountInput.min!) : '0'} — ${amountInput.max != null ? formatAmount(amountInput.max!) : '∞'}',
                          style: Theme.of(
                            field.context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              Gap.vertical.custom(kSpace5),
              CustomPadding(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisExtent: 64,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        Widget buttonContent;
                        if (index < 11) {
                          buttonContent = Text(
                            buttons[index].toString(),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.white),
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
                            // For BTC, we edit in sats (the display unit),
                            // so use the raw integer value directly.
                            final isBtc = field.value!.currency == Currency.BTC;
                            String currentValue;
                            if (isBtc) {
                              currentValue = field.value!.value.toString();
                            } else {
                              currentValue = field.value!.toDecimalString(
                                maxDecimals: maxDecimals,
                              );
                              // Only trim trailing zeros after the decimal point
                              if (currentValue.contains('.')) {
                                currentValue = currentValue.replaceAll(
                                  RegExp(r'0*$'),
                                  '',
                                );
                                currentValue = currentValue.replaceAll(
                                  RegExp(r'\.$'),
                                  '',
                                );
                              }
                            }

                            if (buttons[index] is int) {
                              if (currentValue == '0') {
                                currentValue = '';
                              }
                              final newValue =
                                  currentValue + buttons[index].toString();
                              final Amount newAmount;
                              if (isBtc) {
                                final parsed = BigInt.tryParse(newValue);
                                if (parsed == null) return;
                                newAmount = Amount(
                                  value: parsed,
                                  currency: field.value!.currency,
                                );
                              } else {
                                newAmount = Amount.fromDecimal(
                                  decimal: newValue,
                                  currency: field.value!.currency,
                                );
                              }
                              if (amountInput.max != null &&
                                  newAmount.value > amountInput.max!.value) {
                                return;
                              }
                              field.didChange(newAmount);
                              return;
                            }

                            if (buttons[index] == '.') {
                              if (isBtc) return; // no decimals for sats
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
                                if (isBtc) {
                                  final parsed = newValue.isEmpty
                                      ? BigInt.zero
                                      : (BigInt.tryParse(newValue) ??
                                            BigInt.zero);
                                  field.didChange(
                                    Amount(
                                      value: parsed,
                                      currency: field.value!.currency,
                                    ),
                                  );
                                } else {
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
            ],
          );
        },
      );
}

/// A bottom sheet that allows the user to edit an amount within an optional range.
class AmountEditorBottomSheet extends StatefulWidget {
  final Amount initialAmount;
  final Amount? minAmount;
  final Amount? maxAmount;

  const AmountEditorBottomSheet({
    super.key,
    required this.initialAmount,
    this.minAmount,
    this.maxAmount,
  });

  /// Shows the amount editor as a modal bottom sheet.
  /// Returns the selected [Amount], or null if dismissed.
  static Future<Amount?> show(
    BuildContext context, {
    required Amount initialAmount,
    Amount? minAmount,
    Amount? maxAmount,
  }) {
    return showModalBottomSheet<Amount>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AmountEditorBottomSheet(
        initialAmount: initialAmount,
        minAmount: minAmount,
        maxAmount: maxAmount,
      ),
    );
  }

  @override
  State<AmountEditorBottomSheet> createState() =>
      _AmountEditorBottomSheetState();
}

class _AmountEditorBottomSheetState extends State<AmountEditorBottomSheet> {
  final _formFieldKey = GlobalKey<FormFieldState<Amount>>();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AmountInputWidget(
          key: _formFieldKey,
          initialValue: widget.initialAmount,
          min: widget.minAmount,
          max: widget.maxAmount,
        ),
        SafeArea(
          top: false,
          child: CustomPadding(
            top: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () {
                    final amount =
                        _formFieldKey.currentState?.value ??
                        widget.initialAmount;
                    final isValid =
                        (widget.minAmount == null ||
                            amount.value >= widget.minAmount!.value) &&
                        (widget.maxAmount == null ||
                            amount.value <= widget.maxAmount!.value);
                    if (isValid) {
                      Navigator.of(context).pop(amount);
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.done),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
