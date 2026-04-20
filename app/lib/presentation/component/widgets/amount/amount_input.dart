import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/forms/amount_field_controller.dart';
import 'package:hostr/logic/forms/listing_price_field_controller.dart'
    show decimalsForDenomination;
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
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
    return value;
  }

  final value = trimTrailingZeros(format(true).format(amountAsDouble));
  return value;
}

/// Lazily-built resolver backed by [getIt<Hostr>] chain configs.
TokenDisplayResolver? _cachedResolver;

TokenDisplayResolver? get _resolver {
  if (_cachedResolver != null) return _cachedResolver;
  try {
    _cachedResolver = TokenDisplayResolver(
      getIt<Hostr>().evm.configuredChains.map((c) => c.config),
    );
  } catch (_) {
    // getIt not yet configured (e.g. during tests) — leave null.
  }
  return _cachedResolver;
}

/// Format a [TokenAmount] for display (on-chain amounts like escrow events).
///
/// Denomination is resolved automatically from the app's chain configuration
/// via [TokenDisplayResolver].  Falls back to BTC display for native tokens
/// and a raw decimal string for unrecognised ERC-20s.
String formatTokenAmount(TokenAmount amount, {bool exact = true}) {
  // Attempt config-based denomination lookup.
  final info = _resolver?.resolve(amount.token);
  if (info != null && info.denomination.isNotEmpty) {
    return formatAmount(
      amount.toDenominated(denomination: info.denomination),
      exact: exact,
    );
  }

  // Fallback: no resolver or unknown token — use token type heuristics.
  if (amount.token.isNative) {
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
    return value;
  }

  final value = trimTrailingZeros(format(true).format(amountAsDouble));
  return value;
}

String trimTrailingZeros(String value) {
  if (value.contains('.')) {
    value = value.replaceAll(RegExp(r'0*$'), '');
    value = value.replaceAll(RegExp(r'\.$'), '');
  }
  return value;
}

class AmountTapInput extends StatefulWidget {
  final AmountFieldController controller;
  final String? labelText;
  final String? hintText;
  final String? suffixText;
  final DenominatedAmount? min;
  final DenominatedAmount? max;
  final List<String> possibleDenominations;
  final bool enabled;
  final bool editable;
  final bool required;
  final TextStyle? textStyle;
  final AutovalidateMode autovalidateMode;
  final String? Function(DenominatedAmount? amount)? validator;
  final ValueChanged<DenominatedAmount?>? onChanged;

  const AmountTapInput({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.suffixText,
    this.min,
    this.max,
    this.possibleDenominations = const [],
    this.enabled = true,
    this.editable = true,
    this.required = false,
    this.textStyle,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.validator,
    this.onChanged,
  });

  @override
  State<AmountTapInput> createState() => _AmountTapInputState();
}

