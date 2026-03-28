import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../util/custom_logger.dart';

/// Generic in-memory tracker for live operation instances.
///
/// Replaces the duplicated BehaviorSubject / watcher / register / unregister
/// pattern. Extended by [SwapInTracker] and [SwapOutTracker] for typed usage.
///
/// [T] is the operation type (e.g. `SwapInOperation`, `SwapOutOperation`).
/// Operations must expose a `Stream` of states with an `isTerminal` property.
class OperationTracker<T> {
  final CustomLogger _logger;
  final String _label;

  /// Extracts a stream of states from the operation that have `.isTerminal`.
  final Stream<dynamic> Function(T operation) _stateStream;

  final BehaviorSubject<Map<String, T>> _operations$ = BehaviorSubject.seeded(
    {},
  );
  final Map<String, StreamSubscription> _watchers = {};

  OperationTracker({
    required CustomLogger logger,
    required String label,
    required Stream<dynamic> Function(T operation) stateStream,
  }) : _logger = logger,
       _label = label,
       _stateStream = stateStream;

  /// Current snapshot of all tracked operations, keyed by ID.
  Map<String, T> get current => _operations$.value;

  /// Reactive stream of all tracked operations.
  Stream<Map<String, T>> get stream => _operations$.stream;

  /// Register an operation keyed by [key].
  ///
  /// Automatically unregisters when the operation reaches a terminal state.
  void register(String key, T operation) {
    _watchers[key]?.cancel();

    final current = Map<String, T>.of(_operations$.value);
    current[key] = operation;
    _operations$.add(current);

    _logger.d('registered $_label $key');

    _watchers[key] = _stateStream(operation).listen(
      (state) {
        if (state.isTerminal == true) _unregister(key);
      },
      onError: (Object error, StackTrace stackTrace) => _unregister(key),
      onDone: () => _unregister(key),
    );
  }

  void _unregister(String key) {
    _watchers[key]?.cancel();
    _watchers.remove(key);

    final current = Map<String, T>.of(_operations$.value);
    if (current.remove(key) != null) {
      _operations$.add(current);
      _logger.d('unregistered $_label $key');
    }
  }

  /// Remove an operation by [key].
  void unregister(String key) => _unregister(key);

  /// Find the first operation matching [predicate], or null.
  T? firstWhereOrNull(bool Function(T op) predicate) {
    return _operations$.value.values.cast<T?>().firstWhere(
      (op) => op != null && predicate(op),
      orElse: () => null,
    );
  }

  /// Reactive stream of the first operation matching [predicate], or null.
  Stream<T?> watch(bool Function(T op) predicate) {
    return _operations$.stream
        .map(
          (ops) => ops.values.cast<T?>().firstWhere(
            (op) => op != null && predicate(op),
            orElse: () => null,
          ),
        )
        .distinct();
  }

  /// Dispose all watchers and close the subject.
  void dispose() {
    for (final sub in _watchers.values) {
      sub.cancel();
    }
    _watchers.clear();
    _operations$.close();
  }
}
