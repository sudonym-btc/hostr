import 'package:flutter/material.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';

class PaymentStatusChip extends StatelessWidget {
  final PaymentEvent? state;
  const PaymentStatusChip({super.key, required this.state});

  Chip _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity(horizontal: -4, vertical: -4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.only(right: 10),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      side: BorderSide.none,
      avatar: Icon(
        icon,
        size: 14,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      shape: const StadiumBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (state is EscrowFundedEvent) {
      return _buildChip(context, label: 'Paid', icon: Icons.check);
    } else if (state is EscrowReleasedEvent) {
      return _buildChip(context, label: 'Released', icon: Icons.handshake);
    } else if (state is EscrowArbitratedEvent) {
      return _buildChip(context, label: 'Arbitrated', icon: Icons.gavel);
    } else if (state is EscrowClaimedEvent) {
      return _buildChip(
        context,
        label: 'Claimed',
        icon: Icons.done_all_outlined,
      );
    }

    return const SizedBox.shrink();
  }
}