class _AmountTapInputState extends State<AmountTapInput> {
  final _fieldKey = GlobalKey<FormFieldState<DenominatedAmount>>();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AmountTapInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _fieldKey.currentState?.didChange(widget.controller.amount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _fieldKey.currentState?.didChange(widget.controller.amount);
      setState(() {});
    });
  }

  DenominatedAmount get _displayAmount =>
      widget.controller.amount ??
      DenominatedAmount.zero(
        widget.controller.denomination,
        widget.controller.decimals,
      );

  @override
  Widget build(BuildContext context) {
    return FormField<DenominatedAmount>(
      key: _fieldKey,
      initialValue: widget.controller.amount,
      enabled: widget.enabled,
      autovalidateMode: widget.autovalidateMode,
      validator: _validate,
      builder: (field) {
        final canEdit = widget.enabled && widget.editable;
        final textStyle =
            widget.textStyle ??
            Theme.of(context).textTheme.bodyLarge ??
            DefaultTextStyle.of(context).style;

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: canEdit ? () => _openEditor(context) : null,
          child: InputDecorator(
            isEmpty: false,
            decoration: InputDecoration(
              enabled: widget.enabled,
              labelText: widget.labelText,
              hintText: widget.hintText,
              suffixText: widget.suffixText,
              errorText: field.errorText,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatAmount(_displayAmount), style: textStyle),
                if (canEdit) ...[
                  Gap.horizontal.xs(),
                  Icon(
                    Icons.edit,
                    size: textStyle.fontSize ?? kIconSm,
                    color: textStyle.color,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final result = await AmountEditorBottomSheet.show(
      context,
      initialAmount: _displayAmount,
      minAmount: widget.min,
      maxAmount: widget.max,
      possibleDenominations: widget.possibleDenominations,
      onDenominationChanged: widget.controller.setDenomination,
    );

    if (result == null || !mounted) {
      return;
    }
    widget.controller.setValue(result);
    widget.onChanged?.call(widget.controller.amount);
  }

  String? _validate(DenominatedAmount? amount) {
    final effectiveAmount = widget.controller.amount ?? amount;
    final controllerError = widget.controller.validate(
      widget.controller.textController.text,
    );
    if (controllerError != null) {
      return controllerError;
    }
    if (widget.required &&
        (effectiveAmount == null || effectiveAmount.value <= BigInt.zero)) {
      return 'Enter a valid amount';
    }
    if (effectiveAmount != null &&
        widget.min != null &&
        effectiveAmount.value < widget.min!.value) {
      return 'Amount must be at least ${formatAmount(widget.min!)}';
    }
    if (effectiveAmount != null &&
        widget.max != null &&
        effectiveAmount.value > widget.max!.value) {
      return 'Amount must be at most ${formatAmount(widget.max!)}';
    }
    return widget.validator?.call(effectiveAmount);
  }
}

class AmountInputWidget extends FormField<DenominatedAmount> {
  final DenominatedAmount? min;
  final DenominatedAmount? max;

  /// Denominations the user may switch between (e.g. `['BTC', 'USD']`).
  ///
  /// When empty or single-element, the denomination selector is hidden
  /// and the widget behaves exactly as before.
  final List<String> possibleDenominations;

  /// Fired when the user taps a different denomination in the selector.
  ///
  /// The parent is responsible for rebuilding with new [initialValue],
  /// [min], and [max] all expressed in the new denomination.
  final ValueChanged<String>? onDenominationChanged;

  AmountInputWidget({
    super.key,
    initialValue,
    this.min,
    this.max,
    this.possibleDenominations = const [],
    this.onDenominationChanged,
  }) : super(
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
           final denominations = amountInput.possibleDenominations;
           final activeDenomination = field.value!.denomination;
           return Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Gap.vertical.xl(),
               if (denominations.length > 1)
                 Align(
                   alignment: Alignment.centerRight,
                   child: Padding(
                     padding: const EdgeInsets.only(right: 16),
                     child: _CurrencyCycleButton(
                       denominations: denominations,
                       activeDenomination: activeDenomination,
                       onCycle: (newDenom) {
                         final newDecimals = decimalsForDenomination(newDenom);
                         field.didChange(
                           DenominatedAmount.zero(newDenom, newDecimals),
                         );
                         amountInput.onDenominationChanged?.call(newDenom);
                       },
                     ),
                   ),
                 )
               else
                 Gap.vertical.xl(),
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
               Gap.vertical.xl(),
               Center(
                 child: ConstrainedBox(
                   constraints: const BoxConstraints(
                     maxWidth: kAppFormMaxWidth,
                   ),
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
                                 style: Theme.of(context)
                                     .textTheme
                                     .headlineSmall
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
  final List<String> possibleDenominations;
  final ValueChanged<String>? onDenominationChanged;

  const AmountEditorBottomSheet({
    super.key,
    required this.initialAmount,
    this.minAmount,
    this.maxAmount,
    this.possibleDenominations = const [],
    this.onDenominationChanged,
  });

  /// Shows the amount editor as a modal bottom sheet.
  /// Returns the selected [DenominatedAmount], or null if dismissed.
  static Future<DenominatedAmount?> show(
    BuildContext context, {
    required DenominatedAmount initialAmount,
    DenominatedAmount? minAmount,
    DenominatedAmount? maxAmount,
    List<String> possibleDenominations = const [],
    ValueChanged<String>? onDenominationChanged,
  }) {
    return showAppModal<DenominatedAmount>(
      context,
      builder: (_) => AmountEditorBottomSheet(
        initialAmount: initialAmount,
        minAmount: minAmount,
        maxAmount: maxAmount,
        possibleDenominations: possibleDenominations,
        onDenominationChanged: onDenominationChanged,
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
          possibleDenominations: widget.possibleDenominations,
          onDenominationChanged: widget.onDenominationChanged,
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

// ── Strike-style currency cycle button ────────────────────────────────────

/// A circular-arrow icon with the *next* currency's symbol inside.
class _CurrencyCycleButton extends StatelessWidget {
  final List<String> denominations;
  final String activeDenomination;
  final ValueChanged<String> onCycle;

  const _CurrencyCycleButton({
    required this.denominations,
    required this.activeDenomination,
    required this.onCycle,
  });

  static const _symbols = <String, String>{'BTC': '₿', 'USD': '\$', 'ETH': 'Ξ'};

  @override
  Widget build(BuildContext context) {
    final currentIndex = denominations.indexOf(activeDenomination);
    final nextIndex = (currentIndex + 1) % denominations.length;
    final nextDenom = denominations[nextIndex];
    final symbol = _symbols[nextDenom] ?? nextDenom;
    final theme = Theme.of(context);

    return IconButton(
      tooltip: 'Switch to $nextDenom',
      onPressed: () => onCycle(nextDenom),
      icon: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.sync_outlined,
              size: 38,
              color: theme.colorScheme.onSurfaceVariant,
              weight: 200,
              grade: 0.1,
            ),
            Text(
              symbol,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
