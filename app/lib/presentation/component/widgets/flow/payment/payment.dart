import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/main.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_operation.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:models/main.dart';

import '../modal_bottom_sheet.dart';

class PaymentFlowWidget extends StatelessWidget {
  final PayOperation cubit;
  const PaymentFlowWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<PayOperation, PayState>(
        builder: (context, state) {
          return PaymentViewWidget(state);
        },
      ),
    );
  }
}

class PaymentViewWidget extends StatelessWidget {
  final PayState state;
  final VoidCallback? onConfirm;
  const PaymentViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    switch (state) {
      case PayFailed():
        return PaymentFailureWidget(state as PayFailed);
      case PayInFlight():
        return PaymentProgressWidget(state);
      case PayCompleted():
        return PaymentSuccessWidget(state);
      case PayResolved():
      case PayCallbackComplete():
      default:
        return PaymentConfirmWidget(state: state);
    }
  }
}

class PaymentConfirmWidget extends StatelessWidget {
  final PayState state;
  const PaymentConfirmWidget({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Builder(
        builder: (context) {
          Widget nwcInfo = CustomPadding(
            child: NostrWalletConnectConnectionWidget(),
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              nwcInfo,
              CustomPadding(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.params.to,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // todo: calc amount from invoice
                          Text(
                            formatAmount(
                              state.params.amount?.toAmount() ??
                                  Amount(
                                    currency: Currency.BTC,
                                    value: BigInt.from(0),
                                  ),
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    state is PayResolved
                        ? FilledButton(
                            child: Text(AppLocalizations.of(context)!.ok),
                            onPressed: () {
                              context.read<PayOperation>().finalize();
                            },
                          )
                        : FilledButton(
                            child: Text(AppLocalizations.of(context)!.pay),
                            onPressed: () {
                              context.read<PayOperation>().complete();
                            },
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PaymentProgressWidget extends StatelessWidget {
  final PayState state;
  const PaymentProgressWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Center(child: CircularProgressIndicator()),
    );
  }
}

class PaymentSuccessWidget extends StatelessWidget {
  final PayState state;
  const PaymentSuccessWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      content: Text(AppLocalizations.of(context)!.paymentCompleted),
    );
  }
}

class PaymentFailureWidget extends StatelessWidget {
  final PayFailed state;
  const PaymentFailureWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      content: Text('Payment failed: ${state.error}'),
    );
  }
}
