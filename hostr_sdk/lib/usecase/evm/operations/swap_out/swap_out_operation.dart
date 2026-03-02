import 'dart:async';

import 'package:bloc/bloc.dart';
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
  void submitExternalInvoice(String invoice) {
    if (externalInvoiceCompleter != null &&
        !externalInvoiceCompleter!.isCompleted) {
      externalInvoiceCompleter!.complete(invoice);
    }
  }

  Future<SwapOutFees> estimateFees();
  Future<void> execute();

  /// Resume from the current deserialized state.
  ///
  /// Checks the current Boltz status and either marks the swap as completed,
  /// failed, or attempts to refund locked EVM funds.
  ///
  /// Returns `true` if the swap was resolved (completed, refunded, or terminal).
  Future<bool> recover();
}
