import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../util/custom_logger.dart';
import 'escrow_fund_operation.dart';

/// Live, in-memory registry of running [EscrowFundOperation] instances keyed
/// by trade ID.
///
/// This is distinct from [OperationStateStore] which handles disk-based
/// persistence for crash recovery. This registry tracks actual live Cubit
/// instances so that:
///
/// 1. The UI can reactively show a loading state on the pay button when an
///    operation is in-flight for a given trade.
@singleton
class EscrowFundRegistry {
  final CustomLogger _logger;

  EscrowFundRegistry(CustomLogger logger)
    : _logger = logger.scope('fund-registry');

  final BehaviorSubject<Map<String, EscrowFundOperation>> _operations$ =
      BehaviorSubject.seeded({});

  final Map<String, StreamSubscription> _watchers = {};

  /// Register a live [EscrowFundOperation] for [tradeId].
  ///
  /// Automatically unregisters when the operation reaches a terminal state.
  void register(String tradeId, EscrowFundOperation operation) =>
      _logger.spanSync('register', () {
        // Clean up any previous watcher for this trade.
        _watchers[tradeId]?.cancel();

        final current = Map<String, EscrowFundOperation>.of(_operations$.value);
        current[tradeId] = operation;
        _operations$.add(current);

        _logger.d(
          'EscrowFundRegistry: registered operation for trade $tradeId',
        );

        _watchers[tradeId] = operation.stream.listen(
          (state) {
            if (state.isTerminal) {
              _unregister(tradeId);
            }
          },
          onError: (_, _) => _unregister(tradeId),
          onDone: () => _unregister(tradeId),
        );
      });

  void _unregister(String tradeId) => _logger.spanSync('_unregister', () {
    _watchers[tradeId]?.cancel();
    _watchers.remove(tradeId);

    final current = Map<String, EscrowFundOperation>.of(_operations$.value);
    if (current.remove(tradeId) != null) {
      _operations$.add(current);
      _logger.d(
        'EscrowFundRegistry: unregistered operation for trade $tradeId',
      );
    }
  });

  /// Reactive stream of the [EscrowFundOperation] for [tradeId], or `null`
  /// when no operation is active. Emits immediately with the current value.
  Stream<EscrowFundOperation?> watchTrade(String tradeId) {
    return _operations$.stream.map((ops) => ops[tradeId]).distinct();
  }

  /// Synchronous check: is there an active (non-terminal) fund operation for
  /// [tradeId]?
  bool hasActiveFund(String tradeId) {
    return _operations$.value.containsKey(tradeId);
  }

  /// Returns a [Future] that completes when the operation for [tradeId]
  /// finishes (or immediately if none is active).
  Future<void> waitForCompletion(String tradeId) =>
      _logger.span('waitForCompletion', () {
        if (!hasActiveFund(tradeId)) return Future.value();
        return watchTrade(tradeId).firstWhere((op) => op == null).then((_) {});
      });

  void dispose() => _logger.spanSync('dispose', () {
    for (final sub in _watchers.values) {
      sub.cancel();
    }
    _watchers.clear();
    _operations$.close();
  });
}
