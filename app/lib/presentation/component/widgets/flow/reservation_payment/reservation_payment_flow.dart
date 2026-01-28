import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:models/main.dart';

import '../flow.dart';
import '../payment/payment_flow.dart';
import '../select_escrow/select_escrow_flow.dart';

/// Reservation payment flow implementation.
class ReservationPaymentFlow extends FlowDefinition {
  ReservationPaymentFlow(this.flowHost, {required this.reservationRequest});

  final FlowHost flowHost;
  final ReservationRequest reservationRequest;

  @override
  String get id => 'reservation-payment-flow';

  @override
  List<FlowStep> buildSteps() => [
    UseEscrowStep(
      onDone: (useEscrow) {
        flowHost.pushFlow(
          useEscrow
              ? SelectEscrowFlow(
                  onDone: (Escrow e) => flowHost.pushFlow(
                    SwapInFlow(
                      desiredAmount: reservationRequest.parsedContent.amount,
                      onDone: () => PaymentFlow(evmPaymentCubit),
                    ),
                  ),
                )
              : PaymentFlow(paymentCubit),
        );
      },
    ),
  ];
}

/// Renders the reservation payment flow.
class ReservationPaymentFlowWidget extends StatefulWidget {
  final ReservationRequest reservationRequest;
  final VoidCallback onClose;

  const ReservationPaymentFlowWidget({
    super.key,
    required this.reservationRequest,
    required this.onClose,
  });

  @override
  State<ReservationPaymentFlowWidget> createState() =>
      _ReservationPaymentFlowWidgetState();
}

class _ReservationPaymentFlowWidgetState
    extends State<ReservationPaymentFlowWidget> {
  late FlowHost _flowHost;

  @override
  void initState() {
    super.initState();
    _flowHost = FlowHost(widget.onClose);
    _flowHost.init(
      ReservationPaymentFlow(
        _flowHost,
        reservationRequest: widget.reservationRequest,
      ),
    );
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
          return _ReservationPaymentFlowScaffold(
            flowHost: _flowHost,
            child: state.currentStep?.build(context) ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _ReservationPaymentFlowScaffold extends StatelessWidget {
  final Widget child;
  final FlowHost flowHost;

  const _ReservationPaymentFlowScaffold({
    required this.child,
    required this.flowHost,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class UseEscrowStep extends StatelessWidget implements FlowStep {
  final ValueChanged<bool> onDone;

  const UseEscrowStep({super.key, required this.onDone});

  @override
  String get id => 'use-escrow';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Use an escrow for this payment?'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            onDone(true);
          },
          child: const Text('Yes, use escrow'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            onDone(false);
          },
          child: const Text('No, direct payment'),
        ),
      ],
    );
  }
}
