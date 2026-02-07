import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow/escrow_cubit.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap.dart';

import '../modal_bottom_sheet.dart';

class EscrowFlowWidget extends StatelessWidget {
  final EscrowCubit cubit;
  const EscrowFlowWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<EscrowCubit, EscrowState>(
        builder: (context, state) {
          switch (state) {
            case EscrowInitialised():
              return EscrowConfirmWidget(onConfirm: () => cubit.confirm());
            case EscrowSwapProgress():
              return EscrowProgressWidget(state);
            case EscrowCompleted():
              return EscrowSuccessWidget(state);
            case EscrowFailed():
              return EscrowFailureWidget(state);
          }
        },
      ),
    );
  }
}

class EscrowConfirmWidget extends StatelessWidget {
  final VoidCallback onConfirm;
  const EscrowConfirmWidget({required this.onConfirm, super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: 'Deposit Funds',
      content: AmountWidget(
        toPubkey: context.read<EscrowCubit>().params.escrowService.pubKey,
        amount: context.read<EscrowCubit>().params.amount,
        onConfirm: onConfirm,
      ),
    );
  }
}

class EscrowProgressWidget extends StatelessWidget {
  final EscrowSwapProgress progress;
  const EscrowProgressWidget(this.progress, {super.key});

  @override
  Widget build(BuildContext context) {
    return SwapViewWidget(progress.swapState);
  }
}

class EscrowTradeProgressWidget extends StatelessWidget {
  const EscrowTradeProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Text('Escrow trade in progress...'),
    );
  }
}

class EscrowSuccessWidget extends StatelessWidget {
  final EscrowCompleted state;
  const EscrowSuccessWidget(this.state, {super.key});

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

class EscrowFailureWidget extends StatelessWidget {
  final EscrowFailed state;
  const EscrowFailureWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      title: 'Escrow Failed',
      content: Text(state.error.toString()),
    );
  }
}
