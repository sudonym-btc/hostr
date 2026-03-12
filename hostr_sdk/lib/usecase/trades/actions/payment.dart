import 'package:injectable/injectable.dart';

import '../../../util/stream_status.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../trade.dart';
import 'trade_action_resolver.dart';

@injectable
class PaymentActions {
  final Trade trade;

  PaymentActions({required this.trade});

  static List<TradeAction> resolve(
    List<PaymentEvent> paymentEvents,
    StreamStatus paymentStreamStatus,
    TradeRole role,
  ) {
    final paymentStateFresh =
        paymentStreamStatus is StreamStatusLive ||
        paymentStreamStatus is StreamStatusQueryComplete;

    final escrowFunded = paymentEvents
        .whereType<EscrowFundedEvent>()
        .firstOrNull;
    final usedEscrow = escrowFunded != null;

    final hasTerminalPaymentState = paymentEvents.any(
      (event) =>
          event is PaymentClaimedEvent ||
          event is PaymentArbitratedEvent ||
          event is PaymentReleasedEvent,
    );

    final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final canClaim =
        usedEscrow &&
        !hasTerminalPaymentState &&
        nowUnix > escrowFunded.unlockAt;

    final actions = <TradeAction>[];

    if (!paymentStateFresh) return actions;

    if (role == TradeRole.host) {
      actions.addAll([
        if (canClaim) TradeAction.claim,
        if (!hasTerminalPaymentState && paymentEvents.isNotEmpty)
          TradeAction.refund,
      ]);
    }

    return actions;
  }

  void pay() {
    throw UnimplementedError('Payment action is not implemented yet');
  }

  void refund() {
    throw UnimplementedError('Refund action is not implemented yet');
  }

  void claim() {
    throw UnimplementedError('Claim action is not implemented yet');
  }
}
