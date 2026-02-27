import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/trade_action_resolver.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

@widgetbook.UseCase(name: 'Trade header (knobs)', type: TradeHeaderView)
Widget tradeHeaderKnobs(BuildContext context) {
  final availability = context.knobs.list<TradeAvailability>(
    label: 'Availability',
    initialOption: TradeAvailability.available,
    options: TradeAvailability.values,
    labelBuilder: (v) => v.name,
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
        availability: availability,
        availabilityReason: availability != TradeAvailability.available
            ? 'This reservation is not available.'
            : null,
        tradeId: 'mock-trade-id',
        hostPubKey: listing.pubKey,
        runtimeReady: true,
        actionsRightWidget: FilledButton.tonal(
          onPressed: () {},
          child: const Text('Pay'),
        ),
        actionsSecondaryRow: Row(
          children: [
            TextButton(onPressed: () {}, child: const Text('Cancel')),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Message Escrow'),
            ),
          ],
        ),
      ),
    ),
  );
}
