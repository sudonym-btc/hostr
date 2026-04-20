import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import '../../../../amount/amount_input.dart';
import '../../../modal_bottom_sheet.dart';

class SwapInFlowWidget extends StatefulWidget {
  final SwapInOperation cubit;

  /// Optional overrides for the flow titles.
  final String? progressTitle;
  final String? successTitle;
  final String? errorTitle;

  const SwapInFlowWidget({
    super.key,
    required this.cubit,
    this.progressTitle,
    this.successTitle,
    this.errorTitle,
  });

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
            progressTitle: widget.progressTitle,
            successTitle: widget.successTitle,
            errorTitle: widget.errorTitle,
          );
        },
      ),
    );
  }
}

class SwapInViewWidget extends StatelessWidget {
  final SwapInState state;
  final Future<void> Function()? onConfirm;

  /// Optional overrides for the flow titles.
  final String? progressTitle;
  final String? successTitle;
  final String? errorTitle;

  const SwapInViewWidget(
    this.state, {
    super.key,
    this.onConfirm,
    this.progressTitle,
    this.successTitle,
    this.errorTitle,
  });

  @override
  build(BuildContext context) {
    switch (state) {
      case SwapInInitialised():
        return SwapInConfirmWidget(onConfirm: onConfirm ?? () async {});
      case SwapInPaymentProgress():
        return SwapInPaymentProgressWidget(state as SwapInPaymentProgress);
      case SwapInCompleted():
        return SwapInSuccessWidget(
          state as SwapInCompleted,
          title: successTitle,
        );
      case SwapInFailed():
        return SwapInFailureWidget(
          (state as SwapInFailed).error.toString(),
          title: errorTitle,
        );
      case SwapInInvoicePaid():
      case SwapInLockupTxInMempool():
      case SwapInAwaitingOnChain():
      case SwapInFunded():
      case SwapInClaimed():
      case SwapInClaimTxInMempool():
      case SwapInRequestCreated():
      case SwapInPaymentDispatching():
      case SwapInClaimRelaying():
        return SwapInProgressWidget(state, title: progressTitle);
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
            amount: params.amount.toDenominated(),
            loading: _loading,
            onAmountTap: isEditable
                ? () async {
                    final result = await AmountEditorBottomSheet.show(
                      context,
                      initialAmount: params.amount.toDenominated(),
                      minAmount: params.minAmount!.toDenominated(),
                      maxAmount: params.maxAmount!.toDenominated(),
                    );
                    if (result != null && context.mounted) {
                      operation.updateAmount(
                        TokenAmount.fromDenominated(
                          result,
                          params.amount.token,
                        ),
                      );
                    }
                  }
                : null,
            feeWidget: FutureBuilder<SwapQuote>(
              future: operation.chain.swapInQuote(params: operation.params),
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

                final fees = snapshot.data!.feeBreakdown;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "+ ${formatAmount(fees.networkFees)} in network fees"
                      "${fees.gasSponsored ? ' (gas sponsored)' : ''}",
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
    final payState = state.paymentState;
    if (payState == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PaymentViewWidget(payState);
  }
}

class SwapInProgressWidget extends StatelessWidget {
  final SwapInState state;
  final String? title;
  const SwapInProgressWidget(this.state, {super.key, this.title});

  String _subtitle(AppLocalizations l10n) {
    switch (state) {
      case SwapInInvoicePaid():
        return l10n.swapStatusInvoicePaidWaitingForTransaction;
      case SwapInLockupTxInMempool():
        return l10n.swapStatusWaitingForTransactionConfirm;
      case SwapInAwaitingOnChain():
        return l10n.swapStatusWaitingForTransactionConfirm;
      case SwapInFunded():
        return l10n.swapStatusFundedClaiming;
      case SwapInClaimed():
        return l10n.swapStatusClaimedFinalising;
      case SwapInClaimTxInMempool():
        return l10n.swapStatusClaimTxInMempool;
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
      title: title ?? AppLocalizations.of(context)!.swapProgressTitle,
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
  final String? title;
  const SwapInSuccessWidget(this.state, {super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      title: title ?? AppLocalizations.of(context)!.swapCompleteTitle,
      subtitle: AppLocalizations.of(context)!.swapCompleteSubtitle,
      content: Container(),
    );
  }
}

class SwapInFailureWidget extends StatelessWidget {
  final String error;
  final String? title;
  const SwapInFailureWidget(this.error, {super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      title: title ?? AppLocalizations.of(context)!.swapFailedTitle,
      content: Text(error),
    );
  }
}
