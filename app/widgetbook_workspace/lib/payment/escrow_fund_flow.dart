import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/escrow/fund/escrow_fund.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// -- Confirm (pure stand-in — real widget reads cubit) ------------------

@widgetbook.UseCase(name: 'Escrow Fund - Confirm', type: ModalBottomSheet)
Widget escrowFundConfirm(BuildContext context) {
  return ModalBottomSheet(
    type: ModalBottomSheetType.normal,
    title: 'Deposit Funds',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escrow Service'),
        const SizedBox(height: 8),
        Text(
          '50 000 sats',
          style: Theme.of(context)
              .textTheme
              .displayMedium!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '+ 150 sats in gas',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.6),
              ),
        ),
        Text(
          '+ 250 sats in swap fees',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(onPressed: () {}, child: const Text('OK')),
          ],
        ),
      ],
    ),
  );
}

// -- Swap in-progress (composing swap-in view) -------------------------

@widgetbook.UseCase(
    name: 'Swap in progress', type: EscrowFundProgressWidget)
Widget escrowFundSwapProgress(BuildContext context) {
  return EscrowFundProgressWidget(
    EscrowFundSwapProgress(
      SwapInPaymentProgress(
        paymentState: PayInFlight(
          params: PayParameters(
            to: 'escrow@hostr.cc',
            amount: BitcoinAmount.fromInt(BitcoinUnit.sat, 50000),
          ),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(
    name: 'On-chain in progress', type: EscrowFundProgressWidget)
Widget escrowFundOnChainProgress(BuildContext context) {
  return EscrowFundProgressWidget(
    EscrowFundSwapProgress(const SwapInAwaitingOnChain()),
  );
}

// -- Trade progress ----------------------------------------------------

@widgetbook.UseCase(
    name: 'Trade in progress', type: EscrowFundTradeProgressWidget)
Widget escrowFundTradeProgress(BuildContext context) {
  return const EscrowFundTradeProgressWidget();
}

// -- Success -----------------------------------------------------------

@widgetbook.UseCase(name: 'Escrow Fund - Success', type: ModalBottomSheet)
Widget escrowFundSuccess(BuildContext context) {
  // EscrowFundCompleted requires a TransactionInformation from web3dart.
  // We use the sub-widget's ModalBottomSheet directly for the story.
  return const ModalBottomSheet(
    type: ModalBottomSheetType.success,
    title: 'Deposit Success',
    subtitle: 'Funds have been deposited into the escrow.',
    content: SizedBox.shrink(),
  );
}

// -- Error -------------------------------------------------------------

@widgetbook.UseCase(name: 'Error', type: EscrowFundFailureWidget)
Widget escrowFundError(BuildContext context) {
  return EscrowFundFailureWidget(
    EscrowFundFailed('Escrow contract reverted: insufficient allowance'),
  );
}
