import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';
import 'package:timelines_plus/timelines_plus.dart';

import 'payment_timeline_item.dart';

class TradeTimeline extends StatelessWidget {
  final List<Reservation> reservations;
  final List<PaymentEvent> paymentEvents;
  final String hostPubKey;
  const TradeTimeline({
    super.key,
    required this.reservations,
    required this.paymentEvents,
    required this.hostPubKey,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> events = [...reservations, ...paymentEvents]
      ..sort((a, b) {
        final timestampA = a is Reservation
            ? DateTime.fromMillisecondsSinceEpoch(a.createdAt * 1000)
            : (a is EscrowEvent
                  ? a.block.timestamp
                  : DateTime.fromMillisecondsSinceEpoch(0));

        final timestampB = b is Reservation
            ? DateTime.fromMillisecondsSinceEpoch(b.createdAt * 1000)
            : (b is EscrowEvent
                  ? b.block.timestamp
                  : DateTime.fromMillisecondsSinceEpoch(0));
        return timestampA.compareTo(timestampB);
      });
    if (events.isEmpty) return const SizedBox.shrink();

    const maxHistoryHeight = 320.0;
    final surface = Theme.of(context).colorScheme.surface;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: maxHistoryHeight),
      child: Stack(
        children: [
          Timeline.tileBuilder(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: kDefaultPadding.toDouble()),
            theme: TimelineThemeData(
              nodePosition: 0,
              connectorTheme: ConnectorThemeData(
                thickness: 2.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              indicatorTheme: IndicatorThemeData(
                size: 20.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            builder: TimelineTileBuilder.connected(
              connectionDirection: ConnectionDirection.before,
              connectorBuilder: (_, index, ___) => SolidLineConnector(
                color: Theme.of(context).colorScheme.primary,
              ),
              indicatorBuilder: (context, index) => DotIndicator(
                color: Theme.of(context).colorScheme.primary,
                // child: Icon(Icons.check, size: 12, color: Colors.white),
              ),
              contentsAlign: ContentsAlign.basic,
              contentsBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: PaymentTimelineItem(
                  event: events[index],
                  hostPubkey: hostPubKey,
                ),
              ),
              itemCount: events.length,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: kDefaultPadding.toDouble(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [surface.withValues(alpha: 0), surface],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
