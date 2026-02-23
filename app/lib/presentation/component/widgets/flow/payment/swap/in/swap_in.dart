import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/ui/asymptotic_progress_bar.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../../modal_bottom_sheet.dart';

class SwapInFlowWidget extends StatelessWidget {
  final SwapInOperation cubit;
  const SwapInFlowWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<SwapInOperation, SwapInState>(
        builder: (context, state) {
          return SwapInViewWidget(state, onConfirm: () => cubit.execute());
        },
      ),
    );
  }
}

class SwapInViewWidget extends StatelessWidget {
  final SwapInState state;
  final VoidCallback? onConfirm;
  const SwapInViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    switch (state) {
      case SwapInInitialised():
        return SwapInConfirmWidget(onConfirm: onConfirm ?? () {});
      case SwapInPaymentProgress():
        return SwapInPaymentProgressWidget(state as SwapInPaymentProgress);
      case SwapInCompleted():
        return SwapInSuccessWidget(state as SwapInCompleted);
      case SwapInFailed():
        return const SwapInFailureWidget('Swap failed.');
      case SwapInAwaitingOnChain():
      case SwapInFunded():
      case SwapInClaimed():
      case SwapInRequestCreated():
        return SwapInProgressWidget(state);
    }
  }
}

class SwapInConfirmWidget extends StatelessWidget {
  final VoidCallback onConfirm;
  const SwapInConfirmWidget({required this.onConfirm, super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: 'Swap',
      subtitle: 'Please confirm to proceed with the swap.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(onPressed: onConfirm, child: Text('Confirm')),
        ],
      ),
    );
  }
}

class SwapInPaymentProgressWidget extends StatelessWidget {
  final SwapInPaymentProgress state;
  const SwapInPaymentProgressWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return PaymentViewWidget(state.paymentState);
  }
}

class SwapInProgressWidget extends StatelessWidget {
  final SwapInState state;
  const SwapInProgressWidget(this.state, {super.key});

  String get _subtitle {
    switch (state) {
      case SwapInAwaitingOnChain():
        return 'Waiting for transaction to confirm...';
      case SwapInFunded():
        return 'Swap funded, claiming...';
      case SwapInClaimed():
        return 'Swap claimed, finalising...';
      case SwapInRequestCreated():
        return 'Swap request created...';
      default:
        return 'Processing your swap...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: 'Swap Progress',
      subtitle: _subtitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24),
          AsymptoticProgressBar(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SwapInSuccessWidget extends StatelessWidget {
  final SwapInCompleted state;
  const SwapInSuccessWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      title: 'Swap Complete',
      subtitle: 'Your swap has been completed successfully.',
      content: Container(),
    );
  }
}

class SwapInFailureWidget extends StatelessWidget {
  final String error;
  const SwapInFailureWidget(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      title: 'Swap Failed',
      content: Text(error),
    );
  }
}
