import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../flow.dart';

/// SelectEscrow flow implementation.
class SelectEscrowFlow extends FlowDefinition {
  @override
  String get id => 'select-escrow-flow';

  @override
  List<FlowStep> buildSteps() => [const SelectEscrowStep()];
}

/// Renders the select escrow flow.
class SelectEscrowFlowWidget extends StatefulWidget {
  final VoidCallback onClose;

  const SelectEscrowFlowWidget({super.key, required this.onClose});

  @override
  State<SelectEscrowFlowWidget> createState() => _SelectEscrowFlowWidgetState();
}

class _SelectEscrowFlowWidgetState extends State<SelectEscrowFlowWidget> {
  late FlowHost _flowHost;

  @override
  void initState() {
    super.initState();
    _flowHost = FlowHost(widget.onClose);
    _flowHost.init(SelectEscrowFlow());
  }

  @override
  void dispose() {
    _flowHost.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FlowHost>.value(
      value: _flowHost,
      child: BlocBuilder<FlowHost, FlowState>(
        builder: (context, state) {
          return _SelectEscrowFlowScaffold(
            flowHost: _flowHost,
            child: state.currentStep?.build(context) ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _SelectEscrowFlowScaffold extends StatelessWidget {
  final Widget child;
  final FlowHost flowHost;

  const _SelectEscrowFlowScaffold({
    required this.child,
    required this.flowHost,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class SelectEscrowStep extends StatelessWidget implements FlowStep {
  const SelectEscrowStep({super.key});

  @override
  String get id => 'select-escrow';

  @override
  Widget build(BuildContext context) {
    final flowHost = context.read<FlowHost>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Select an escrow'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            // TODO: Trigger DirectPaymentFlow subflow
            // flowHost.pushFlow(DirectPaymentFlowImpl());
          },
          child: const Text('Direct payment'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            // TODO: Trigger SwapInFlow subflow
            // flowHost.pushFlow(SwapInFlowImpl());
          },
          child: const Text('Swap in'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            // TODO: Trigger EvmPaymentFlow subflow
            // flowHost.pushFlow(EvmPaymentFlowImpl());
          },
          child: const Text('EVM payment'),
        ),
      ],
    );
  }
}
