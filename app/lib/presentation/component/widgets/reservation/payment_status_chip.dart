import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../profile/verification/verification_badges.dart';

class PaymentStatusChip extends StatelessWidget {
  final PaymentEvent? state;
  const PaymentStatusChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget child;
    if (state is EscrowFundedEvent) {
      child = StatusChip(
        label: 'Paid',
        color: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      );
    } else if (state is EscrowReleasedEvent) {
      child = StatusChip(label: 'Funds Released', color: colorScheme.primary);
    } else if (state is EscrowArbitratedEvent) {
      child = StatusChip(label: 'Arbitrated', color: colorScheme.primary);
    } else if (state is EscrowClaimedEvent) {
      child = StatusChip(label: 'Claimed', color: colorScheme.primary);
    } else {
      child = const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: kAnimationDuration,
      switchInCurve: kAnimationCurve,
      switchOutCurve: kAnimationCurve,
      child: KeyedSubtree(key: ValueKey(state.runtimeType), child: child),
    );
  }
}
