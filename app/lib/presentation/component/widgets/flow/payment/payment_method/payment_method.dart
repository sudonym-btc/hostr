import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import '../../modal_bottom_sheet.dart';
import '../escrow/fund/escrow_fund.dart';
import 'escrow_selector/escrow_selector.cubit.dart';
import 'escrow_selector/escrow_selector.dart';
import 'payment_method.cubit.dart';

class PaymentMethodWidget extends StatelessWidget {
  final ProfileMetadata counterparty;
  final ReservationRequest reservationRequest;
  const PaymentMethodWidget({
    super.key,
    required this.counterparty,
    required this.reservationRequest,
  });

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      title: 'Payment method',
      content: MultiBlocProvider(
        providers: [
          BlocProvider<EscrowSelectorCubit>(
            create: (context) => EscrowSelectorCubit(
              counterparty: counterparty,
              reservationRequest: reservationRequest,
              onDone: (selectedEscrow) {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return BlocProvider<EscrowFundOperation>(
                      create: (BuildContext context) =>
                          getIt<Hostr>().escrow.fund(
                            EscrowFundParams(
                              reservationRequest: reservationRequest,
                              amount: reservationRequest.parsedContent.amount,
                              sellerProfile: counterparty,
                              escrowService: selectedEscrow,
                            ),
                          ),
                      child: BlocBuilder<EscrowFundOperation, EscrowFundState>(
                        builder: (context, state) {
                          return EscrowFundWidget(
                            cubit: context.read<EscrowFundOperation>(),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            )..load(),
          ),
          BlocProvider<PaymentMethodCubit>(
            create: (context) =>
                PaymentMethodCubit(profileMetadata: counterparty)..load(),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EscrowSelectorWidget(),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // TextButton(
                //   onPressed: () {
                //     print('Pay directly');
                //   },
                //   child: const Text('Pay directly'),
                // ),
                // SizedBox(width: 16),
                BlocBuilder<EscrowSelectorCubit, EscrowSelectorState>(
                  builder: (context, state) {
                    switch (state) {
                      case EscrowSelectorLoading():
                        return const CircularProgressIndicator();
                      case EscrowSelectorError():
                        return Text(state.message);
                      case EscrowSelectorLoaded():
                        return FilledButton(
                          onPressed: () =>
                              context.read<EscrowSelectorCubit>().select(),
                          child: const Text('Use Escrow'),
                        );
                      default:
                        throw UnimplementedError();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
