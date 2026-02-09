import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import '../modal_bottom_sheet.dart';

class PaymentFlowWidget extends StatelessWidget {
  final PaymentCubit cubit;
  const PaymentFlowWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<PaymentCubit, PayState>(
        builder: (context, state) {
          return PaymentViewWidget(state);
        },
      ),
    );
  }
}

class PaymentViewWidget extends StatelessWidget {
  final PaymentState state;
  final VoidCallback? onConfirm;
  const PaymentViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    switch (state.status) {
      case PaymentStatus.failed:
        return PaymentFailureWidget(state);
      case PaymentStatus.inFlight:
        return PaymentProgressWidget(state);
      case PaymentStatus.completed:
        return PaymentSuccessWidget(state);
      default:
        return PaymentConfirmWidget(state: state);
    }
  }
}

class PaymentConfirmWidget extends StatelessWidget {
  final PaymentState state;
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
                    state.status == PaymentStatus.resolved
                        ? FilledButton(
                            child: Text(AppLocalizations.of(context)!.ok),
                            onPressed: () {
                              context.read<PaymentCubit>().ok();
                            },
                          )
                        : FilledButton(
                            child: Text(AppLocalizations.of(context)!.pay),
                            onPressed: () {
                              context.read<PaymentCubit>().confirm();
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
  final PaymentState state;
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
  final PaymentState state;
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
  final PaymentState state;
  const PaymentFailureWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      content: Text('Payment failed: ${state.error}'),
    );
  }
}
