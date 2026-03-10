import 'dart:async';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

import '../../../../injection.dart';
import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import '../operation_machine.dart';
import '../operation_state_store.dart';
import 'swap_out_models.dart';
import 'swap_out_state.dart';

/// All steps in the swap-out lifecycle.
enum SwapOutStep { createSwap, lockFunds, awaitResolution, confirmRefund }

abstract class SwapOutOperation
    extends OperationMachine<SwapOutState, SwapOutStep> {
  final Auth auth;
  final SwapOutParams params;

  /// Completer used to wait for an externally-provided invoice when no NWC
  /// connection is available.
  @protected
  Completer<String>? externalInvoiceCompleter;

  SwapOutOperation({
    required this.auth,
    required CustomLogger logger,
    @factoryParam required this.params,
    SwapOutState? initialState,
  }) : super(
         store: getIt<OperationStateStore>(),
         logger: logger.scope('swap-out'),
         initialState: initialState ?? const SwapOutInitialised(),
       );

  // ── OperationMachine contract ──────────────────────────────────────

  @override
  String get namespace => 'swap_out';

  @override
  List<StepGuard<SwapOutStep>> get steps => const [
    StepGuard(
      step: SwapOutStep.createSwap,
      allowedFrom: {
        'initialised',
        'requestCreated',
        'externalInvoiceRequired',
        'invoiceCreated',
        'paymentProgress',
      },
      backgroundAllowed: false,
    ),
    StepGuard(
      step: SwapOutStep.lockFunds,
      allowedFrom: {'awaitingOnChain', 'locking'},
      staleTimeout: Duration(minutes: 30),
      backgroundAllowed: true,
    ),
    StepGuard(
      step: SwapOutStep.awaitResolution,
      allowedFrom: {'funded', 'claimed'},
      backgroundAllowed: true,
    ),
    StepGuard(
      step: SwapOutStep.confirmRefund,
      allowedFrom: {'refunding'},
      backgroundAllowed: true,
    ),
  ];

  @override
  SwapOutState stateFromJson(Map<String, dynamic> json) =>
      SwapOutState.fromJson(json);

  @override
  SwapOutState? busyStateFor(SwapOutStep step, SwapOutState current) {
    final data = current.data;
    if (data == null) return null;
    return switch (step) {
      SwapOutStep.lockFunds => SwapOutLocking(data),
      _ => null,
    };
  }

  @override
  void emitError(
    Object error,
    SwapOutState from,
    StackTrace? st, {
    String? stepName,
  }) {
    emit(
      SwapOutFailed(
        error,
        data: from.data,
        stackTrace: st,
        failedAtStep: stepName,
      ),
    );
  }

  // ── External invoice support ──────────────────────────────────────

  /// Call this from the UI after the user pastes an external Lightning invoice.
  ///
  /// Validates that [invoice] is a well-formed BOLT-11 payment request whose
  /// amount matches the amount required by the current swap.
  void submitExternalInvoice(String invoice) =>
      logger.spanSync('submitExternalInvoice', () {
        if (externalInvoiceCompleter == null ||
            externalInvoiceCompleter!.isCompleted) {
          return;
        }

        final Bolt11PaymentRequest decoded;
        try {
          decoded = Bolt11PaymentRequest(invoice);
        } catch (e) {
          throw StateError('Invalid Lightning invoice: $e');
        }

        final invoiceAmount = BitcoinAmount.fromDecimal(
          BitcoinUnit.bitcoin,
          decoded.amount.toString(),
        );

        final currentState = state;
        if (currentState is SwapOutExternalInvoiceRequired) {
          final expectedAmount = currentState.invoiceAmount;
          if (invoiceAmount.getInSats != expectedAmount.getInSats) {
            externalInvoiceCompleter!.completeError(
              ArgumentError(
                'Invoice amount ${invoiceAmount.getInSats} sats does not match '
                'the required ${expectedAmount.getInSats} sats.',
              ),
            );
            return;
          }
        }

        externalInvoiceCompleter!.complete(invoice);
      });

  // ── Abstract: chain-specific ──────────────────────────────────────

  Future<SwapOutFees> estimateFees();
}
