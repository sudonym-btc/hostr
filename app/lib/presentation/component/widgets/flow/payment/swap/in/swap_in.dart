import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../../../amount/amount_input.dart';
import '../../../modal_bottom_sheet.dart';

class SwapInFlowWidget extends StatefulWidget {
  final SwapInOperation cubit;
  const SwapInFlowWidget({super.key, required this.cubit});

  @override
  State<SwapInFlowWidget> createState() => _SwapInFlowWidgetState();
}

class _SwapInFlowWidgetState extends State<SwapInFlowWidget> {
  @override
  void initState() {
    super.initState();
    widget.cubit.init();
  }

  @override
  void dispose() {
    // Allow in-flight swaps to complete before closing the cubit.
    widget.cubit.detachOrClose(
      (s) => s is SwapInCompleted || s is SwapInFailed,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<SwapInOperation, SwapInState>(
        builder: (context, state) {
          return SwapInViewWidget(
            state,
            onConfirm: () async => widget.cubit.execute(),
          );
        },
      ),
    );
  }
}

class SwapInViewWidget extends StatelessWidget {
  final SwapInState state;
  final Future<void> Function()? onConfirm;
  const SwapInViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    switch (state) {
      case SwapInInitialised():
        return SwapInConfirmWidget(onConfirm: onConfirm ?? () async {});
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

class SwapInConfirmWidget extends StatefulWidget {
  final Future<void> Function() onConfirm;
  const SwapInConfirmWidget({required this.onConfirm, super.key});

  @override
  State<SwapInConfirmWidget> createState() => _SwapInConfirmWidgetState();
}

class _SwapInConfirmWidgetState extends State<SwapInConfirmWidget> {
  bool _loading = false;

  Future<void> _handleConfirm() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onConfirm();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final operation = context.read<SwapInOperation>();
    final params = operation.params;
    final isEditable =
        params.minAmount != null &&
        params.maxAmount != null &&
        params.minAmount! < params.maxAmount!;

    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: AppLocalizations.of(context)!.swapTitle,
      subtitle: AppLocalizations.of(context)!.swapConfirmSubtitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmountWidget(
            to: params.evmKey.address.eip55With0x,
            amount: params.amount.toAmount(),
            loading: _loading,
            onAmountTap: isEditable
                ? () async {
                    final result = await AmountEditorBottomSheet.show(
                      context,
                      initialAmount: params.amount.toAmount(),
                      minAmount: params.minAmount!.toAmount(),
                      maxAmount: params.maxAmount!.toAmount(),
                    );
                    if (result != null && context.mounted) {
                      operation.updateAmount(BitcoinAmount.fromAmount(result));
                    }
                  }
                : null,
            feeWidget: FutureBuilder(
              future: operation.estimateFees(),
              builder: (context, snapshot) {
                final baseStyle = Theme.of(context).textTheme.bodySmall!;
                final subtleStyle = baseStyle.copyWith(
                  fontWeight: FontWeight.w400,
                  color: baseStyle.color?.withValues(alpha: 0.6),
                );

                if (snapshot.connectionState != ConnectionState.done) {
                  return Text(
                    AppLocalizations.of(context)!.estimatingFees,
                    style: subtleStyle,
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Fee estimation failed',
                    style: subtleStyle.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "+ ${formatAmount(snapshot.data!.estimatedGasFees.toAmount())} in gas",
                      style: subtleStyle,
                    ),
                    Text(
                      "+ ${formatAmount(snapshot.data!.estimatedSwapFees.toAmount())} in swap fees",
                      style: subtleStyle,
                    ),
                    Text(
                      "+ ${formatAmount(snapshot.data!.estimatedRelayFees.toAmount())} in relay fees",
                      style: subtleStyle,
                    ),
                  ],
                );
              },
            ),
            onConfirm: _handleConfirm,
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
