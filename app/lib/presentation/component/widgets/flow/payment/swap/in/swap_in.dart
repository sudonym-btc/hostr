import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
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
        return SwapInFailureWidget((state as SwapInFailed).error.toString());
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
      title: AppLocalizations.of(context)!.swapTitle,
      subtitle: AppLocalizations.of(context)!.swapConfirmSubtitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: onConfirm,
            child: Text(AppLocalizations.of(context)!.confirmButton),
          ),
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

  String _subtitle(AppLocalizations l10n) {
    switch (state) {
      case SwapInAwaitingOnChain():
        return l10n.swapStatusWaitingForTransactionConfirm;
      case SwapInFunded():
        return l10n.swapStatusFundedClaiming;
      case SwapInClaimed():
        return l10n.swapStatusClaimedFinalising;
      case SwapInRequestCreated():
        return l10n.swapStatusRequestCreated;
      default:
        return l10n.swapStatusProcessingYourSwap;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: AppLocalizations.of(context)!.swapProgressTitle,
      subtitle: _subtitle(AppLocalizations.of(context)!),
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

class SwapInSuccessWidget extends StatelessWidget {
  final SwapInCompleted state;
  const SwapInSuccessWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      title: AppLocalizations.of(context)!.swapCompleteTitle,
      subtitle: AppLocalizations.of(context)!.swapCompleteSubtitle,
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
      title: AppLocalizations.of(context)!.swapFailedTitle,
      content: Text(error),
    );
  }
}
