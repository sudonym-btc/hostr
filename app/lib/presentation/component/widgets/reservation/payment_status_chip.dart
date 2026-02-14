import 'package:flutter/material.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';

class PaymentStatusChip extends StatelessWidget {
  final PaymentEvent? state;
  const PaymentStatusChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is EscrowFundedEvent) {
      return Chip(
        label: const Text('Paid'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        side: BorderSide.none,
        avatar: Icon(
          Icons.check,
          size: 16,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        shape: const StadiumBorder(),
      );
    } else if (state is EscrowReleasedEvent) {
      return Chip(
        label: const Text('Released'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        side: BorderSide.none,
        avatar: Icon(
          Icons.handshake,
          size: 16,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        shape: const StadiumBorder(),
      );
    } else if (state is EscrowArbitratedEvent) {
      return Chip(
        label: const Text('Arbitrated'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        side: BorderSide.none,
        avatar: Icon(
          Icons.gavel,
          size: 16,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        shape: const StadiumBorder(),
      );
    } else if (state is EscrowClaimedEvent) {
      return Chip(
        label: const Text('Claimed'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        side: BorderSide.none,
        avatar: Icon(
          Icons.done_all_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        shape: const StadiumBorder(),
      );
    }

    return Container();
  }
}
