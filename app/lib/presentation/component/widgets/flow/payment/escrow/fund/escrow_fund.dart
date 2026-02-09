import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../../modal_bottom_sheet.dart';

class EscrowFundWidget extends StatelessWidget {
  final EscrowFundOperation cubit;
  const EscrowFundWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<EscrowFundOperation, EscrowFundState>(
        builder: (context, state) {
          switch (state) {
            case EscrowFundInitialised():
              return EscrowFundConfirmWidget(onConfirm: () => cubit.execute());
            case EscrowFundSwapProgress():
              return EscrowFundProgressWidget(state);
            case EscrowFundCompleted():
              return EscrowFundSuccessWidget(state);
            case EscrowFundFailed():
              return EscrowFundFailureWidget(state);
          }
        },
      ),
    );
  }
}

class EscrowFundConfirmWidget extends StatelessWidget {
  final VoidCallback onConfirm;
  const EscrowFundConfirmWidget({required this.onConfirm, super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: 'Deposit Funds',
      content: AmountWidget(
        toPubkey: context
            .read<EscrowFundOperation>()
            .params
            .escrowService
            .pubKey,
        amount: context.read<EscrowFundOperation>().params.amount,
        onConfirm: onConfirm,
      ),
    );
  }
}

class EscrowFundProgressWidget extends StatelessWidget {
  final EscrowFundSwapProgress progress;
  const EscrowFundProgressWidget(this.progress, {super.key});

  @override
  Widget build(BuildContext context) {
    return SwapInViewWidget(progress.swapState);
  }
}

class EscrowFundTradeProgressWidget extends StatelessWidget {
  const EscrowFundTradeProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Text('Escrow trade in progress...'),
    );
  }
}

class EscrowFundSuccessWidget extends StatelessWidget {
  final EscrowFundCompleted state;
  const EscrowFundSuccessWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      title: 'Deposit Success',
      subtitle: 'Transaction ID: ${state.transactionInformation.hash}',
      content: Container(),
    );
  }
}

class EscrowFundFailureWidget extends StatelessWidget {
  final EscrowFundFailed state;
  const EscrowFundFailureWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      title: 'Escrow Failed',
      content: Text(state.error.toString()),
    );
  }
}
