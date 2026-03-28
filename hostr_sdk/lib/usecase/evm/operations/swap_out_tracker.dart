import 'package:injectable/injectable.dart';

import '../../../util/custom_logger.dart';
import 'operation_tracker.dart';
import 'swap_out/swap_out_operation.dart';

/// Live, in-memory tracker of running [SwapOutOperation] instances.
///
/// Operations self-register via [registerSwapOut] in their constructor,
/// so callers never need to call this directly. Terminal operations are
/// automatically unregistered by the underlying [OperationTracker].
@singleton
class SwapOutTracker extends OperationTracker<SwapOutOperation> {
  SwapOutTracker(CustomLogger logger)
    : super(logger: logger, label: 'swap-out', stateStream: (op) => op.stream);

  /// Register a live [SwapOutOperation].
  ///
  /// Keyed by its boltz ID. Skips registration if no boltzId is available.
  void registerSwapOut(SwapOutOperation operation) {
    final boltzId = operation.state.data?.boltzId;
    if (boltzId == null) return;
    register(boltzId, operation);
  }
}
