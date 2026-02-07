import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow/operations/fund/escrow_fund_models.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/escrow/fund/escrow_fund.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/escrow/fund/escrow_fund_cubit.dart';
import 'package:models/main.dart';

import '../../modal_bottom_sheet.dart';
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
                          onPressed: () {
                            Navigator.of(context).pop();
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider<EscrowFundCubit>(
                                  create: (BuildContext context) =>
                                      EscrowFundCubit(
                                        EscrowFundParams(
                                          reservationRequest:
                                              reservationRequest,
                                          amount: reservationRequest
                                              .parsedContent
                                              .amount,
                                          sellerProfile: counterparty,
                                          escrowService: state.selectedEscrow,
                                        ),
                                      ),
                                  child: Builder(
                                    builder: (context) {
                                      return EscrowFundWidget(
                                        cubit: context.read<EscrowFundCubit>(),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
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
