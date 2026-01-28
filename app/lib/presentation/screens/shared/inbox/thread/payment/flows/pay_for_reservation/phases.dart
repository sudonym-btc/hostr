// ━━━ PARENT FLOW PHASES ━━━
sealed class ReservationPhase {}

class ReviewReservationPhase extends ReservationPhase {}

// Payment is a sub-phase of reservation flow
class PaymentPhase extends ReservationPhase {
  final PaymentSubPhase step;
  PaymentPhase(this.step);
}

class ConfirmationPhase extends ReservationPhase {
  final PaymentResult paymentResult;
  ConfirmationPhase(this.paymentResult);
}

// ━━━ REUSE PAYMENT SUB-STEPS ━━━
sealed class PaymentSubPhase {}

class MethodSelectionStep extends PaymentSubPhase {}

class EscrowPhase extends PaymentSubPhase {
  final EscrowSubStep step;
  EscrowPhase(this.step);
}

class RawPaymentPhase extends PaymentSubPhase {
  final RawPaymentSubStep step;
  RawPaymentPhase(this.step);
}

sealed class EscrowSubStep {}

class SelectEscrowStep extends EscrowSubStep {}

class ReviewEscrowStep extends EscrowSubStep {
  final String selectedEscrowId;
  ReviewEscrowStep(this.selectedEscrowId);
}

sealed class RawPaymentSubStep {}

class EnterAmountStep extends RawPaymentSubStep {}

class ConfirmPaymentStep extends RawPaymentSubStep {
  final double amount;
  ConfirmPaymentStep(this.amount);
}

// ━━━ PAYMENT RESULT ━━━
class PaymentResult {
  final bool useEscrow;
  final String? escrowId;
  final double? amount;

  PaymentResult({required this.useEscrow, this.escrowId, this.amount});
}

// ━━━ PARENT STATE ━━━
class ReservationFlowState {
  final ReservationPhase currentPhase;
  final PaymentResult? paymentResult;

  ReservationFlowState({ReservationPhase? currentPhase, this.paymentResult})
    : currentPhase = currentPhase ?? ReviewReservationPhase();

  ReservationFlowState copyWith({
    ReservationPhase? currentPhase,
    PaymentResult? paymentResult,
  }) => ReservationFlowState(
    currentPhase: currentPhase ?? this.currentPhase,
    paymentResult: paymentResult ?? this.paymentResult,
  );
}
