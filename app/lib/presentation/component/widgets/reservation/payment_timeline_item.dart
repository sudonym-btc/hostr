import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';

import '../amount/amount_input.dart';

class PaymentTimelineItem extends StatelessWidget {
  // Can be either a Reservation or a PaymentEvent, both have different display info
  final dynamic event;
  final Listing listing;

  const PaymentTimelineItem({
    super.key,
    required this.event,
    required this.listing,
  });
  @override
  Widget build(BuildContext context) {
    String formatPercent(double value) {
      return value
          .toStringAsFixed(6)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }

    Widget escrowEvent({
      required String title,
      String? description,
      IconData? icon,
      required DateTime timestamp,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(style: Theme.of(context).textTheme.titleMedium, title),
          description != null ? Text(description) : SizedBox.shrink(),
          Text(
            formatDateLong(timestamp),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
          ),

          // ProfileChipWidget(
          //   id: event.escrowService.parsedContent.service.pubKey,
          // ),
        ],
      );
    }

    if (event is Reservation) {
      return escrowEvent(
        title:
            'Reservation ${event.parsedContent.cancelled ? "cancelled" : "updated"} by ${event.pubKey == listing.pubKey ? 'host' : 'guest'}',
        timestamp: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      );
    }
    if (event is EscrowFundedEvent) {
      return escrowEvent(
        title: 'Escrow funded',
        description: '${formatAmount(event.amount.toAmount())}',
        timestamp: event.block.timestamp,
      );
    } else if (event is EscrowReleasedEvent) {
      return escrowEvent(
        title: 'Funds released',
        timestamp: event.block.timestamp,
      );
    } else if (event is EscrowArbitratedEvent) {
      return escrowEvent(
        title: 'Escrow arbitrated',
        description:
            'Forwarded ${formatPercent(event.forwarded * 100)}% to host',
        timestamp: event.block.timestamp,
      );
    } else if (event is EscrowClaimedEvent) {
      return escrowEvent(
        title: 'Escrow funds claimed',
        timestamp: event.block.timestamp,
      );
    }
    return Text('Timeline Event ${event.runtimeType}');
  }
}
