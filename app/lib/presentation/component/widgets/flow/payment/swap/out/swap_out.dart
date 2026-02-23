import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/ui/asymptotic_progress_bar.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../../../amount/amount_input.dart';
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
          return SwapOutViewWidget(
            state,
            onConfirm: () => cubit.execute(),
            onSubmitInvoice: cubit.submitExternalInvoice,
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
        return const SwapOutFailureWidget('Swap failed.');
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
      title: 'Withdraw Funds',
      content: FutureBuilder<SwapOutFees>(
        future: _feesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to estimate fees: ${snapshot.error}',
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

  String get _subtitle {
    switch (state) {
      case SwapOutInvoiceCreated():
        return 'Invoice created, processing...';
      case SwapOutAwaitingOnChain():
        return 'Waiting for transaction to confirm...';
      case SwapOutFunded():
        return 'Swap funded, waiting for payment...';
      case SwapOutClaimed():
        return 'Swap claimed, finalising...';
      case SwapOutRefunding():
        return 'Processing refund...';
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

class SwapOutSuccessWidget extends StatelessWidget {
  final SwapOutCompleted state;
  const SwapOutSuccessWidget(this.state, {super.key});

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

class SwapOutRefundedWidget extends StatelessWidget {
  const SwapOutRefundedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      title: 'Swap Refunded',
      subtitle: 'Swap refunded successfully.',
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
      title: 'Swap Failed',
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
      setState(() => _error = 'Please paste a Lightning invoice.');
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
            'Create a Lightning invoice for exactly '
            '${widget.invoiceAmount.getInSats} sats '
            'in your wallet and paste it below.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Lightning Invoice',
              hintText: 'lnbc…',
              errorText: _error,
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                onPressed: _paste,
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submit, child: const Text('Continue')),
        ],
      ),
    );
  }
}
