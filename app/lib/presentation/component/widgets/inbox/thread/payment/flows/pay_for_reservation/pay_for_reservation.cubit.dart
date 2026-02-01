import 'package:flutter_bloc/flutter_bloc.dart';

import 'phases.dart';

class ReservationFlowCubit extends Cubit<ReservationFlowState> {
  ReservationFlowCubit() : super(ReservationFlowState());

  // Move to payment phase
  void proceedToPayment() =>
      emit(state.copyWith(currentPhase: PaymentPhase(MethodSelectionStep())));

  // Payment sub-flow navigation
  void choosePaymentEscrow() => emit(
    state.copyWith(currentPhase: PaymentPhase(EscrowPhase(SelectEscrowStep()))),
  );

  void confirmPaymentEscrow(String escrowId) => emit(
    state.copyWith(
      currentPhase: PaymentPhase(EscrowPhase(ReviewEscrowStep(escrowId))),
    ),
  );

  void choosePaymentNow() => emit(
    state.copyWith(
      currentPhase: PaymentPhase(RawPaymentPhase(EnterAmountStep())),
    ),
  );

  void confirmPaymentAmount(double amount) => emit(
    state.copyWith(
      currentPhase: PaymentPhase(RawPaymentPhase(ConfirmPaymentStep(amount))),
    ),
  );

  // Complete payment and move to confirmation
  void completePayment({
    required bool useEscrow,
    String? escrowId,
    double? amount,
  }) => emit(
    state.copyWith(
      currentPhase: ConfirmationPhase(),
      paymentResult: PaymentResult(
        useEscrow: useEscrow,
        escrowId: escrowId,
        amount: amount,
      ),
    ),
  );

  // Back navigation (same as before)
  void goBack() {
    final phase = state.currentPhase;
    final nextPhase = switch (phase) {
      ReviewReservationPhase() => ReviewReservationPhase(),
      PaymentPhase(step: MethodSelectionStep()) => ReviewReservationPhase(),
      PaymentPhase(step: EscrowPhase(step: SelectEscrowStep())) => PaymentPhase(
        MethodSelectionStep(),
      ),
      PaymentPhase(step: EscrowPhase(step: ReviewEscrowStep())) => PaymentPhase(
        EscrowPhase(SelectEscrowStep()),
      ),
      PaymentPhase(step: RawPaymentPhase(step: EnterAmountStep())) =>
        PaymentPhase(MethodSelectionStep()),
      PaymentPhase(step: RawPaymentPhase(step: ConfirmPaymentStep())) =>
        PaymentPhase(RawPaymentPhase(EnterAmountStep())),
      ConfirmationPhase() => ConfirmationPhase(),
    };
    emit(state.copyWith(currentPhase: nextPhase));
  }
}
