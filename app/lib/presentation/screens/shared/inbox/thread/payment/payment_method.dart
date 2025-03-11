import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'escrow_selector.dart';

class PaymentMethodWidget extends StatelessWidget {
  final Metadata counterparty;
  final ReservationRequest r;
  const PaymentMethodWidget(
      {super.key, required this.counterparty, required this.r});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SafeArea(
        child: CustomPadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
              style: Theme.of(context).textTheme.titleLarge!,
              'Would you like to use an escrow to settle this transfer?'),
          CustomPadding(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: FilledButton(
                      onPressed: () async {
                        Navigator.of(context).pop();

                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return EscrowSelectorWidget(
                                  r: r, counterparty: counterparty);
                            });
                      },
                      child: Text('Use Escrow'))),
              CustomPadding(),
              Expanded(
                  child: FilledButton(
                      key: ValueKey('pay_upfront'),
                      onPressed: () {
                        Navigator.of(context).pop();

                        BlocProvider.of<PaymentsManager>(context).create(
                            LnUrlPaymentParameters(
                                to: counterparty.lud16 ?? counterparty.lud06!,
                                amount: r.parsedContent.amount));
                      },
                      child: Text('Pay Upfront')))
            ],
          )
        ],
      ),
    ));
  }
}
