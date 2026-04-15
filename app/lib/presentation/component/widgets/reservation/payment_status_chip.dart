import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/ui/app_chip.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class PaymentStatusChip extends StatelessWidget {
  final PaymentEvent? state;
  const PaymentStatusChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (state is EscrowFundedEvent) {
      child = AppChip.success.xs(label: Text('Paid'));
    } else if (state is EscrowReleasedEvent) {
      child = AppChip.neutral.xs(label: Text('Funds Released'));
    } else if (state is EscrowArbitratedEvent) {
      child = AppChip.neutral.xs(label: Text('Arbitrated'));
    } else if (state is EscrowClaimedEvent) {
      child = AppChip.neutral.xs(label: Text('Claimed'));
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
