import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:models/amount.dart';

import 'amount_input.dart';

class AmountWidget extends StatelessWidget {
  final String to;
  final Amount amount;
  final Function onConfirm;
  const AmountWidget({
    super.key,
    required this.to,
    required this.amount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(to, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          formatAmount(amount),
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
