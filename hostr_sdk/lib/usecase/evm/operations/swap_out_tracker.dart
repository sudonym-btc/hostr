import 'dart:async';

import 'package:injectable/injectable.dart' hide Order;

import '../../../util/custom_logger.dart';
import 'operation_tracker.dart';
import 'swap_out/swap_out_operation.dart';

/// Live, in-memory tracker of running [SwapOutOperation] instances.
///
/// Operations self-register via [registerSwapOut] in their constructor,
/// so callers never need to call this directly. Terminal operations are
/// automatically unregistered by the underlying [OperationTracker].
///
/// Handles the case where `boltzId` is not yet known at construction time
/// by temporarily keying the operation by its [identityHashCode] and
/// re-keying once a state carrying a `boltzId` is emitted.
@singleton
class SwapOutTracker extends OperationTracker<SwapOutOperation> {
  final Map<String, StreamSubscription> _rekeyWatchers = {};

  SwapOutTracker(CustomLogger logger)
    : super(logger: logger, label: 'swap-out', stateStream: (op) => op.stream);

  /// Register a live [SwapOutOperation].
  ///
  /// When the operation already has a boltzId (e.g. recovered from storage)
  /// it is keyed by that ID. For freshly-created operations whose boltzId
  /// is not yet available, the operation is keyed by a temporary placeholder;
  /// as soon as the first state with a boltzId is emitted, the entry is
  /// automatically re-keyed.
  void registerSwapOut(SwapOutOperation operation) {
    final boltzId = operation.state.data?.boltzId;

    if (boltzId != null) {
      register(boltzId, operation);
      return;
    }

    // No boltzId yet — pre-register with a temporary key and re-key later.
    final tempKey = '_pending_${identityHashCode(operation)}';
    register(tempKey, operation);

    unawaited(_rekeyWatchers[tempKey]?.cancel());
    _rekeyWatchers[tempKey] = operation.stream.listen((state) {
      final newBoltzId = state.data?.boltzId;
      if (newBoltzId == null) return;
      unawaited(_rekeyWatchers[tempKey]?.cancel());
      _rekeyWatchers.remove(tempKey);
      unregister(tempKey);
      register(newBoltzId, operation);
    });
  }

  @override
  Future<void> dispose() async {
    for (final sub in _rekeyWatchers.values) {
      await sub.cancel();
    }
    _rekeyWatchers.clear();
    await super.dispose();
  }
}
