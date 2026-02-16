import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../../modal_bottom_sheet.dart';

class SwapOutFlowWidget extends StatelessWidget {
  final SwapOutOperation cubit;
  const SwapOutFlowWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<SwapOutOperation, SwapOutState>(
        builder: (context, state) {
          return SwapOutViewWidget(state, onConfirm: () => cubit.execute());
        },
      ),
    );
  }
}

class SwapOutViewWidget extends StatelessWidget {
  final SwapOutState state;
  final VoidCallback? onConfirm;
  const SwapOutViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    switch (state) {
      case SwapOutInitialised():
        return SwapOutConfirmWidget(onConfirm: onConfirm ?? () {});
      case SwapOutPaymentProgress():
        return SwapOutPaymentProgressWidget(state as SwapOutPaymentProgress);
      case SwapOutCompleted():
        return SwapOutSuccessWidget(state as SwapOutCompleted);
      case SwapOutFailed():
        return const SwapOutFailureWidget('Swap failed.');
      case SwapOutAwaitingOnChain():
      case SwapOutFunded():
      case SwapOutClaimed():
      case SwapOutRequestCreated():
        return SwapOutProgressWidget(state);
    }
  }
}

class SwapOutConfirmWidget extends StatelessWidget {
  final VoidCallback onConfirm;
  const SwapOutConfirmWidget({required this.onConfirm, super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Column(
        children: [
          Text('Please confirm to proceed with the swap.'),
          ElevatedButton(onPressed: onConfirm, child: Text('Confirm')),
        ],
      ),
    );
  }
}

class SwapOutPaymentProgressWidget extends StatelessWidget {
  final SwapOutPaymentProgress state;
  const SwapOutPaymentProgressWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return PaymentViewWidget(state.paymentState);
  }
}

class SwapOutProgressWidget extends StatelessWidget {
  final SwapOutState state;
  const SwapOutProgressWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Center(child: CircularProgressIndicator()),
    );
  }
}

class SwapOutSuccessWidget extends StatelessWidget {
  final SwapOutCompleted state;
  const SwapOutSuccessWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      content: Text('Swap completed!'),
    );
  }
}

class SwapOutFailureWidget extends StatelessWidget {
  final String error;
  const SwapOutFailureWidget(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      content: Text('Swap failed: $error'),
    );
  }
}
