When money moves in the app:

1. Zaps

2. Direct payments (include refund)

3. Swap in

4. Swap out

5. EVM payment

6. Select an escrow

Sometimes an amount will be able to be settable, sometimes a comment will be settable.

Each payment type should have it's own PaymentCubit.
Each payment type should have it's own UI flow.
They should be composable:

    ReservationPaymentFlow:

    - Select an escrow
        - a: Direct payment (subflow)
        - b:
            - Swap in
            - EVM payment

---

# Minimal flow interfaces (Cubits + UI)

These are minimal, composable interfaces to drive flows in `showBottomModal`, advance step-by-step, allow subflows, and support back navigation.

## Core flow contracts

```dart
/// A single UI step within a flow.
abstract interface class PaymentFlowStep {
    /// Unique stable id for back navigation + analytics.
    String get id;

    /// Render the step. The step can call `onNext`/`onBack` via context.
    Widget build(BuildContext context);
}

/// A flow is a stack of steps that can include subflows.
abstract interface class PaymentFlow {
    String get id;

    /// Initial steps or lazily provided steps.
    List<PaymentFlowStep> buildSteps();
}

/// Host that renders the current step inside showBottomModal.
abstract interface class PaymentFlowHost {
    /// Push a new flow on top (subflow).
    Future<void> pushFlow(PaymentFlow flow);

    /// Complete the current step and move forward.
    void next();

    /// Go back to the previous step (or pop subflow if at first step).
    void back();

    /// Close the modal.
    void close();

    /// Build the current step UI.
    Widget build(BuildContext context);
}
```

## Minimal cubit contract

```dart
/// Every payment type gets its own cubit.
abstract interface class PaymentCubit {
    /// Start the flow (typically injected into a `PaymentFlow` instance).
    Future<void> start();

    /// Called by UI when user advances to next step.
    Future<void> onNext();

    /// Called by UI when user goes back.
    Future<void> onBack();

    /// Optional: cancel flow.
    Future<void> cancel();
}
```

## Minimal UI flow contract

```dart
/// Flow wrapper rendered by showBottomModal.
class PaymentFlowSheet extends StatelessWidget {
    const PaymentFlowSheet({super.key, required this.host});

    final PaymentFlowHost host;

    @override
    Widget build(BuildContext context) {
        // Host decides which step to show and handles back/next.
        return host.build(context);
    }
}
```

## Flow composition (example wiring)

```dart
class ReservationPaymentFlow implements PaymentFlow {
    @override
    String get id => 'reservation-payment';

    @override
    List<PaymentFlowStep> buildSteps() => [
                SelectEscrowStep(
                    onDirectPayment: (host) => host.pushFlow(DirectPaymentFlow()),
                    onSwapIn: (host) => host.pushFlow(SwapInFlow()),
                    onEvmPayment: (host) => host.pushFlow(EvmPaymentFlow()),
                ),
            ];
}
```

## Expanded, minimal working sketch (flow host + steps + cubit)

