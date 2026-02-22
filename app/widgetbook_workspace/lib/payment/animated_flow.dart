import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/escrow/fund/escrow_fund.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/out/swap_out.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:web3dart/web3dart.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// ═══════════════════════════════════════════════════════════════════════════
// Generic state cycler widget
// ═══════════════════════════════════════════════════════════════════════════

class _StateCyclerWidget<T> extends StatefulWidget {
  final List<(String label, T state)> states;
  final Widget Function(BuildContext context, T state) builder;
  final Duration delay;

  const _StateCyclerWidget({
    required this.states,
    required this.builder,
    this.delay = const Duration(seconds: 3),
    super.key,
  });

  @override
  State<_StateCyclerWidget<T>> createState() => _StateCyclerWidgetState<T>();
}

class _StateCyclerWidgetState<T> extends State<_StateCyclerWidget<T>> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCycling();
  }

  void _startCycling() {
    _timer = Timer.periodic(widget.delay, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.states.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (label, state) = widget.states[_index];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            '${_index + 1}/${widget.states.length}  $label',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Flexible(child: widget.builder(context, state)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mock data
// ═══════════════════════════════════════════════════════════════════════════

PayParameters get _mockPayParams => PayParameters(
  to: 'satoshi@hostr.cc',
  amount: BitcoinAmount.fromInt(BitcoinUnit.sat, 50000),
);

// ═══════════════════════════════════════════════════════════════════════════
// Payment Flow – animated
// ═══════════════════════════════════════════════════════════════════════════

@widgetbook.UseCase(name: 'Animated flow', type: PaymentViewWidget)
Widget paymentAnimatedFlow(BuildContext context) {
  return _StateCyclerWidget<PayState>(
    states: [
      ('Initialised', PayInitialised(params: _mockPayParams)),
      (
        'Resolved',
        PayResolved(
          params: _mockPayParams,
          details: ResolvedDetails(
            minAmount: 1000,
            maxAmount: 1000000,
            commentAllowed: 144,
          ),
          effectiveMinAmount: 1000,
          effectiveMaxAmount: 1000000,
        ),
      ),
      (
        'Callback complete',
        PayCallbackComplete(params: _mockPayParams, details: CallbackDetails()),
      ),
      ('In flight', PayInFlight(params: _mockPayParams)),
      (
        'External required',
        PayExternalRequired(
          params: _mockPayParams,
          callbackDetails: CallbackDetails(),
        ),
      ),
      (
        'Completed',
        PayCompleted(params: _mockPayParams, details: CompletedDetails()),
      ),
      (
        'Failed',
        PayFailed('Invoice expired after 600 seconds', params: _mockPayParams),
      ),
    ],
    builder: (context, state) => PaymentViewWidget(state),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Swap Out Flow – animated
// ═══════════════════════════════════════════════════════════════════════════

@widgetbook.UseCase(name: 'Animated flow', type: SwapOutViewWidget)
Widget swapOutAnimatedFlow(BuildContext context) {
  return _StateCyclerWidget<SwapOutState>(
    states: [
      ('Initialised', const SwapOutInitialised()),
      ('Request created', const SwapOutRequestCreated()),
      (
        'External invoice required',
        SwapOutExternalInvoiceRequired(
          BitcoinAmount.fromInt(BitcoinUnit.sat, 45000),
        ),
      ),
      ('Invoice created', const SwapOutInvoiceCreated('lnbc450u1p...')),
      ('Awaiting on-chain', const SwapOutAwaitingOnChain()),
      ('Funded', const SwapOutFunded()),
      ('Claimed', const SwapOutClaimed()),
      ('Completed', const SwapOutCompleted()),
      ('Failed', const SwapOutFailed('Insufficient EVM balance for swap')),
    ],
    builder: (context, state) => SwapOutViewWidget(state),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Swap In Flow – animated
// ═══════════════════════════════════════════════════════════════════════════

@widgetbook.UseCase(name: 'Animated flow', type: SwapInViewWidget)
Widget swapInAnimatedFlow(BuildContext context) {
  return _StateCyclerWidget<SwapInState>(
    states: [
      ('Initialised', const SwapInInitialised()),
      ('Request created', const SwapInRequestCreated()),
      (
        'Payment progress',
        SwapInPaymentProgress(
          paymentState: PayInFlight(params: _mockPayParams),
        ),
      ),
      ('Awaiting on-chain', const SwapInAwaitingOnChain()),
      ('Funded', const SwapInFunded()),
      ('Claimed', const SwapInClaimed()),
      ('Completed', const SwapInCompleted()),
      (
        'Failed',
        const SwapInFailed('Swap timed out waiting for on-chain confirmation'),
      ),
    ],
    builder: (context, state) => SwapInViewWidget(state),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Escrow Fund Flow – animated
// ═══════════════════════════════════════════════════════════════════════════

@widgetbook.UseCase(name: 'Animated flow', type: EscrowFundProgressWidget)
Widget escrowFundAnimatedFlow(BuildContext context) {
  return _StateCyclerWidget<EscrowFundState>(
    states: [
      ('Initialised', EscrowFundInitialised()),
      (
        'Swap progress – paying',
        EscrowFundSwapProgress(
          SwapInPaymentProgress(
            paymentState: PayInFlight(params: _mockPayParams),
          ),
        ),
      ),
      (
        'Swap progress – awaiting on-chain',
        EscrowFundSwapProgress(const SwapInAwaitingOnChain()),
      ),
      ('Swap progress – funded', EscrowFundSwapProgress(const SwapInFunded())),
      (
        'Swap progress – completed',
        EscrowFundSwapProgress(const SwapInCompleted()),
      ),
      (
        'Completed',
        EscrowFundCompleted(
          transactionInformation: TransactionInformation.fromMap({
            'blockHash':
                '0x0000000000000000000000000000000000000000000000000000000000000000',
            'blockNumber': '0x3039',
            'transactionIndex': '0x0',
            'hash':
                '0x0000000000000000000000000000000000000000000000000000000000000001',
            'from': '0x0000000000000000000000000000000000000001',
            'to': '0x0000000000000000000000000000000000000002',
            'value': '0x0',
            'gasPrice': '0x0',
            'gas': '0x5208',
            'input': '0x',
            'nonce': '0x0',
            'v': '0x1b',
            'r': '0x1',
            's': '0x1',
          }),
        ),
      ),
      ('Failed', EscrowFundFailed('Escrow contract reverted')),
    ],
    builder: (context, state) {
      switch (state) {
        case EscrowFundInitialised():
          return EscrowFundConfirmWidget(onConfirm: () {});
        case EscrowFundSwapProgress():
          return EscrowFundProgressWidget(state);
        case EscrowFundCompleted():
          return EscrowFundSuccessWidget(state);
        case EscrowFundFailed():
          return EscrowFundFailureWidget(state);
      }
    },
  );
}
