import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A single step within a flow.
abstract class FlowStep {
  String get id;

  Widget build(BuildContext context);
}

/// Defines a flow: a sequence of steps that can include subflows.
abstract class FlowDefinition {
  String get id;

  /// Build the initial list of steps for this flow.
  List<FlowStep> buildSteps();
}

/// State emitted by FlowHost cubit.
class FlowState {
  final FlowStep? currentStep;

  FlowState({required this.currentStep});

  FlowState copyWith({FlowStep? currentStep}) =>
      FlowState(currentStep: currentStep ?? this.currentStep);
}

/// Manages flow state: steps within flows and nested subflows.
class FlowHost extends Cubit<FlowState> {
  FlowHost(this._onClose) : super(FlowState(currentStep: null));

  final VoidCallback _onClose;
  final List<_FlowStackEntry> _stack = [];

  FlowStep? get currentStep => state.currentStep;

  /// Initialize with the root flow.
  void init(FlowDefinition flow) {
    if (_stack.isNotEmpty) return;
    _stack.add(_FlowStackEntry(flow));
    emit(FlowState(currentStep: _stack.last.currentStep));
  }

  /// Advance to the next step in the current flow.
  void onNext() {
    if (_stack.isEmpty) return;
    _stack.last.advance();
    emit(FlowState(currentStep: _stack.last.currentStep));
  }

  /// Go back to the previous step, or pop this flow if at the first step.
  void onBack() {
    if (_stack.isEmpty) return;

    // Try to go back within current flow
    if (_stack.last.canGoBack) {
      _stack.last.goBack();
      emit(FlowState(currentStep: _stack.last.currentStep));
      return;
    }

    // Pop this flow if it's a subflow
    if (_stack.length > 1) {
      _stack.removeLast();
      emit(FlowState(currentStep: _stack.last.currentStep));
      return;
    }

    // Root flow, no more steps to go back to
    close();
  }

  /// Push a new flow on top of the stack (subflow).
  Future<void> pushFlow(FlowDefinition flow) async {
    _stack.add(_FlowStackEntry(flow));
    emit(FlowState(currentStep: _stack.last.currentStep));
  }

  /// Close the entire flow modal.
  @override
  Future<void> close() async {
    await super.close();
    _onClose();
  }
}

/// Internal helper: tracks a flow's step position.
class _FlowStackEntry {
  _FlowStackEntry(this.flow) : steps = flow.buildSteps();

  final FlowDefinition flow;
  final List<FlowStep> steps;
  int index = 0;

  FlowStep get currentStep => steps[index];
  bool get canGoBack => index > 0;

  void advance() {
    if (index < steps.length - 1) index++;
  }

  void goBack() {
    if (index > 0) index--;
  }
}
