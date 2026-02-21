import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:models/stubs/main.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Trade header (knobs)', type: TradeHeaderView)
Widget tradeHeaderKnobs(BuildContext context) {
  final isReservationRequestOnly = context.knobs.boolean(
    label: 'Reservation request only',
    initialValue: false,
  );
  final isBlocked = context.knobs.boolean(
    label: 'Blocked',
    initialValue: false,
  );
  final showTimeline = context.knobs.boolean(
    label: 'Show timeline',
    initialValue: true,
  );
  final paymentStatusLabel = context.knobs.object.dropdown<String>(
    label: 'Payment status',
    options: const ['Pending', 'Paid', 'Escrow', 'Cancelled'],
  );

  final listing = MOCK_LISTINGS.first;
  final start = DateTime.now();
  final end = DateTime.now().add(const Duration(days: 2));

  return Scaffold(
    body: SingleChildScrollView(
      child: TradeHeaderView(
        listing: listing,
        start: start,
        end: end,
        amount: listing.parsedContent.price.first.amount,
        isBlocked: isBlocked,
        blockedReason: isBlocked ? 'This reservation is not available.' : null,
        isReservationRequestOnly: isReservationRequestOnly,
        paymentStatusWidget: Chip(label: Text(paymentStatusLabel)),
        actionsRightWidget: FilledButton.tonal(
          onPressed: () {},
          child: const Text('Pay'),
        ),
        actionsWidget: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(onPressed: () {}, child: const Text('Accept')),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Message Escrow'),
            ),
            FilledButton.tonal(onPressed: () {}, child: const Text('Cancel')),
          ],
        ),
        timelineWidget: showTimeline
            ? const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Timeline preview'),
                subtitle: Text('Reservation requested → Paid → Confirmed'),
              )
            : const SizedBox.shrink(),
      ),
    ),
  );
}
