import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

import '../../../../injection.dart';
import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import '../operation_state_store.dart';
import 'swap_out_models.dart';
import 'swap_out_state.dart';

abstract class SwapOutOperation extends Cubit<SwapOutState> {
  final CustomLogger logger;
  final Auth auth;
  final SwapOutParams params;

  /// Completer used to wait for an externally-provided invoice when no NWC
  /// connection is available.
  @protected
  Completer<String>? externalInvoiceCompleter;

  late final OperationStateStore _stateStore = getIt<OperationStateStore>();

  SwapOutOperation({
    required this.auth,
    required this.logger,
    @factoryParam required this.params,
    SwapOutState? initialState,
  }) : super(initialState ?? const SwapOutInitialised());

  /// Persist every state that carries data.
  @override
  void emit(SwapOutState state) {
    super.emit(state);
    final id = state.operationId;
    if (id != null) {
      _stateStore.write('swap_out', id, state.toJson());
    }
  }

  /// Call this from the UI after the user pastes an external Lightning invoice.
  ///
  /// Validates that [invoice] is a well-formed BOLT-11 payment request whose
  /// amount matches the amount required by the current swap.  Throws a
  /// [FormatException] for unparseable invoices and an [ArgumentError] when
  /// the encoded amount does not equal the expected amount.
  void submitExternalInvoice(String invoice) {
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
  }

  Future<SwapOutFees> estimateFees();

  /// Reads the current state and performs exactly one state transition.
  ///
  /// Implementors switch on [state] and run the appropriate step:
  ///
  /// | State group                                        | Action                          |
  /// |----------------------------------------------------|---------------------------------|
  /// | `Initialised`                                      | Acquire invoice + create swap   |
  /// | `AwaitingOnChain`                                  | Lock funds in EtherSwap         |
  /// | `Funded`                                           | Await Boltz payment or refund   |
  /// | `Refunding`                                        | Confirm refund receipt          |
  /// | `Completed / Refunded / Failed`                    | No-op (terminal)                |
  Future<void> handle();

  /// Loops [handle] until the state is terminal.
  Future<void> run() async {
    while (!state.isTerminal) {
      await handle();
    }
  }

  /// Start a new swap-out from [SwapOutInitialised].
  Future<void> execute() => run();

  /// Resume from a persisted (non-terminal) state.
  ///
  /// Returns `true` if the swap reached a terminal state.
  Future<bool> recover() async {
    if (state.data == null) return false;
    if (state.isTerminal) return true;
    try {
      await run();
      return state.isTerminal;
    } catch (e) {
      logger.e('Recovery error for ${state.data?.boltzId}: $e');
      return false;
    }
  }
}
