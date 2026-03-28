import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

PayParameters get _mockParams => PayParameters(
  to: 'satoshi@hostr.cc',
  amount: TokenAmount.fromInt(TokenUnit.sat, 50000, Token.native(30)),
);

// -- Confirm -----------------------------------------------------------

@widgetbook.UseCase(name: 'Payment - Confirm', type: ModalBottomSheet)
Widget paymentConfirm(BuildContext context) {
  return ModalBottomSheet(
    type: ModalBottomSheetType.normal,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'satoshi@hostr.cc',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '50 000 sats',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            FilledButton(onPressed: () {}, child: const Text('Pay')),
          ],
        ),
      ],
    ),
  );
}

// -- Loading -----------------------------------------------------------

@widgetbook.UseCase(name: 'Loading', type: PaymentProgressWidget)
Widget paymentLoading(BuildContext context) {
  return PaymentProgressWidget(PayInFlight(params: _mockParams));
}

// -- Success -----------------------------------------------------------

@widgetbook.UseCase(name: 'Success', type: PaymentSuccessWidget)
Widget paymentSuccess(BuildContext context) {
  return PaymentSuccessWidget(
    PayCompleted(params: _mockParams, details: CompletedDetails()),
  );
}

// -- Error -------------------------------------------------------------

@widgetbook.UseCase(name: 'Error', type: PaymentFailureWidget)
Widget paymentError(BuildContext context) {
  return PaymentFailureWidget(
    PayFailed('Invoice expired after 600 seconds', params: _mockParams),
  );
}
