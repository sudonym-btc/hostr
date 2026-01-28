import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/payment/payment.cubit.dart';

import '../flow.dart';

/// Payment flow implementation that defines the sequence of payment steps.
class PaymentFlow extends FlowDefinition {
  @override
  String get id => 'payment-flow';

  @override
  List<FlowStep> buildSteps() => [
    const PaymentResolveStep(),
    const PaymentOkStep(),
    const PaymentConfirmStep(),
  ];
}

/// Renders the payment flow using FlowHost for step navigation.
class PaymentFlowWidget extends StatefulWidget {
  final PaymentCubit paymentCubit;
  final VoidCallback onClose;

  const PaymentFlowWidget({
    super.key,
    required this.paymentCubit,
    required this.onClose,
  });

  @override
  State<PaymentFlowWidget> createState() => _PaymentFlowWidgetState();
}

class _PaymentFlowWidgetState extends State<PaymentFlowWidget> {
  late FlowHost _flowHost;

  @override
  void initState() {
    super.initState();
    _flowHost = FlowHost(widget.onClose);
    _flowHost.init(PaymentFlow());
  }

  @override
  void dispose() {
    _flowHost.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaymentCubit>.value(
      value: widget.paymentCubit,
      child: BlocProvider<FlowHost>.value(
        value: _flowHost,
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            return _PaymentFlowScaffold(
              flowHost: _flowHost,
              child: _buildStepForPaymentState(context, state),
            );
          },
        ),
      ),
    );
  }

  /// Map payment cubit state to the appropriate step, or render the default step.
  Widget _buildStepForPaymentState(BuildContext context, PaymentState state) {
    switch (state.status) {
      case PaymentStatus.resolveInitiated:
      case PaymentStatus.callbackInitiated:
      case PaymentStatus.inFlight:
        return const PaymentLoadingStep();
      case PaymentStatus.completed:
        return const PaymentCompletedStep();
      case PaymentStatus.failed:
        return PaymentFailedStep(error: state.error);
      default:
        return _flowHost.currentStep?.build(context) ?? const SizedBox.shrink();
    }
  }
}

class _PaymentFlowScaffold extends StatelessWidget {
  final Widget child;
  final FlowHost flowHost;

  const _PaymentFlowScaffold({required this.child, required this.flowHost});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class PaymentResolveStep extends StatelessWidget implements FlowStep {
  const PaymentResolveStep({super.key});

  @override
  String get id => 'payment-resolve';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentCubit>();
    final flowHost = context.read<FlowHost>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Ready to pay'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            cubit.resolve();
            flowHost.onNext();
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class PaymentOkStep extends StatelessWidget implements FlowStep {
  const PaymentOkStep({super.key});

  @override
  String get id => 'payment-ok';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentCubit>();
    final flowHost = context.read<FlowHost>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Review'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            cubit.ok();
            flowHost.onNext();
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class PaymentConfirmStep extends StatelessWidget implements FlowStep {
  const PaymentConfirmStep({super.key});

  @override
  String get id => 'payment-confirm';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentCubit>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Confirm payment'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            cubit.confirm();
          },
          child: const Text('Pay'),
        ),
      ],
    );
  }
}

class PaymentLoadingStep extends StatelessWidget implements FlowStep {
  const PaymentLoadingStep({super.key});

  @override
  String get id => 'payment-loading';

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class PaymentCompletedStep extends StatelessWidget implements FlowStep {
  const PaymentCompletedStep({super.key});

  @override
  String get id => 'payment-completed';

  @override
  Widget build(BuildContext context) {
    final flowHost = context.read<FlowHost>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Payment completed'),
        const SizedBox(height: 12),
        FilledButton(onPressed: flowHost.close, child: const Text('Done')),
      ],
    );
  }
}

class PaymentFailedStep extends StatelessWidget implements FlowStep {
  final String? error;

  const PaymentFailedStep({super.key, this.error});

  @override
  String get id => 'payment-failed';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Payment failed'),
        const SizedBox(height: 8),
        if (error != null) Text(error!, textAlign: TextAlign.center),
      ],
    );
  }
}
