import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:models/amount.dart';

class AmountWidget extends StatelessWidget {
  final String? to;
  final String? toPubkey;
  final Amount amount;
  final Function onConfirm;
  final Widget? feeWidget;
  final VoidCallback? onAmountTap;
  final bool loading;
  const AmountWidget({
    super.key,
    this.to,
    this.toPubkey,
    required this.amount,
    required this.onConfirm,
    this.feeWidget,
    this.onAmountTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (toPubkey != null)
          ProfileProvider(
            pubkey: toPubkey!,
            builder: (context, profile) =>
                Text("${profile.data?.metadata.getName() ?? ''}"),
          )
        else if (to != null)
          Text(to!, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (toPubkey != null || to != null) SizedBox(height: 8),
        GestureDetector(
          onTap: onAmountTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatAmount(amount),
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onAmountTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 16),
              ],
            ],
          ),
        ),
        SizedBox(height: 8),
        feeWidget != null ? feeWidget! : SizedBox.shrink(),
        SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: loading ? null : () => onConfirm(),
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      ],
    );
  }
}
