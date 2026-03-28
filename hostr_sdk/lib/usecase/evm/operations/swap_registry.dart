import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../util/custom_logger.dart';
import 'swap_in/swap_in_operation.dart';
import 'swap_in/swap_in_state.dart';
import 'swap_out/swap_out_operation.dart';

/// Live, in-memory registry of running [SwapInOperation] and
/// [SwapOutOperation] instances.
///
/// Tracks actual live cubit instances so that UI can reactively look up
/// an active swap operation by its `parentOperationId` (e.g. trade ID)
/// without knowing anything about escrow fund / withdraw specifics.
///
/// Operations are automatically unregistered when they reach a terminal state.
@singleton
class SwapRegistry {
  final CustomLogger _logger;

  SwapRegistry(CustomLogger logger) : _logger = logger.scope('swap-registry');

  // ── Swap-In tracking ──────────────────────────────────────────────

  final BehaviorSubject<Map<String, SwapInOperation>> _swapIns$ =
      BehaviorSubject.seeded({});
  final Map<String, StreamSubscription> _swapInWatchers = {};

  /// Register a live [SwapInOperation].
  ///
  /// When the operation already has a boltzId (e.g. recovered from storage)
  /// it is keyed by that ID. For freshly-created operations whose boltzId
  /// is not yet available, the operation is keyed by its
  /// [SwapInParams.parentOperationId] as a placeholder; as soon as the
  /// first state with a boltzId is emitted, the entry is automatically
  /// re-keyed so that both boltzId-based and parentId-based lookups work.
  void registerSwapIn(SwapInOperation operation) {
    final boltzId = operation.state.data?.boltzId;

    if (boltzId != null) {
      _registerSwapInByKey(boltzId, operation);
      return;
    }

    // No boltzId yet — pre-register by parentOperationId and re-key later.
    final parentId = operation.params.parentOperationId;
    if (parentId == null) {
      _logger.w('registerSwapIn: no boltzId or parentOperationId — skipping');
      return;
    }

    _logger.d('pre-registering swap-in by parentId $parentId');
    _registerSwapInByKey(parentId, operation);

    // Listen for the boltzId to appear, then re-key.
    final rekeyKey = '$parentId#rekey';
    _swapInWatchers[rekeyKey]?.cancel();
    _swapInWatchers[rekeyKey] = operation.stream.listen((state) {
      final newBoltzId = state.data?.boltzId;
      if (newBoltzId == null) return;
      _swapInWatchers[rekeyKey]?.cancel();
      _swapInWatchers.remove(rekeyKey);
      _unregisterSwapIn(parentId);
      _registerSwapInByKey(newBoltzId, operation);
    });
  }

  void _registerSwapInByKey(String key, SwapInOperation operation) {
    _swapInWatchers[key]?.cancel();

    final current = Map<String, SwapInOperation>.of(_swapIns$.value);
    current[key] = operation;
    _swapIns$.add(current);

    _logger.d('registered swap-in $key');

    _swapInWatchers[key] = operation.stream.listen(
      (state) {
        if (state.isTerminal) _unregisterSwapIn(key);
      },
      onError: (_, _) => _unregisterSwapIn(key),
      onDone: () => _unregisterSwapIn(key),
    );
  }

  void _unregisterSwapIn(String boltzId) {
    _swapInWatchers[boltzId]?.cancel();
    _swapInWatchers.remove(boltzId);

    final current = Map<String, SwapInOperation>.of(_swapIns$.value);
    if (current.remove(boltzId) != null) {
      _swapIns$.add(current);
      _logger.d('unregistered swap-in $boltzId');
    }
  }

  /// Reactive stream of the [SwapInOperation] whose
  /// [SwapInData.parentOperationId] or [SwapInParams.parentOperationId]
  /// matches [parentOperationId], or `null` when no such operation is active.
  /// Emits immediately.
  Stream<SwapInOperation?> watchSwapInForParent(String parentOperationId) {
    return _swapIns$.stream
        .map(
          (ops) => ops.values.cast<SwapInOperation?>().firstWhere(
            (op) =>
                op?.state.data?.parentOperationId == parentOperationId ||
                op?.params.parentOperationId == parentOperationId,
            orElse: () => null,
          ),
        )
        .distinct();
  }

  /// Synchronous lookup: active swap-in whose `parentOperationId` matches.
  SwapInOperation? getSwapInForParent(String parentOperationId) {
    return _swapIns$.value.values.cast<SwapInOperation?>().firstWhere(
      (op) =>
          op?.state.data?.parentOperationId == parentOperationId ||
          op?.params.parentOperationId == parentOperationId,
      orElse: () => null,
    );
  }

  // ── Swap-Out tracking ─────────────────────────────────────────────

  final BehaviorSubject<Map<String, SwapOutOperation>> _swapOuts$ =
      BehaviorSubject.seeded({});
  final Map<String, StreamSubscription> _swapOutWatchers = {};

  /// Register a live [SwapOutOperation].
  ///
  /// Keyed by its boltz ID. Automatically unregistered on terminal state.
  void registerSwapOut(SwapOutOperation operation) {
    final boltzId = operation.state.data?.boltzId;
    if (boltzId == null) {
      _logger.w('registerSwapOut called without boltzId — skipping');
      return;
    }

    _swapOutWatchers[boltzId]?.cancel();

    final current = Map<String, SwapOutOperation>.of(_swapOuts$.value);
    current[boltzId] = operation;
    _swapOuts$.add(current);

    _logger.d('registered swap-out $boltzId');

    _swapOutWatchers[boltzId] = operation.stream.listen(
      (state) {
        if (state.isTerminal) _unregisterSwapOut(boltzId);
      },
      onError: (_, _) => _unregisterSwapOut(boltzId),
      onDone: () => _unregisterSwapOut(boltzId),
    );
  }

  void _unregisterSwapOut(String boltzId) {
    _swapOutWatchers[boltzId]?.cancel();
    _swapOutWatchers.remove(boltzId);

    final current = Map<String, SwapOutOperation>.of(_swapOuts$.value);
    if (current.remove(boltzId) != null) {
      _swapOuts$.add(current);
      _logger.d('unregistered swap-out $boltzId');
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────

  void dispose() {
    for (final sub in _swapInWatchers.values) {
      sub.cancel();
    }
    _swapInWatchers.clear();
    _swapIns$.close();

    for (final sub in _swapOutWatchers.values) {
      sub.cancel();
    }
    _swapOutWatchers.clear();
    _swapOuts$.close();
  }
}
