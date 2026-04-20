import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../util/custom_logger.dart';
import 'operation_tracker.dart';
import 'swap_in/swap_in_operation.dart';

/// Live, in-memory tracker of running [SwapInOperation] instances.
///
/// Operations self-register via [register] in their constructor, so callers
/// never need to call this directly. Terminal operations are automatically
/// unregistered by the underlying [OperationTracker].
///
/// Handles the "re-key" dance for freshly-created swaps whose `boltzId`
/// is not yet known: the operation is initially keyed by
/// [SwapInParams.parentOperationId] and automatically re-keyed once a
/// state carrying a `boltzId` is emitted.
@singleton
class SwapInTracker extends OperationTracker<SwapInOperation> {
  final Map<String, StreamSubscription> _rekeyWatchers = {};

  SwapInTracker(CustomLogger logger)
    : super(logger: logger, label: 'swap-in', stateStream: (op) => op.stream);

  /// Register a live [SwapInOperation].
  ///
  /// When the operation already has a boltzId (e.g. recovered from storage)
  /// it is keyed by that ID. For freshly-created operations whose boltzId
  /// is not yet available, the operation is keyed by its
  /// [SwapInParams.parentOperationId] as a placeholder; as soon as the
  /// first state with a boltzId is emitted, the entry is automatically
  /// re-keyed.
  void registerSwapIn(SwapInOperation operation) {
    final boltzId = operation.state.data?.boltzId;

    if (boltzId != null) {
      register(boltzId, operation);
      return;
    }

    // No boltzId yet — pre-register by parentOperationId and re-key later.
    final parentId = operation.params.parentOperationId;
    if (parentId == null) {
      return; // nothing to key by
    }

    register(parentId, operation);

    // Listen for the boltzId to appear, then re-key.
    final rekeyKey = '$parentId#rekey';
    unawaited(_rekeyWatchers[rekeyKey]?.cancel());
    _rekeyWatchers[rekeyKey] = operation.stream.listen((state) {
      final newBoltzId = state.data?.boltzId;
      if (newBoltzId == null) return;
      unawaited(_rekeyWatchers[rekeyKey]?.cancel());
      _rekeyWatchers.remove(rekeyKey);
      unregister(parentId);
      register(newBoltzId, operation);
    });
  }

  /// Reactive stream of the [SwapInOperation] whose
  /// `parentOperationId` matches, or `null` when no such operation is active.
  Stream<SwapInOperation?> watchForParent(String parentOperationId) {
    return watch(
      (op) =>
          op.state.data?.parentOperationId == parentOperationId ||
          op.params.parentOperationId == parentOperationId,
    );
  }

  /// Synchronous lookup: active swap-in whose `parentOperationId` matches.
  SwapInOperation? getForParent(String parentOperationId) {
    return firstWhereOrNull(
      (op) =>
          op.state.data?.parentOperationId == parentOperationId ||
          op.params.parentOperationId == parentOperationId,
    );
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
