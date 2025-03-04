import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/main.dart';

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
            nwcInfo = BlocProvider<NwcCubit>(create: (context) {
              return NwcCubit()..checkInfo();
            }, child:
                BlocBuilder<NwcCubit, NwcCubitState>(builder: (context, state) {
              if (state is Success) {
                return CustomPadding(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: state.content.color != null
                          ? Color(int.parse(
                                  state.content.color!.substring(1, 7),
                                  radix: 16) +
                              0xFF000000)
                          : Colors.orange,
                    ),
                    title: Text(state.content.alias ?? 'NWC Wallet'),
                    subtitle: Text(state.content.pubkey ?? 'No pubkey'),
                  ),
                  // Text(state.content.methods.join(', ')),
                  // Text(state.content.notifications.join(', ')),
                );
              }
              if (state is Error) {
                return Text('Could not connect to NWC provider: ${state.e}');
              }
              return CircularProgressIndicator();
            }));
            // nwcInfo = FutureBuilder(future: getIt<NwcCubit>()., builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {  return NwcProvider(pubkey: );});
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
                        Text(formatAmount(state.params.amount!)),
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