```dart
class PaymentFlowHostImpl implements PaymentFlowHost {
    PaymentFlowHostImpl(this.rootFlow);

    final PaymentFlow rootFlow;
    final List<_FlowStackEntry> _stack = [];
    final ValueNotifier<PaymentFlowStep?> _currentStep = ValueNotifier(null);

    PaymentFlowStep get _step => _currentStep.value!;

    void _initIfNeeded() {
        if (_stack.isEmpty) {
            _stack.add(_FlowStackEntry(rootFlow));
            _currentStep.value = _stack.last.currentStep;
        }
    }

    @override
    Widget build(BuildContext context) {
        _initIfNeeded();
        return ValueListenableBuilder<PaymentFlowStep?>(
            valueListenable: _currentStep,
            builder: (context, step, _) {
                if (step == null) return const SizedBox.shrink();
                return step.build(context);
            },
        );
    }

    @override
    Future<void> pushFlow(PaymentFlow flow) async {
        _stack.add(_FlowStackEntry(flow));
        _currentStep.value = _stack.last.currentStep;
    }

    @override
    void next() {
        _stack.last.advance();
        _currentStep.value = _stack.last.currentStep;
    }

    @override
    void back() {
        if (_stack.last.canGoBack) {
            _stack.last.goBack();
            _currentStep.value = _stack.last.currentStep;
            return;
        }
        if (_stack.length > 1) {
            _stack.removeLast();
            _currentStep.value = _stack.last.currentStep;
            return;
        }
        close();
    }

    @override
    void close() {
        // Call Navigator.pop in real code.
    }
}

class _FlowStackEntry {
    _FlowStackEntry(this.flow) : steps = flow.buildSteps();

    final PaymentFlow flow;
    final List<PaymentFlowStep> steps;
    int index = 0;

    PaymentFlowStep get currentStep => steps[index];
    bool get canGoBack => index > 0;

    void advance() {
        if (index < steps.length - 1) index++;
    }

    void goBack() {
        if (index > 0) index--;
    }
}

class SelectEscrowStep implements PaymentFlowStep {
    SelectEscrowStep({
        required this.onDirectPayment,
        required this.onSwapIn,
        required this.onEvmPayment,
    });

    final void Function(PaymentFlowHost host) onDirectPayment;
    final void Function(PaymentFlowHost host) onSwapIn;
    final void Function(PaymentFlowHost host) onEvmPayment;

    @override
    String get id => 'select-escrow';

    @override
    Widget build(BuildContext context) {
        final host = context.read<PaymentFlowHost>();
        return Column(
            children: [
                ListTile(
                    title: const Text('Direct payment'),
                    onTap: () => onDirectPayment(host),
                ),
                ListTile(
                    title: const Text('Swap in'),
                    onTap: () => onSwapIn(host),
                ),
                ListTile(
                    title: const Text('EVM payment'),
                    onTap: () => onEvmPayment(host),
                ),
            ],
        );
    }
}

class DirectPaymentFlow implements PaymentFlow {
    @override
    String get id => 'direct-payment';

    @override
    List<PaymentFlowStep> buildSteps() => [
                DirectPaymentAmountStep(),
                DirectPaymentConfirmStep(),
            ];
}

class DirectPaymentAmountStep implements PaymentFlowStep {
    @override
    String get id => 'direct-payment-amount';

    @override
    Widget build(BuildContext context) {
        final host = context.read<PaymentFlowHost>();
        final cubit = context.read<DirectPaymentCubit>();
        return Column(
            children: [
                const Text('Enter amount'),
                ElevatedButton(
                    onPressed: () async {
                        await cubit.onNext();
                        host.next();
                    },
                    child: const Text('Continue'),
                ),
            ],
        );
    }
}

class DirectPaymentConfirmStep implements PaymentFlowStep {
    @override
    String get id => 'direct-payment-confirm';

    @override
    Widget build(BuildContext context) {
        final host = context.read<PaymentFlowHost>();
        final cubit = context.read<DirectPaymentCubit>();
        return Column(
            children: [
                const Text('Confirm payment'),
                ElevatedButton(
                    onPressed: () async {
                        await cubit.onNext();
                        host.close();
                    },
                    child: const Text('Pay'),
                ),
                TextButton(
                    onPressed: () async {
                        await cubit.onBack();
                        host.back();
                    },
                    child: const Text('Back'),
                ),
            ],
        );
    }
}

class DirectPaymentCubit implements PaymentCubit {
    @override
    Future<void> start() async {}

    @override
    Future<void> onNext() async {}

    @override
    Future<void> onBack() async {}

    @override
    Future<void> cancel() async {}
}
```

## Back navigation expectations

- `host.back()` moves to previous step.
- If current flow has no previous step, `host.back()` pops the subflow.
- UI should expose back action (e.g., leading icon in the modal header).

## showBottomModal usage (minimal)

```dart
Future<void> startPaymentFlow(BuildContext context, PaymentFlow flow) async {
    await showBottomModal(
        context: context,
        builder: (_) => PaymentFlowSheet(host: PaymentFlowHostImpl(flow)),
    );
}
```
