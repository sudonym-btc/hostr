import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import '../../chain/evm_chain.dart';
import '../swap_record.dart';
import '../swap_store.dart';
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

  SwapOutOperation({
    required this.auth,
    required this.logger,
    @factoryParam required this.params,
  }) : super(SwapOutInitialised());

  /// Call this from the UI after the user pastes an external Lightning invoice.
  void submitExternalInvoice(String invoice) {
    if (externalInvoiceCompleter != null &&
        !externalInvoiceCompleter!.isCompleted) {
      externalInvoiceCompleter!.complete(invoice);
    }
  }

  Future<SwapOutFees> estimateFees();
  Future<void> execute();

  /// Recover a persisted swap-out record.
  ///
  /// Checks the current Boltz status and either marks the swap as completed,
  /// failed, or attempts to refund locked EVM funds (cooperative then timelock).
  ///
  /// Returns `true` if the swap was resolved (completed, refunded, or terminal).
  Future<bool> recover({
    required SwapOutRecord record,
    required String boltzStatus,
    required EvmChain chain,
    required SwapStore swapStore,
  });
}
