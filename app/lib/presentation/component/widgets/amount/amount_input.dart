import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart'
    hide
        amountIsAboveLimit,
        amountIsBelowLimit,
        amountIsWithinLimits,
        compactFormat,
        comparableAmountLimit,
        format,
        formatAmount,
        formatTokenAmount,
        highestComparableAmount,
        lowestComparableAmount,
        trimTrailingZeros;
import 'package:hostr/logic/forms/amount_field_controller.dart';
import 'package:hostr/logic/forms/listing_price_field_controller.dart'
    show decimalsForDenomination;
import 'package:hostr/presentation/component/widgets/amount/amount_formatting.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:models/main.dart';

export 'amount_formatting.dart';

const buttons = [1, 2, 3, 4, 5, 6, 7, 8, 9, '.', 0, 'backspace'];

class AmountTapInput extends StatefulWidget {
  final AmountFieldController controller;
  final String? labelText;
  final String? hintText;
  final String? suffixText;
  final List<DenominatedAmount> min;
  final List<DenominatedAmount> max;
  final List<String> possibleDenominations;
  final bool enabled;
  final bool editable;
  final bool required;
  final bool exact;
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
    this.min = const [],
    this.max = const [],
    this.possibleDenominations = const [],
    this.enabled = true,
    this.editable = true,
    this.required = false,
    this.exact = true,
    this.textStyle,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.validator,
    this.onChanged,
  });

  @override
  State<AmountTapInput> createState() => _AmountTapInputState();
}

