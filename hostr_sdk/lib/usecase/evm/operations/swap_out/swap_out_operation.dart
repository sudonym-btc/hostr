import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

import '../../../../util/main.dart';
import '../../../auth/auth.dart';
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
}
