import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import '../amount/amount_input.dart';

class PaymentTimelineItem extends StatelessWidget {
  // Can be either a Reservation or a PaymentEvent, both have different display info
  final dynamic event;
  final ReservationGroup? reservationGroup;

  const PaymentTimelineItem({
    super.key,
    required this.event,
    this.reservationGroup,
  });
  @override
  Widget build(BuildContext context) {
    String formatPercent(double value) {
      return value
          .toStringAsFixed(6)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }

    Widget buildTimeLineItem({
      required String title,
      String? description,
      IconData? icon,
      required DateTime timestamp,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          description != null
              ? Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : SizedBox.shrink(),
          Text(
            formatDateLong(timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (event is ReservationTransition) {
      final transitionEvent = event as ReservationTransition;
      final pubKey = transitionEvent.pubKey;
      final sellerPubkey = reservationGroup?.sellerPubkey;
      final escrowPubkey = reservationGroup?.escrowPubkey;

      String _roleLabel({
        required String host,
        required String escrow,
        required String guest,
      }) {
        if (pubKey == escrowPubkey) return escrow;
        if (pubKey == sellerPubkey) return host;
        return guest;
      }

      var title = 'Guest created reservation';
      switch (transitionEvent.transitionType) {
        case ReservationTransitionType.cancel:
          title = _roleLabel(
            host: 'Host cancelled reservation',
            escrow: 'Escrow cancelled reservation',
            guest: 'Guest cancelled reservation',
          );
          break;
        case ReservationTransitionType.confirm:
        case ReservationTransitionType.commit:
          title = _roleLabel(
            host: 'Host confirmed reservation',
            escrow: 'Escrow confirmed reservation',
            guest: 'Guest created reservation',
          );
          break;
        case ReservationTransitionType.counterOffer:
          title = _roleLabel(
            host: 'Host counter-offered',
            escrow: 'Escrow updated reservation',
            guest: 'Guest created reservation',
          );
          break;
      }

      return buildTimeLineItem(
        title: title,
        timestamp: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      );
    }
    if (event is EscrowFundedEvent) {
      final unlockDate = DateTime.fromMillisecondsSinceEpoch(
        event.unlockAt * 1000,
      );
      return buildTimeLineItem(
        title: 'Escrow funded',
        description:
            '${formatTokenAmount(event.amount)} · Unlocks ${formatDate(unlockDate)}',
        timestamp: event.block.timestamp,
      );
    } else if (event is EscrowReleasedEvent) {
      return buildTimeLineItem(
        title: 'Funds released',
        timestamp: event.block.timestamp,
      );
    } else if (event is EscrowArbitratedEvent) {
      final paymentPct = formatPercent(event.paymentForwarded * 100);
      final desc = event.bondForwarded > 0
          ? 'Payment $paymentPct% to host · Bond ${formatPercent(event.bondForwarded * 100)}% to host'
          : 'Payment $paymentPct% to host';
      return buildTimeLineItem(
        title: 'Escrow arbitrated',
        description: desc,
        timestamp: event.block.timestamp,
      );
    } else if (event is EscrowClaimedEvent) {
      return buildTimeLineItem(
        title: 'Funds claimed by host',
        timestamp: event.block.timestamp,
      );
    } else if (event is ZapFundedEvent) {
      return buildTimeLineItem(
        title: 'Funded via zap',
        description: formatTokenAmount(event.amount),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          event.event.createdAt * 1000,
        ),
      );
    }

    return Text(
      AppLocalizations.of(
        context,
      )!.timelineEventType(event.runtimeType.toString()),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
