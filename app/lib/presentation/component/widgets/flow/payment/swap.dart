import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/swap/swap_cubit.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';

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
          return SwapViewWidget(state, onConfirm: () => cubit.confirm());
        },
      ),
    );
  }
}

class SwapViewWidget extends StatelessWidget {
  final SwapState state;
  final VoidCallback? onConfirm;
  const SwapViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    switch (state) {
      case SwapInitialised():
        return SwapConfirmWidget(onConfirm: onConfirm ?? () {});
      case SwapPaymentProgress():
        return SwapPaymentProgressWidget(state as SwapPaymentProgress);
      case SwapCompleted():
        return SwapSuccessWidget(state as SwapCompleted);
      case SwapFailed():
        return const SwapFailureWidget('Swap failed.');
      case SwapAwaitingOnChain():
      case SwapFunded():
      case SwapClaimed():
      case SwapRequestCreated():
        return SwapProgressWidget(state);
    }
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

class SwapPaymentProgressWidget extends StatelessWidget {
  final SwapPaymentProgress state;
  const SwapPaymentProgressWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return PaymentViewWidget(state.paymentState);
  }
}

class SwapProgressWidget extends StatelessWidget {
  final SwapState state;
  const SwapProgressWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Center(child: CircularProgressIndicator()),
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
