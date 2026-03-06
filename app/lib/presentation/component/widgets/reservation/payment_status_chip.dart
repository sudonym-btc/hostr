import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../profile/verification/verification_badges.dart';

class PaymentStatusChip extends StatelessWidget {
  final PaymentEvent? state;
  const PaymentStatusChip({super.key, required this.state});

  StatusChip _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return StatusChip(
      label: label,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (state is EscrowFundedEvent) {
      child = _buildChip(context, label: 'Paid', icon: Icons.check);
    } else if (state is EscrowReleasedEvent) {
      child = _buildChip(
        context,
        label: 'Funds Released',
        icon: Icons.handshake,
      );
    } else if (state is EscrowArbitratedEvent) {
      child = _buildChip(context, label: 'Arbitrated', icon: Icons.gavel);
    } else if (state is EscrowClaimedEvent) {
      child = _buildChip(
        context,
        label: 'Claimed',
        icon: Icons.done_all_outlined,
      );
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
