import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/swap/swap_cubit.dart';

import '../modal_bottom_sheet.dart';

class SwapFlowWidget extends StatelessWidget {
  final SwapCubit cubit;
  const SwapFlowWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<SwapCubit, SwapState>(
        builder: (context, state) {
          switch (state) {
            case SwapInitialised():
              return SwapConfirmWidget(onConfirm: () => cubit.confirm());
            case SwapPaymentProgress():
              return SwapPaymentWidget(state);
            case SwapCompleted():
              return SwapSuccessWidget(state);
            case SwapFailed():
              return const SwapFailureWidget('Swap failed.');
            case SwapAwaitingOnChain():
            case SwapFunded():
            case SwapClaimed():
              throw UnimplementedError();
          }
        },
      ),
    );
  }
}

class SwapConfirmWidget extends StatelessWidget {
  final VoidCallback onConfirm;
  const SwapConfirmWidget({required this.onConfirm, super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Column(
        children: [
          Text('Please confirm to proceed with the escrow.'),
          ElevatedButton(onPressed: onConfirm, child: Text('Confirm')),
        ],
      ),
    );
  }
}

class SwapProgressWidget extends StatelessWidget {
  final SwapPaymentProgress progress;
  const SwapProgressWidget(this.progress, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Column(children: [Text('Swap in progress: $progress')]),
    );
  }
}

class SwapPaymentWidget extends StatelessWidget {
  final SwapPaymentProgress state;
  const SwapPaymentWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Text('Swap trade in progress...'),
    );
  }
}

class SwapSuccessWidget extends StatelessWidget {
  final SwapCompleted state;
  const SwapSuccessWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      content: Text('Swap completed!'),
    );
  }
}

class SwapFailureWidget extends StatelessWidget {
  final String error;
  const SwapFailureWidget(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      content: Text('Swap failed: $error'),
    );
  }
}
