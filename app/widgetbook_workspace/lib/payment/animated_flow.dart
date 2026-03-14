import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/escrow/fund/escrow_fund.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/onchain_operation.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/out/swap_out.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
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

const _mockSwapInData = SwapInData(
  boltzId: 'mock-swap-in-001',
  preimageHex:
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  preimageHash:
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
  onchainAmountSat: 50000,
  timeoutBlockHeight: 800000,
  chainId: 31,
  accountIndex: 0,
);

const _mockSwapOutData = SwapOutData(
  boltzId: 'mock-swap-out-001',
  invoice: 'lnbc450u1p...',
  invoicePreimageHashHex:
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
  claimAddress: '0x0000000000000000000000000000000000000001',
  lockedAmountWeiHex: '0xC350',
  lockerAddress: '0x0000000000000000000000000000000000000002',
  timeoutBlockHeight: 800000,
  chainId: 31,
  accountIndex: 0,
);

const _mockEscrowFundData = EscrowFundData(
  tradeId: 'mock-trade-001',
  contractAddress: '0x0000000000000000000000000000000000000003',
  chainId: 31,
  accountIndex: 0,
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
      ('Awaiting on-chain', const SwapOutAwaitingOnChain(_mockSwapOutData)),
      ('Funded', const SwapOutFunded(_mockSwapOutData)),
      ('Claimed', const SwapOutClaimed(_mockSwapOutData)),
      ('Completed', const SwapOutCompleted(_mockSwapOutData)),
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
      ('Request created', const SwapInRequestCreated(_mockSwapInData)),
      (
        'Payment progress',
        SwapInPaymentProgress(
          _mockSwapInData,
          paymentState: PayInFlight(params: _mockPayParams),
        ),
      ),
      ('Awaiting on-chain', const SwapInAwaitingOnChain(_mockSwapInData)),
      ('Funded', const SwapInFunded(_mockSwapInData)),
      ('Claimed', const SwapInClaimed(_mockSwapInData)),
      ('Claim tx in mempool', const SwapInClaimTxInMempool(_mockSwapInData)),
      ('Completed', const SwapInCompleted(_mockSwapInData)),
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
  return _StateCyclerWidget<OnchainOperationState>(
    states: [
      ('Initialised', const OnchainInitialised()),
      (
        'Swap progress – paying',
        OnchainSwapProgress(
          _mockEscrowFundData,
          swapState: SwapInPaymentProgress(
            _mockSwapInData,
            paymentState: PayInFlight(params: _mockPayParams),
          ),
        ),
      ),
      (
        'Swap progress – awaiting on-chain',
        OnchainSwapProgress(
          _mockEscrowFundData,
          swapState: const SwapInAwaitingOnChain(_mockSwapInData),
        ),
      ),
      (
        'Swap progress – funded',
        OnchainSwapProgress(
          _mockEscrowFundData,
          swapState: const SwapInFunded(_mockSwapInData),
        ),
      ),
      (
        'Swap progress – completed',
        OnchainSwapProgress(
          _mockEscrowFundData,
          swapState: const SwapInCompleted(_mockSwapInData),
        ),
      ),
      (
        'Completed',
        OnchainTxConfirmed(
          _mockEscrowFundData.copyWithTransactionInformation(
            TransactionInformation.fromMap({
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
      ),
      ('Failed', OnchainError('Escrow contract reverted')),
    ],
    builder: (context, state) {
      switch (state) {
        case OnchainInitialised():
          return EscrowFundConfirmWidget(onConfirm: () async {});
        case OnchainTxBroadcast():
          return OnchainTransactionSheet.broadcast(
            title: 'Depositing Funds',
            subtitle: state.data.txHash != null
                ? 'Waiting for on-chain confirmation...'
                : 'Submitting deposit transaction...',
          );
        case OnchainSwapProgress():
          return EscrowFundProgressWidget(state);
        case OnchainTxConfirmed():
          return OnchainTransactionSheet.success(
            title: 'Deposit Success',
            subtitle: 'Funds have been deposited into the escrow.',
          );
        case OnchainError():
          return OnchainTransactionSheet.error(state, title: 'Escrow Failed');
        case OnchainTxBroadcasting():
          // TODO: Handle this case.
          throw UnimplementedError();
        case OnchainTxSent():
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    },
  );
}
