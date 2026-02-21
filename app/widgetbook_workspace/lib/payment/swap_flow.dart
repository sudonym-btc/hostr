import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/out/swap_out.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// ── Swap In ──────────────────────────────────────────────────────────────

@widgetbook.UseCase(name: 'Swap In - Confirm', type: SwapInConfirmWidget)
Widget swapInConfirm(BuildContext context) {
  return SwapInConfirmWidget(onConfirm: () {});
}

@widgetbook.UseCase(name: 'Swap In - Loading', type: SwapInProgressWidget)
Widget swapInLoading(BuildContext context) {
  return SwapInProgressWidget(const SwapInAwaitingOnChain());
}

@widgetbook.UseCase(name: 'Swap In - Success', type: SwapInSuccessWidget)
Widget swapInSuccess(BuildContext context) {
  return SwapInSuccessWidget(const SwapInCompleted());
}

@widgetbook.UseCase(name: 'Swap In - Error', type: SwapInFailureWidget)
Widget swapInError(BuildContext context) {
  return const SwapInFailureWidget(
    'Swap timed out waiting for on-chain confirmation',
  );
}

@widgetbook.UseCase(
  name: 'Swap In - Payment in progress',
  type: SwapInPaymentProgressWidget,
)
Widget swapInPaymentProgress(BuildContext context) {
  return SwapInPaymentProgressWidget(
    SwapInPaymentProgress(
      paymentState: PayInFlight(
        params: PayParameters(
          to: 'satoshi@hostr.cc',
          amount: BitcoinAmount.fromInt(BitcoinUnit.sat, 50000),
        ),
      ),
    ),
  );
}

// ── Swap Out ─────────────────────────────────────────────────────────────

@widgetbook.UseCase(name: 'Swap Out - Confirm', type: SwapOutConfirmWidget)
Widget swapOutConfirm(BuildContext context) {
  return SwapOutConfirmWidget(onConfirm: () {});
}

@widgetbook.UseCase(name: 'Swap Out - Loading', type: SwapOutProgressWidget)
Widget swapOutLoading(BuildContext context) {
  return SwapOutProgressWidget(const SwapOutAwaitingOnChain());
}

@widgetbook.UseCase(name: 'Swap Out - Success', type: SwapOutSuccessWidget)
Widget swapOutSuccess(BuildContext context) {
  return SwapOutSuccessWidget(const SwapOutCompleted());
}

@widgetbook.UseCase(name: 'Swap Out - Error', type: SwapOutFailureWidget)
Widget swapOutError(BuildContext context) {
  return const SwapOutFailureWidget('Insufficient EVM balance for swap');
}

@widgetbook.UseCase(
  name: 'Swap Out - Payment in progress',
  type: SwapOutPaymentProgressWidget,
)
Widget swapOutPaymentProgress(BuildContext context) {
  return SwapOutPaymentProgressWidget(
    SwapOutPaymentProgress(
      paymentState: PayInFlight(
        params: PayParameters(
          to: 'satoshi@hostr.cc',
          amount: BitcoinAmount.fromInt(BitcoinUnit.sat, 50000),
        ),
      ),
    ),
  );
}
