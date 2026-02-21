import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:injectable/injectable.dart';

import 'trade_action_resolver.dart';

@injectable
class PaymentActions {
  final ThreadTrade trade;

  PaymentActions({required this.trade});

  static List<TradeAction> resolve(
    List<PaymentEvent> paymentEvents,
    StreamStatus paymentStreamStatus,
    ThreadPartyRole role,
    bool isBlocked,
  ) {
    final paymentStateFresh =
        paymentStreamStatus is StreamStatusLive ||
        paymentStreamStatus is StreamStatusQueryComplete;

    final usedEscrow = paymentEvents.any((event) => event is EscrowFundedEvent);

    final hasTerminalPaymentState = paymentEvents.any(
      (event) =>
          event is PaymentClaimedEvent ||
          event is PaymentArbitratedEvent ||
          event is PaymentReleasedEvent,
    );
    final actions = <TradeAction>[];

    if (!paymentStateFresh) return actions;

    if (role == ThreadPartyRole.host) {
      actions.addAll([
        if (!hasTerminalPaymentState && usedEscrow) TradeAction.claim,
        if (!hasTerminalPaymentState && paymentEvents.isNotEmpty)
          TradeAction.refund,
      ]);
    }
    // Guest pay action is handled in reservation request actions, as payment is only possible during particular conditions

    return actions;
  }

  pay() {
    throw UnimplementedError('Payment action is not implemented yet');
  }

  refund() {
    throw UnimplementedError('Refund action is not implemented yet');
  }

  claim() {
    throw UnimplementedError('Claim action is not implemented yet');
  }
}
