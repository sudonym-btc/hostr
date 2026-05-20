import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:timelines_plus/timelines_plus.dart';

import 'payment_timeline_item.dart';

class TradeTimeline extends StatelessWidget {
  final List<OrderTransition> transitions;
  final List<PaymentEvent> paymentEvents;
  final OrderGroup? reservationGroup;
  final DateTime? Function(PaymentEvent event)? paymentEventTimestamp;

  const TradeTimeline({
    super.key,
    required this.transitions,
    required this.paymentEvents,
    this.reservationGroup,
    this.paymentEventTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> events = [...transitions, ...paymentEvents]
      ..sort((a, b) {
        final timestampA = _timestampFor(a);
        final timestampB = _timestampFor(b);
        return timestampA.compareTo(timestampB);
      });
    if (events.isEmpty) return const SizedBox.shrink();

    const maxHistoryHeight = 320.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: maxHistoryHeight),
      child: Timeline.tileBuilder(
        shrinkWrap: true,
        theme: TimelineThemeData(
          nodePosition: 0,
          connectorTheme: ConnectorThemeData(
            thickness: 1.0,
            color: Theme.of(context).colorScheme.primary,
          ),
          indicatorTheme: IndicatorThemeData(
            size: kSpace2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          connectorBuilder: (_, index, _) =>
              SolidLineConnector(color: Theme.of(context).colorScheme.primary),
          indicatorBuilder: (context, index) => DotIndicator(
            color: Theme.of(context).colorScheme.primary,
            // child: Icon(Icons.check, size: 12, color: Colors.white),
          ),
          contentsAlign: ContentsAlign.basic,
          contentsBuilder: (context, index) => CustomPadding.custom(
            kSpace4,
            child: PaymentTimelineItem(
              event: events[index],
              reservationGroup: reservationGroup,
              paymentEventTimestamp: paymentEventTimestamp,
            ),
          ),
          itemCount: events.length,
        ),
      ),
    );
  }

  DateTime _timestampFor(dynamic event) {
    if (event is OrderTransition) {
      return DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    }
    if (event is PaymentEvent) {
      final resolvedTimestamp = paymentEventTimestamp?.call(event);
      if (resolvedTimestamp != null) return resolvedTimestamp;
    }
    if (event is EscrowEvent) {
      final blockTimestamp = event.block?.timestamp;
      if (blockTimestamp != null) return blockTimestamp;
      return DateTime.fromMillisecondsSinceEpoch(event.blockNum * 1000);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