const _kAmountTapInputEditIconMaxSize = 22.0;

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
          borderRadius: AppBorderRadii.sm,
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
                Text(
                  formatAmount(_displayAmount, exact: widget.exact),
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
                if (canEdit) ...[
                  Gap.horizontal.xs(),
                  Icon(
                    Icons.edit_outlined,
                    size: (textStyle.fontSize ?? kIconSm).clamp(
                      0.0,
                      _kAmountTapInputEditIconMaxSize,
                    ),
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
      minAmounts: widget.min,
      maxAmounts: widget.max,
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
    final effectiveMin = effectiveAmount == null
        ? null
        : highestComparableAmount(effectiveAmount, widget.min);
    final effectiveMax = effectiveAmount == null
        ? null
        : lowestComparableAmount(effectiveAmount, widget.max);
    if (effectiveAmount != null &&
        amountIsBelowLimit(effectiveAmount, effectiveMin)) {
      final min = comparableAmountLimit(effectiveAmount, effectiveMin)!;
      return 'Amount must be at least ${formatAmount(min)}';
    }
    if (effectiveAmount != null &&
        amountIsAboveLimit(effectiveAmount, effectiveMax)) {
      final max = comparableAmountLimit(effectiveAmount, effectiveMax)!;
      return 'Amount must be at most ${formatAmount(max)}';
    }
    return widget.validator?.call(effectiveAmount);
  }
}

class AmountInputWidget extends FormField<DenominatedAmount> {
  final List<DenominatedAmount> min;
  final List<DenominatedAmount> max;

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

  /// Fired when the user submits the keypad with Enter or numpad Enter.
  final VoidCallback? onSubmitted;

  /// Fired when the current keypad amount enters or exits the valid range.
  final ValueChanged<bool>? onValidityChanged;

  AmountInputWidget({
    super.key,
    initialValue,
    this.min = const [],
    this.max = const [],
    this.possibleDenominations = const [],
    this.onDenominationChanged,
    this.onSubmitted,
    this.onValidityChanged,
  }) : super(
         initialValue: initialValue ?? DenominatedAmount.zero('BTC', 8),
         builder: (field) {
           final amountInput = field.widget as AmountInputWidget;
           final value = field.value!;
           final effectiveMin = highestComparableAmount(value, amountInput.min);
           final effectiveMax = lowestComparableAmount(value, amountInput.max);
           final isOutOfRange =
               amountIsBelowLimit(value, effectiveMin) ||
               amountIsAboveLimit(value, effectiveMax);
           WidgetsBinding.instance.addPostFrameCallback((_) {
             amountInput.onValidityChanged?.call(!isOutOfRange);
           });
           final denominations = amountInput.possibleDenominations;
           final activeDenomination = value.denomination;
           return Focus(
             autofocus: true,
             onKeyEvent: (_, event) {
               if (event is! KeyDownEvent) {
                 return KeyEventResult.ignored;
               }

               if (_isAmountEditorSubmitKey(event.logicalKey)) {
                 amountInput.onSubmitted?.call();
                 return amountInput.onSubmitted == null
                     ? KeyEventResult.ignored
                     : KeyEventResult.handled;
               }

               final input = _amountEditorInputForKey(event.logicalKey);
               if (input == null) {
                 return KeyEventResult.ignored;
               }

               final handled = _applyAmountEditorInput(field, input);
               return handled ? KeyEventResult.handled : KeyEventResult.ignored;
             },
             child: Column(
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
                           final newDecimals = decimalsForDenomination(
                             newDenom,
                           );
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
                       if (effectiveMin != null || effectiveMax != null)
                         CustomPadding.only(
                           top: kSpace1,
                           child: Text(
                             '${effectiveMin != null ? formatAmount(effectiveMin) : '0'} — ${effectiveMax != null ? formatAmount(effectiveMax) : '∞'}',
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
                                   color: Theme.of(
                                     context,
                                   ).colorScheme.onSurface,
                                 );
                               } else {
                                 buttonContent =
                                     Container(); // Empty container for the last cell
                               }

                               return GestureDetector(
                                 behavior: HitTestBehavior.opaque,
                                 onTap: () {
                                   _applyAmountEditorInput(
                                     field,
                                     buttons[index],
                                   );
                                 },
                                 child: AppSurface(
                                   steps: 2,
                                   shape: AppShapes.circle,
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
             ),
           );
         },
       );
}

bool _isAmountEditorSubmitKey(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter;
}

Object? _amountEditorInputForKey(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
    return 0;
  }
  if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
    return 1;
  }
  if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
    return 2;
  }
  if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
    return 3;
  }
  if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
    return 4;
  }
  if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
    return 5;
  }
  if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
    return 6;
  }
  if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
    return 7;
  }
  if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
    return 8;
  }
  if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
    return 9;
  }

  if (key == LogicalKeyboardKey.period ||
      key == LogicalKeyboardKey.numpadDecimal) {
    return '.';
  }

  if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
    return 'backspace';
  }

  return null;
}

bool _applyAmountEditorInput(
  FormFieldState<DenominatedAmount> field,
  Object input,
) {
  final currentAmount = field.value;
  if (currentAmount == null) {
    return false;
  }

  final isBtc = currentAmount.isBtc;
  final maxDecimals = isBtc ? 0 : currentAmount.decimals;

  // For BTC-family, we edit in sats (the display unit), so use the raw
  // integer value directly.
  String currentValue;
  if (isBtc) {
    currentValue = currentAmount.value.toString();
  } else {
    currentValue = currentAmount.toDecimalString(maxDecimals: maxDecimals);
    // Only trim trailing zeros after the decimal point.
    if (currentValue.contains('.')) {
      currentValue = currentValue.replaceAll(RegExp(r'0*$'), '');
      currentValue = currentValue.replaceAll(RegExp(r'\.$'), '');
    }
  }

  if (input is int) {
    if (currentValue == '0') {
      currentValue = '';
    }
    final newValue = currentValue + input.toString();
    final DenominatedAmount newAmount;
    if (isBtc) {
      final parsed = BigInt.tryParse(newValue);
      if (parsed == null) return false;
      newAmount = DenominatedAmount(
        value: parsed,
        denomination: currentAmount.denomination,
        decimals: currentAmount.decimals,
      );
    } else {
      newAmount = DenominatedAmount.fromDecimal(
        newValue,
        currentAmount.denomination,
        currentAmount.decimals,
      );
    }
    field.didChange(newAmount);
    return true;
  }

  if (input == '.') {
    if (isBtc || currentValue.contains('.')) return false;
    final newValue = currentValue.isEmpty ? '0.' : '$currentValue.';
    field.didChange(
      DenominatedAmount.fromDecimal(
        newValue,
        currentAmount.denomination,
        currentAmount.decimals,
      ),
    );
    return true;
  }

  if (input == 'backspace') {
    if (currentValue.isEmpty) return false;

    final newValue = currentValue.substring(0, currentValue.length - 1);
    if (isBtc) {
      final parsed = newValue.isEmpty
          ? BigInt.zero
          : (BigInt.tryParse(newValue) ?? BigInt.zero);
      field.didChange(
        DenominatedAmount(
          value: parsed,
          denomination: currentAmount.denomination,
          decimals: currentAmount.decimals,
        ),
      );
    } else {
      field.didChange(
        DenominatedAmount.fromDecimal(
          newValue.isEmpty ? '0' : newValue,
          currentAmount.denomination,
          currentAmount.decimals,
        ),
      );
    }
    return true;
  }

  return false;
}

