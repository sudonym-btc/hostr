import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../flow.dart';

/// SwapIn flow implementation.
class SwapInFlow extends FlowDefinition {
  @override
  String get id => 'swap-in-flow';

  @override
  List<FlowStep> buildSteps() => [
    const SwapInAmountStep(),
    const SwapInConfirmStep(),
  ];
}

/// Renders the swap in flow.
class SwapInFlowWidget extends StatefulWidget {
  final VoidCallback onClose;

  const SwapInFlowWidget({super.key, required this.onClose});

  @override
  State<SwapInFlowWidget> createState() => _SwapInFlowWidgetState();
}

class _SwapInFlowWidgetState extends State<SwapInFlowWidget> {
  late FlowHost _flowHost;

  @override
  void initState() {
    super.initState();
    _flowHost = FlowHost(widget.onClose);
    _flowHost.init(SwapInFlow());
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
          return _SwapInFlowScaffold(
            flowHost: _flowHost,
            child: state.currentStep?.build(context) ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _SwapInFlowScaffold extends StatelessWidget {
  final Widget child;
  final FlowHost flowHost;

  const _SwapInFlowScaffold({required this.child, required this.flowHost});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class SwapInAmountStep extends StatelessWidget implements FlowStep {
  const SwapInAmountStep({super.key});

  @override
  String get id => 'swap-in-amount';

  @override
  Widget build(BuildContext context) {
    final flowHost = context.read<FlowHost>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Enter amount to swap in'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            flowHost.onNext();
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class SwapInConfirmStep extends StatelessWidget implements FlowStep {
  const SwapInConfirmStep({super.key});

  @override
  String get id => 'swap-in-confirm';

  @override
  Widget build(BuildContext context) {
    final flowHost = context.read<FlowHost>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Confirm swap in'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            // TODO: Execute swap in
            flowHost.close();
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
