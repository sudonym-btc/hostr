import '../../../payments/operations/pay_state.dart';

sealed class SwapOutState {
  const SwapOutState();
}

final class SwapOutInitialised extends SwapOutState {
  const SwapOutInitialised();
}

final class SwapOutRequestCreated extends SwapOutState {
  const SwapOutRequestCreated();
}

final class SwapOutPaymentProgress extends SwapOutState {
  final PayState paymentState;
  const SwapOutPaymentProgress({required this.paymentState});
}

final class SwapOutAwaitingOnChain extends SwapOutState {
  const SwapOutAwaitingOnChain();
}

final class SwapOutFunded extends SwapOutState {
  const SwapOutFunded();
}

final class SwapOutClaimed extends SwapOutState {
  const SwapOutClaimed();
}

final class SwapOutCompleted extends SwapOutState {
  const SwapOutCompleted();
}

final class SwapOutFailed extends SwapOutState {
  const SwapOutFailed(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}
