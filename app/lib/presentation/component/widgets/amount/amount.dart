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
  const AmountWidget({
    super.key,
    this.to,
    this.toPubkey,
    required this.amount,
    required this.onConfirm,
    this.feeWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        toPubkey != null
            ? ProfileProvider(
                pubkey: toPubkey!,
                builder: (context, profile) =>
                    Text("${profile.data?.metadata.getName() ?? ''}"),
              )
            : Text(to!, maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 8),
        Text(
          formatAmount(amount),
          style: Theme.of(
            context,
          ).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        feeWidget != null ? feeWidget! : SizedBox.shrink(),
        SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: () => onConfirm(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      ],
    );
  }
}
