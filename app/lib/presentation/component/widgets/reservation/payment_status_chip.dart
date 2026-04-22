import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/ui/app_chip.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class PaymentStatusChip extends StatelessWidget {
  final PaymentEvent? state;
  final VoidCallback? onTap;

  const PaymentStatusChip({super.key, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (state is EscrowFundedEvent) {
      child = AppChip.success.xs(label: Text('Paid'), onTap: onTap);
    } else if (state is EscrowReleasedEvent) {
      child = AppChip.info.xs(label: Text('Funds Released'), onTap: onTap);
    } else if (state is EscrowArbitratedEvent) {
      child = AppChip.info.xs(label: Text('Arbitrated'), onTap: onTap);
    } else if (state is EscrowClaimedEvent) {
      child = AppChip.info.xs(label: Text('Claimed'), onTap: onTap);
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
