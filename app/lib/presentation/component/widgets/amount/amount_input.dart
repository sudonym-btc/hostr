import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
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

/// Returns the amount expressed in satoshis for BTC-family tokens.
///
/// - Lightning BTC (8 decimals): value is already sats.
/// - Native RBTC (18 decimals): divides out the 10^10 factor.
BigInt _toSats(TokenAmount amount) {
  if (amount.token.decimals <= 8) return amount.value;
  final factor = BigInt.from(10).pow(amount.token.decimals - 8);
  return amount.value ~/ factor;
}

/// Format a [DenominatedAmount] for display (listing prices, negotiation amounts).
///
/// - BTC → `"₿ 50,000"` (integer sats)
/// - USD → `"$ 12.50"` (2-decimal fiat)
/// - Unknown → decimal string with no prefix
String formatAmount(DenominatedAmount amount, {bool exact = true}) {
  if (amount.isBtc) {
    const prefix = '₿ ';
    // Rescale to sats (8 decimals) — tBTC has 18 decimals, Lightning has 8.
    final sats = amount.decimals <= 8
        ? amount.value
        : amount.value ~/ BigInt.from(10).pow(amount.decimals - 8);
    final value = exact
        ? _commaFormat.format(sats.toInt())
        : compactFormat(false).format(sats.toInt());
    return '$prefix$value';
  }

  if (amount.isUsd) {
    final amountAsDouble = amount.value / BigInt.from(10).pow(amount.decimals);
    if (!exact) {
      return '\$ ${compactFormat(true).format(amountAsDouble)}';
    }
    return '\$ ${format(true).format(amountAsDouble)}';
  }

  if (amount.isEth) {
    const prefix = 'Ξ ';
    final amountAsDouble = amount.value / BigInt.from(10).pow(amount.decimals);
    if (!exact) {
      return '$prefix${compactFormat(true).format(amountAsDouble)}';
    }
    final formatted = trimTrailingZeros(amountAsDouble.toStringAsFixed(8));
    return '$prefix$formatted';
  }

  var amountAsDouble = amount.value / BigInt.from(10).pow(amount.decimals);

  if (!exact) {
    final value = compactFormat(true).format(amountAsDouble);
    return '$value';
  }

  final value = trimTrailingZeros(format(true).format(amountAsDouble));
  return '$value';
}

/// Format a [TokenAmount] for display (on-chain amounts like escrow events).
///
/// When [denomination] is provided (e.g. `"BTC"`, `"USD"`), the amount is
/// converted to a [DenominatedAmount] and formatted with the proper symbol.
/// Otherwise falls back to BTC display for Lightning/native tokens and a
/// raw decimal string for ERC-20s.
String formatTokenAmount(
  TokenAmount amount, {
  bool exact = true,
  String? denomination,
}) {
  if (denomination != null) {
    return formatAmount(
      amount.toDenominated(denomination: denomination),
      exact: exact,
    );
  }

  // Fallback: no denomination provided — use token type heuristics.
  if (amount.token.isLightning || amount.token.isNative) {
    const prefix = '₿ ';
    final sats = _toSats(amount).toInt();
    final value = exact
        ? _commaFormat.format(sats)
        : compactFormat(false).format(sats);
    return '$prefix$value';
  }

  var amountAsDouble =
      amount.value / BigInt.from(10).pow(amount.token.decimals);

  if (!exact) {
    final value = compactFormat(true).format(amountAsDouble);
    return '$value';
  }

  final value = trimTrailingZeros(format(true).format(amountAsDouble));
  return '$value';
}

String trimTrailingZeros(String value) {
  if (value.contains('.')) {
    value = value.replaceAll(RegExp(r'0*$'), '');
    value = value.replaceAll(RegExp(r'\.$'), '');
  }
  return value;
}

class AmountInputWidget extends FormField<DenominatedAmount> {
  final DenominatedAmount? min;
  final DenominatedAmount? max;

  AmountInputWidget({super.key, initialValue, this.min, this.max})
    : super(
        initialValue: initialValue ?? DenominatedAmount.zero('BTC', 8),
        builder: (field) {
          final amountInput = field.widget as AmountInputWidget;
          final isOutOfRange =
              (amountInput.min != null &&
                  field.value!.value < amountInput.min!.value) ||
              (amountInput.max != null &&
                  field.value!.value > amountInput.max!.value);
          final isBtc = field.value!.isBtc;
          final maxDecimals = isBtc ? 0 : field.value!.decimals;
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
                          style: Theme.of(field.context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  field.context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              Gap.vertical.custom(kSpace5),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kAppFormMaxWidth),
                  child: CustomPadding(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisExtent: 64,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            Widget buttonContent;
                            if (index < 11) {
                              buttonContent = Text(
                                buttons[index].toString(),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              );
                            } else if (index == 11) {
                              buttonContent = Icon(
                                Icons.backspace,
                                color: Theme.of(context).colorScheme.onSurface,
                              );
                            } else {
                              buttonContent =
                                  Container(); // Empty container for the last cell
                            }

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                // For BTC-family, we edit in sats (the display unit),
                                // so use the raw integer value directly.
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
                                  final DenominatedAmount newAmount;
                                  if (isBtc) {
                                    final parsed = BigInt.tryParse(newValue);
                                    if (parsed == null) return;
                                    newAmount = DenominatedAmount(
                                      value: parsed,
                                      denomination: field.value!.denomination,
                                      decimals: field.value!.decimals,
                                    );
                                  } else {
                                    newAmount = DenominatedAmount.fromDecimal(
                                      newValue,
                                      field.value!.denomination,
                                      field.value!.decimals,
                                    );
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
                                      DenominatedAmount.fromDecimal(
                                        newValue,
                                        field.value!.denomination,
                                        field.value!.decimals,
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
                                        DenominatedAmount(
                                          value: parsed,
                                          denomination:
                                              field.value!.denomination,
                                          decimals: field.value!.decimals,
                                        ),
                                      );
                                    } else {
                                      field.didChange(
                                        DenominatedAmount.fromDecimal(
                                          newValue.isEmpty ? '0' : newValue,
                                          field.value!.denomination,
                                          field.value!.decimals,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              child: AppSurface(
                                steps: 2,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(16),
                                child: Center(child: buttonContent),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

/// A bottom sheet that allows the user to edit an amount within an optional range.
class AmountEditorBottomSheet extends StatefulWidget {
  final DenominatedAmount initialAmount;
  final DenominatedAmount? minAmount;
  final DenominatedAmount? maxAmount;

  const AmountEditorBottomSheet({
    super.key,
    required this.initialAmount,
    this.minAmount,
    this.maxAmount,
  });

  /// Shows the amount editor as a modal bottom sheet.
  /// Returns the selected [DenominatedAmount], or null if dismissed.
  static Future<DenominatedAmount?> show(
    BuildContext context, {
    required DenominatedAmount initialAmount,
    DenominatedAmount? minAmount,
    DenominatedAmount? maxAmount,
  }) {
    return showAppModal<DenominatedAmount>(
      context,
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
  final _formFieldKey = GlobalKey<FormFieldState<DenominatedAmount>>();

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
