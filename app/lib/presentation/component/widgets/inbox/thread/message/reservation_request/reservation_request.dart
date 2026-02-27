import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr/presentation/component/widgets/listing/price.dart';
import 'package:models/main.dart';

class ThreadReservationRequestWidget extends ThreadMessageWidget {
  Reservation get negotiateReservation => item.child as Reservation;

  const ThreadReservationRequestWidget({
    super.key,
    required super.sender,
    required super.item,
    required super.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSentByMe
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: MessageContainer(
        isSentByMe: isSentByMe,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.reservationRequest,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            Gap.vertical.xs(),
            Text(
              formatDateRangeShort(
                DateTimeRange(
                  start: negotiateReservation.parsedContent.start,
                  end: negotiateReservation.parsedContent.end,
                ),
                Localizations.localeOf(context),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            PriceText(formatAmount(negotiateReservation.parsedContent.amount!)),
          ],
        ),
      ),
    );
  }
}
