import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../../../amount/amount_input.dart';
import '../../../modal_bottom_sheet.dart';

class SwapOutFlowWidget extends StatefulWidget {
  final SwapOutOperation cubit;
  const SwapOutFlowWidget({super.key, required this.cubit});

  @override
  State<SwapOutFlowWidget> createState() => _SwapOutFlowWidgetState();
}

class _SwapOutFlowWidgetState extends State<SwapOutFlowWidget> {
  @override
  void dispose() {
    // Allow in-flight swaps to complete before closing the cubit.
    widget.cubit.detachOrClose(
      (s) =>
          s is SwapOutCompleted || s is SwapOutRefunded || s is SwapOutFailed,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<SwapOutOperation, SwapOutState>(
        builder: (context, state) {
          return SwapOutViewWidget(
            state,
            onConfirm: () => widget.cubit.execute(),
            onSubmitInvoice: widget.cubit.submitExternalInvoice,
          );
        },
      ),
    );
  }
}

class SwapOutViewWidget extends StatelessWidget {
  final SwapOutState state;
  final VoidCallback? onConfirm;
  final ValueChanged<String>? onSubmitInvoice;
  const SwapOutViewWidget(
    this.state, {
    super.key,
    this.onConfirm,
    this.onSubmitInvoice,
  });

  @override
  build(BuildContext context) {
    switch (state) {
      case SwapOutInitialised():
        return SwapOutConfirmWidget(onConfirm: onConfirm ?? () {});
      case SwapOutRequestCreated():
        return SwapOutConfirmWidget(
          onConfirm: onConfirm ?? () {},
          loading: true,
        );
      case SwapOutExternalInvoiceRequired(:final invoiceAmount):
        return SwapOutExternalInvoiceWidget(
          invoiceAmount: invoiceAmount,
          onSubmit: onSubmitInvoice ?? (_) {},
        );
      case SwapOutInvoiceCreated():
        return SwapOutProgressWidget(state);
      case SwapOutPaymentProgress():
        return SwapOutPaymentProgressWidget(state as SwapOutPaymentProgress);
      case SwapOutCompleted():
        return SwapOutSuccessWidget(state as SwapOutCompleted);
      case SwapOutFailed():
        return SwapOutFailureWidget((state as SwapOutFailed).error.toString());
      case SwapOutAwaitingOnChain():
      case SwapOutFunded():
      case SwapOutClaimed():
      case SwapOutRefunding():
        return SwapOutProgressWidget(state);
      case SwapOutRefunded():
        return SwapOutRefundedWidget();
    }
  }
}

class SwapOutConfirmWidget extends StatefulWidget {
  final VoidCallback onConfirm;
  final bool loading;
  const SwapOutConfirmWidget({
    required this.onConfirm,
    this.loading = false,
    super.key,
  });

  @override
  State<SwapOutConfirmWidget> createState() => _SwapOutConfirmWidgetState();
}

class _SwapOutConfirmWidgetState extends State<SwapOutConfirmWidget> {
  late final Future<SwapOutFees> _feesFuture;

  @override
  void initState() {
    super.initState();
    _feesFuture = context.read<SwapOutOperation>().estimateFees();
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: AppLocalizations.of(context)!.withdrawFundsTitle,
      content: FutureBuilder<SwapOutFees>(
        future: _feesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppLoadingIndicator.large());
          }

          if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.errorGeneric('Failed to estimate fees: ${snapshot.error}'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          }

          final fees = snapshot.data!;
          final baseStyle = Theme.of(context).textTheme.bodySmall!;
          final subtleStyle = baseStyle.copyWith(
            fontWeight: FontWeight.w400,
            color: baseStyle.color?.withValues(alpha: 0.6),
          );

          return AmountWidget(
            amount: fees.invoiceAmount.toAmount(),
            feeWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "+ ${formatAmount(fees.estimatedGasFees.toAmount())} in gas",
                  style: subtleStyle,
                ),
                Text(
                  "+ ${formatAmount(fees.estimatedSwapFees.toAmount())} in swap fees",
                  style: subtleStyle,
                ),
              ],
            ),
            loading: widget.loading,
            onConfirm: widget.onConfirm,
          );
        },
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

  String _subtitle(AppLocalizations l10n) {
    switch (state) {
      case SwapOutInvoiceCreated():
        return l10n.swapStatusInvoiceCreatedProcessing;
      case SwapOutAwaitingOnChain():
        return l10n.swapStatusWaitingForTransactionConfirm;
      case SwapOutFunded():
        return l10n.swapStatusFundedWaitingForPayment;
      case SwapOutClaimed():
        return l10n.swapStatusClaimedFinalising;
      case SwapOutRefunding():
        return l10n.swapStatusProcessingRefund;
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

class SwapOutSuccessWidget extends StatelessWidget {
  final SwapOutCompleted state;
  const SwapOutSuccessWidget(this.state, {super.key});

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

class SwapOutRefundedWidget extends StatelessWidget {
  const SwapOutRefundedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      title: AppLocalizations.of(context)!.swapRefundedTitle,
      subtitle: AppLocalizations.of(context)!.swapRefundedSubtitle,
      content: Container(),
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
      title: AppLocalizations.of(context)!.swapFailedTitle,
      content: Text(error),
    );
  }
}

class SwapOutExternalInvoiceWidget extends StatefulWidget {
  final BitcoinAmount invoiceAmount;
  final ValueChanged<String> onSubmit;

  const SwapOutExternalInvoiceWidget({
    required this.invoiceAmount,
    required this.onSubmit,
    super.key,
  });

  @override
  State<SwapOutExternalInvoiceWidget> createState() =>
      _SwapOutExternalInvoiceWidgetState();
}

class _SwapOutExternalInvoiceWidgetState
    extends State<SwapOutExternalInvoiceWidget> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final invoice = _controller.text.trim();
    if (invoice.isEmpty) {
      setState(
        () => _error = AppLocalizations.of(
          context,
        )!.pasteLightningInvoiceRequired,
      );
      return;
    }
    setState(() => _error = null);
    widget.onSubmit(invoice);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.swapOutExternalInvoiceInstructions(
              widget.invoiceAmount.getInSats.toInt(),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Gap.vertical.md(),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.lightningInvoiceLabel,
              hintText: AppLocalizations.of(context)!.lightningInvoiceHint,
              errorText: _error,
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                onPressed: _paste,
              ),
            ),
            maxLines: 3,
          ),
          Gap.vertical.md(),
          FilledButton(
            onPressed: _submit,
            child: Text(AppLocalizations.of(context)!.continueButton),
          ),
        ],
      ),
    );
  }
}
