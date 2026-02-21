import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
