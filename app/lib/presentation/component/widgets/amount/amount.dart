import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:models/amount.dart';

class AmountWidget extends StatelessWidget {
  final String? to;
  final String? toPubkey;
  final Amount amount;
  final Function onConfirm;
  const AmountWidget({
    super.key,
    this.to,
    this.toPubkey,
    required this.amount,
    required this.onConfirm,
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
        Builder(
          builder: (context) {
            final baseStyle = Theme.of(context).textTheme.bodySmall!;
            final subtleStyle = baseStyle.copyWith(
              fontWeight: FontWeight.w400,
              color: baseStyle.color?.withValues(alpha: 0.6),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "+ ${formatAmount(Amount(currency: Currency.BTC, value: BigInt.from(10000)))} in gas",
                  style: subtleStyle,
                ),
                Text(
                  "+ ${formatAmount(Amount(currency: Currency.BTC, value: BigInt.from(1200)))} in fees",
                  style: subtleStyle,
                ),
              ],
            );
          },
        ),
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
