import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/main.dart';
import 'package:models/main.dart';

class PaymentWidget extends StatelessWidget {
  final PaymentCubit paymentCubit;
  const PaymentWidget({Key? key, required this.paymentCubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaymentCubit>.value(
        value: paymentCubit,
        child:
            BlocBuilder<PaymentCubit, PaymentState>(builder: (context, state) {
          if (state.status == PaymentStatus.failed) {
            return Material(
                color: Colors.red,
                child: CustomPadding(child: Text(state.error!)));
          } else if (state.status == PaymentStatus.completed) {
            return Material(
                color: Colors.green,
                child: CustomPadding(
                    child: Container(
                        width: double.infinity,
                        child: Text('Payment completed'))));
          } else if (state.status == PaymentStatus.inFlight) {
            return CustomPadding(child: CircularProgressIndicator());
          }
          Widget? nwcInfo;

          if (paymentCubit is LnUrlPaymentCubit ||
              paymentCubit is Bolt11PaymentCubit) {
            nwcInfo = NostrWalletConnectConnectionWidget();
          }
          print(
              'Payment of type ${state.runtimeType}, ${paymentCubit.runtimeType}, ${state.params.amount?.value}');

          return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                nwcInfo ?? Container(),
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
                        Text(formatAmount(state.params.amount ??
                            Amount(currency: Currency.BTC, value: 0.0))),
                      ],
                    )),
                    state.status == PaymentStatus.resolved
                        ? FilledButton(
                            child: Text('Ok'),
                            onPressed: () {
                              paymentCubit.ok();
                            },
                          )
                        : FilledButton(
                            child: Text('Pay'),
                            onPressed: () {
                              paymentCubit.confirm();
                            },
                          )
                  ],
                ))
              ]);
        }));
  }
}