/// A bottom sheet that allows the user to edit an amount within an optional range.
class AmountEditorBottomSheet extends StatefulWidget {
  final DenominatedAmount initialAmount;
  final List<DenominatedAmount> minAmounts;
  final List<DenominatedAmount> maxAmounts;
  final List<String> possibleDenominations;
  final ValueChanged<String>? onDenominationChanged;

  const AmountEditorBottomSheet({
    super.key,
    required this.initialAmount,
    this.minAmounts = const [],
    this.maxAmounts = const [],
    this.possibleDenominations = const [],
    this.onDenominationChanged,
  });

  /// Shows the amount editor as a modal bottom sheet.
  /// Returns the selected [DenominatedAmount], or null if dismissed.
  static Future<DenominatedAmount?> show(
    BuildContext context, {
    required DenominatedAmount initialAmount,
    List<DenominatedAmount> minAmounts = const [],
    List<DenominatedAmount> maxAmounts = const [],
    List<String> possibleDenominations = const [],
    ValueChanged<String>? onDenominationChanged,
  }) {
    return showAppModal<DenominatedAmount>(
      context,
      builder: (_) => AmountEditorBottomSheet(
        initialAmount: initialAmount,
        minAmounts: minAmounts,
        maxAmounts: maxAmounts,
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
  final _isAmountValid = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _isAmountValid.dispose();
    super.dispose();
  }

  bool _isValid(DenominatedAmount amount) {
    return amountIsWithinLimits(
      amount,
      min: widget.minAmounts,
      max: widget.maxAmounts,
    );
  }

  void _setAmountValidity(bool isValid) {
    if (_isAmountValid.value == isValid) {
      return;
    }
    _isAmountValid.value = isValid;
  }

  void _submitAmount() {
    final amount = _formFieldKey.currentState?.value ?? widget.initialAmount;
    if (_isValid(amount)) {
      Navigator.of(context).pop(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AmountInputWidget(
          key: _formFieldKey,
          initialValue: widget.initialAmount,
          min: widget.minAmounts,
          max: widget.maxAmounts,
          possibleDenominations: widget.possibleDenominations,
          onDenominationChanged: widget.onDenominationChanged,
          onValidityChanged: _setAmountValidity,
          onSubmitted: _submitAmount,
        ),
        Gap.vertical.lg(),
        SafeArea(
          top: false,
          child: CustomPadding(
            top: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isAmountValid,
              builder: (context, isValid, child) {
                return ModalBottomSheetPrimaryButton(
                  onPressed: isValid ? _submitAmount : null,
                  child: child!,
                );
              },
              child: Text(AppLocalizations.of(context)!.done),
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
