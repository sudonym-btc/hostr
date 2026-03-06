import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr/presentation/component/widgets/ui/app_loading_indicator.dart';
import 'package:hostr/presentation/component/widgets/ui/asymptotic_progress_bar.dart';
import 'package:hostr_sdk/usecase/escrow/operations/onchain_operation.dart';

import '../../ui/gap.dart';
import '../modal_bottom_sheet.dart';

class OnchainOperationFlowWidget extends StatefulWidget {
  final OnchainOperation cubit;
  const OnchainOperationFlowWidget({super.key, required this.cubit});

  @override
  State<OnchainOperationFlowWidget> createState() =>
      _OnchainOperationFlowWidgetState();
}

class _OnchainOperationFlowWidgetState
    extends State<OnchainOperationFlowWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Allow in-flight swaps to complete before closing the cubit.
    widget.cubit.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<OnchainOperation, OnchainOperationState>(
        // Hide the swap initialized screen as it will immediately move on to payment required / progress screen
        buildWhen: (previous, current) => current is! OnchainInitialised,
        builder: (context, state) {
          return OnchainOperationViewWidget(
            state,
            onConfirm: () async => widget.cubit.execute(),
          );
        },
      ),
    );
  }
}

class OnchainOperationViewWidget extends StatelessWidget {
  final OnchainOperationState state;
  final Future<void> Function()? onConfirm;
  const OnchainOperationViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    return switch (state) {
      OnchainInitialised() => ModalBottomSheet(
        type: ModalBottomSheetType.normal,
        title: 'Transaction Initialised',
        content: Center(child: AppLoadingIndicator.large()),
      ),
      OnchainTxBroadcast() => OnchainTransactionBroadcastWidget(
        state as OnchainTxBroadcast,
      ),
      OnchainSwapProgress() => OnchainSwapProgressWidget(
        state as OnchainSwapProgress,
      ),
      OnchainTxConfirmed() => OnchainTransactionSuccessWidget(
        state as OnchainTxConfirmed,
      ),
      OnchainError() => OnchainTransactionFailureWidget(state as OnchainError),
    };
  }
}

class OnchainTransactionBroadcastWidget extends StatelessWidget {
  final OnchainTxBroadcast state;
  const OnchainTransactionBroadcastWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: 'Transaction Broadcasted',
      subtitle: 'Waiting for on-chain confirmation...',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap.vertical.custom(kSpace5),
          AsymptoticProgressBar(),
          Gap.vertical.md(),
        ],
      ),
    );
  }
}

class OnchainSwapProgressWidget extends StatelessWidget {
  final OnchainSwapProgress state;
  const OnchainSwapProgressWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return SwapInViewWidget(state.swapState!);
  }
}

class OnchainTransactionSuccessWidget extends StatelessWidget {
  final OnchainTxConfirmed state;
  const OnchainTransactionSuccessWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      title: 'Transaction Success',
      subtitle: 'Your transaction successfully confirmed onchain.',
      content: Container(),
    );
  }
}

class OnchainTransactionFailureWidget extends StatelessWidget {
  final OnchainError state;
  const OnchainTransactionFailureWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      title: 'Transaction Failed',
      content: Text(state.error.toString()),
    );
  }
}
