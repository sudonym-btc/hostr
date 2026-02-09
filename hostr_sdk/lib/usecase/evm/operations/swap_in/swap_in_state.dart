import '../../../payments/operations/pay_state.dart';

sealed class SwapInState {
  const SwapInState();
}

final class SwapInInitialised extends SwapInState {
  const SwapInInitialised();
}

final class SwapInRequestCreated extends SwapInState {
  const SwapInRequestCreated();
}

final class SwapInPaymentProgress extends SwapInState {
  final PayState paymentState;
  const SwapInPaymentProgress({required this.paymentState});
}

final class SwapInAwaitingOnChain extends SwapInState {
  const SwapInAwaitingOnChain();
}

final class SwapInFunded extends SwapInState {
  const SwapInFunded();
}

final class SwapInClaimed extends SwapInState {
  const SwapInClaimed();
}

final class SwapInCompleted extends SwapInState {
  const SwapInCompleted();
}

final class SwapInFailed extends SwapInState {
  const SwapInFailed(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}
