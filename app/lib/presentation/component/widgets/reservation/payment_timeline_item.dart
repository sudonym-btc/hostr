import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:url_launcher/url_launcher.dart';

import '../amount/amount_input.dart';

class PaymentTimelineItem extends StatelessWidget {
  // Can be either a Order or a PaymentEvent, both have different display info
  final dynamic event;
  final OrderGroup? reservationGroup;
  final DateTime? Function(PaymentEvent event)? paymentEventTimestamp;

  const PaymentTimelineItem({
    super.key,
    required this.event,
    this.reservationGroup,
    this.paymentEventTimestamp,
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
      DateTime? timestamp,
      Uri? transactionUri,
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
          if (timestamp != null)
            Text(
              formatDateLong(timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (transactionUri != null)
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tooltip: 'View transaction',
              onPressed: () => unawaited(
                launchUrl(transactionUri, mode: LaunchMode.externalApplication),
              ),
              icon: const Icon(Icons.open_in_new, size: 14),
            ),
        ],
      );
    }

    if (event is OrderTransition) {
      final transitionEvent = event as OrderTransition;
      final pubKey = transitionEvent.pubKey;
      final sellerPubkey = reservationGroup?.sellerPubkey;
      final escrowPubkey = reservationGroup?.escrowPubkey;

      String roleLabel({
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
        case OrderTransitionType.cancel:
          title = roleLabel(
            host: 'Host cancelled reservation',
            escrow: 'Escrow cancelled reservation',
            guest: 'Guest cancelled reservation',
          );
          break;
        case OrderTransitionType.confirm:
        case OrderTransitionType.commit:
          title = roleLabel(
            host: 'Host confirmed reservation',
            escrow: 'Escrow confirmed reservation',
            guest: 'Guest created reservation',
          );
          break;
        case OrderTransitionType.counterOffer:
          title = roleLabel(
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
      final timestamp = _paymentTimestamp(event);
      final unlockDate = DateTime.fromMillisecondsSinceEpoch(
        event.unlockAt * 1000,
      );
      return buildTimeLineItem(
        title: 'Escrow funded',
        description:
            '${formatTokenAmount(event.amount)} · Unlocks ${formatDate(unlockDate)}',
        timestamp: timestamp,
        transactionUri: _escrowTransactionUri(event),
      );
    } else if (event is EscrowReleasedEvent) {
      final timestamp = _paymentTimestamp(event);
      return buildTimeLineItem(
        title: 'Funds released',
        timestamp: timestamp,
        transactionUri: _escrowTransactionUri(event),
      );
    } else if (event is EscrowArbitratedEvent) {
      final timestamp = _paymentTimestamp(event);
      final paymentPct = formatPercent(event.paymentForwarded * 100);
      final desc = event.bondForwarded > 0
          ? 'Payment $paymentPct% to host · Bond ${formatPercent(event.bondForwarded * 100)}% to host'
          : 'Payment $paymentPct% to host';
      return buildTimeLineItem(
        title: 'Escrow arbitrated',
        description: desc,
        timestamp: timestamp,
        transactionUri: _escrowTransactionUri(event),
      );
    } else if (event is EscrowClaimedEvent) {
      final timestamp = _paymentTimestamp(event);
      return buildTimeLineItem(
        title: 'Funds claimed by host',
        timestamp: timestamp,
        transactionUri: _escrowTransactionUri(event),
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

  DateTime? _paymentTimestamp(PaymentEvent event) {
    final resolvedTimestamp = paymentEventTimestamp?.call(event);
    if (resolvedTimestamp != null) return resolvedTimestamp;
    if (event is EscrowEvent) {
      return event.block?.timestamp;
    }
    return null;
  }

  Uri? _escrowTransactionUri(EscrowEvent event) =>
      _txExplorerUri(event.chain?.config, event.transactionHash);
}

Uri? _txExplorerUri(EvmChainConfig? config, String? txHash) {
  final base = config?.blockExplorerUrl;
  if (base == null || base.isEmpty || txHash == null || txHash.isEmpty) {
    return null;
  }

  final url = base.contains('{tx}')
      ? base.replaceAll('{tx}', txHash)
      : '${base.replaceFirst(RegExp(r'/*$'), '')}/tx/$txHash';
  return Uri.tryParse(url);
}
