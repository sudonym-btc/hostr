import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:models/amount.dart';

typedef AmountFormFieldEditor =
    Future<Amount?> Function(BuildContext context, Amount currentValue);

class AmountWidget extends StatelessWidget {
  final String? to;
  final String? toPubkey;
  final Amount amount;
  final FutureOr<void> Function()? onConfirm;
  final Widget? feeWidget;
  final VoidCallback? onAmountTap;
  final bool loading;
  final bool enabled;
  final bool showConfirmButton;
  final bool? confirmEnabled;
  final String? confirmLabel;
  final String? errorText;
  const AmountWidget({
    super.key,
    this.to,
    this.toPubkey,
    required this.amount,
    this.onConfirm,
    this.feeWidget,
    this.onAmountTap,
    this.loading = false,
    this.enabled = true,
    this.showConfirmButton = true,
    this.confirmEnabled,
    this.confirmLabel,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnAmountTap = enabled ? onAmountTap : null;
    final isConfirmEnabled = confirmEnabled ?? enabled;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (toPubkey != null)
          ProfileProvider(
            pubkey: toPubkey!,
            builder: (context, profile) => Text(
              profile.data?.metadata.getName() ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (to != null)
          Text(
            to!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (toPubkey != null || to != null) Gap.vertical.sm(),
        GestureDetector(
          onTap: effectiveOnAmountTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatAmount(amount),
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? null
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (effectiveOnAmountTap != null) ...[
                Gap.horizontal.xs(),
                Icon(Icons.edit, size: kIconSm),
              ],
            ],
          ),
        ),
        Gap.vertical.sm(),
        feeWidget != null ? feeWidget! : SizedBox.shrink(),
        if (errorText != null) ...[
          Gap.vertical.sm(),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (showConfirmButton) ...[
          Gap.vertical.sm(),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: loading || !isConfirmEnabled || onConfirm == null
                    ? null
                    : onConfirm,
                child: loading
                    ? AppLoadingIndicator.small(
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                    : Text(confirmLabel ?? AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class AmountFormField extends FormField<Amount> {
  AmountFormField({
    super.key,
    String? to,
    String? toPubkey,
    required Amount initialValue,
    AmountFormFieldEditor? onAmountTap,
    FutureOr<void> Function(Amount amount)? onConfirm,
    FormFieldSetter<Amount>? onSaved,
    FormFieldValidator<Amount>? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    ValueChanged<Amount>? onChanged,
    Widget? feeWidget,
    bool loading = false,
    bool enabled = true,
    bool showConfirmButton = false,
    bool? confirmEnabled,
    String? confirmLabel,
  }) : super(
         initialValue: initialValue,
         onSaved: onSaved,
         validator: validator,
         autovalidateMode: autovalidateMode,
         enabled: enabled,
         builder: (field) {
           final value = field.value ?? initialValue;
           return AmountWidget(
             to: to,
             toPubkey: toPubkey,
             amount: value,
             feeWidget: feeWidget,
             loading: loading,
             enabled: enabled,
             showConfirmButton: showConfirmButton,
             confirmEnabled: confirmEnabled ?? (enabled && !field.hasError),
             confirmLabel: confirmLabel,
             errorText: field.errorText,
             onAmountTap: onAmountTap == null
                 ? null
                 : () async {
                     final updated = await onAmountTap(field.context, value);
                     if (updated == null) {
                       return;
                     }
                     field.didChange(updated);
                     onChanged?.call(updated);
                   },
             onConfirm: onConfirm == null ? null : () => onConfirm(value),
           );
         },
       );
}
