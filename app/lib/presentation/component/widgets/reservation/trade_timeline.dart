import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';
import 'package:timelines_plus/timelines_plus.dart';

import 'payment_timeline_item.dart';

class TradeTimeline extends StatelessWidget {
  final List<ReservationTransition> transitions;
  final List<PaymentEvent> paymentEvents;
  final String hostPubKey;
  const TradeTimeline({
    super.key,
    required this.transitions,
    required this.paymentEvents,
    required this.hostPubKey,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> events = [...transitions, ...paymentEvents]
      ..sort((a, b) {
        final timestampA = a is ReservationTransition
            ? DateTime.fromMillisecondsSinceEpoch(a.createdAt * 1000)
            : (a is EscrowEvent
                  ? a.block.timestamp
                  : DateTime.fromMillisecondsSinceEpoch(0));

        final timestampB = b is ReservationTransition
            ? DateTime.fromMillisecondsSinceEpoch(b.createdAt * 1000)
            : (b is EscrowEvent
                  ? b.block.timestamp
                  : DateTime.fromMillisecondsSinceEpoch(0));
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
          connectorBuilder: (_, index, ___) =>
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
              hostPubkey: hostPubKey,
            ),
          ),
          itemCount: events.length,
        ),
      ),
    );
  }
}
