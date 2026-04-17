import 'dart:async';

import 'package:rxdart/rxdart.dart';

// ── Status types ──────────────────────────────────────────────────────

class StreamStatus {}

class StreamStatusIdle extends StreamStatus {}

class StreamStatusQuerying extends StreamStatus {}

class StreamStatusQueryComplete extends StreamStatus {}

class StreamStatusLive extends StreamStatus {}

class StreamStatusError extends StreamStatus {
  final Object? error;
  final StackTrace? stackTrace;
  StreamStatusError(this.error, this.stackTrace);
}

enum StreamPhase { querying, queryComplete, live, error, idle }

// ── StreamWithStatus ──────────────────────────────────────────────────

/// An append-only per-item event source with a lifecycle status side-channel.
///
/// ## Design
///
/// Items are accumulated in a plain [List<T>] (`_items`).  A
/// [PublishSubject<T>] (`_stream`) broadcasts per-item arrivals.
/// A [BehaviorSubject<StreamStatus>] (`_status`) tracks lifecycle.
///
/// All reads are derived from these two subjects:
///
/// - [items]        — current list (synchronous snapshot).
/// - [itemsStream]  — emits the full list after every [add] (replays current
///                    value on listen via [BehaviorSubject]).
/// - [stream]       — per-item broadcast of *new* arrivals only.
/// - [replayStream] — current [items] expanded into individual events,
///                    then continues with [stream].
///
/// ## Write API (append-only)
///
/// - [add] / [addAll]   — append items.
/// - [addStatus]        — update lifecycle status.
/// - [addError]         — error on both channels.
///
/// ## Operators
///
/// - [where]    — filtered child.
/// - [map]      — sync-transformed child.
/// - [asyncMap] — async-transformed child.
/// - [scan]     — accumulator child.
/// - [combineAll] / [combine] — merge multiple sources.
/// - [pipeFrom] — 1:1 mirror from another [StreamWithStatus].
class StreamWithStatus<T> {
  Function? onClose;

  /// Per-item broadcast subject.
  final PublishSubject<T> _stream = PublishSubject<T>();

  /// Running accumulation of items, exposed as a [BehaviorSubject] so
  /// [itemsStream] replays the current list on subscribe.
  final BehaviorSubject<List<T>> _items$;

  /// Lifecycle status (Idle → Querying → QueryComplete / Live).
  final BehaviorSubject<StreamStatus> _status;

  final List<StreamSubscription> _subs = [];
  final Map<int, StreamStatus> _combinedSourceStatuses = {};
  int _nextCombinedSourceId = 0;

  // ── Constructors ──────────────────────────────────────────────────

  /// Creates an empty stream in [StreamStatusIdle].
  StreamWithStatus({this.onClose})
    : _items$ = BehaviorSubject.seeded(const []),
      _status = BehaviorSubject.seeded(StreamStatusIdle());

  /// Runs [query], then [live] if provided.
  ///
  /// Status transitions: Idle → Querying → (QueryComplete | Live).
  factory StreamWithStatus.query({
    required Stream<T> Function() query,
    Stream<T> Function()? live,
    Function? onClose,
  }) {
    final sws = StreamWithStatus<T>(onClose: onClose)
      ..addStatus(StreamStatusQuerying());
    sws._subs.add(
      query().listen(
        sws.add,
        onDone: () {
          if (live != null) {
            sws.addStatus(StreamStatusLive());
            sws._subs.add(live().listen(sws.add));
          } else {
            sws.addStatus(StreamStatusQueryComplete());
          }
        },
        onError: (Object e, StackTrace st) =>
            sws.addStatus(StreamStatusError(e, st)),
      ),
    );
    return sws;
  }

  // ── Read API ──────────────────────────────────────────────────────

  /// Current accumulated items (synchronous snapshot).
  List<T> get items => _items$.value;

  /// Lifecycle status as a [ValueStream] (replays latest on subscribe).
  ValueStream<StreamStatus> get status => _status;

  /// Per-item broadcast of new arrivals only.
  Stream<T> get stream => _stream.stream;

  /// Emits the full item list on every change.
  /// Being a [BehaviorSubject], replays current value on listen.
  Stream<List<T>> get itemsStream => _items$.stream;

  /// Emits current [items] as individual events, then continues with [stream].
  Stream<T> get replayStream {
    late StreamController<T> controller;
    StreamSubscription<T>? sub;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        final snapshot = items;
        for (final item in snapshot) {
          controller.add(item);
        }
        sub = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  // ── Write API (append-only) ───────────────────────────────────────

  /// Appends [item] and notifies all listeners.
  void add(T item) {
    if (_stream.isClosed) return;
    _items$.add(List.unmodifiable([...items, item]));
    _stream.add(item);
  }

  /// Appends all [newItems].
  void addAll(List<T> newItems) {
    if (_stream.isClosed || newItems.isEmpty) return;
    _items$.add(List.unmodifiable([...items, ...newItems]));
    for (final item in newItems) {
      _stream.add(item);
    }
  }

  /// Updates lifecycle status.
  void addStatus(StreamStatus s) {
    if (!_status.isClosed) _status.add(s);
  }

  /// Sets error status and pushes error through [stream].
  void addError(Object error, [StackTrace? stackTrace]) {
    addStatus(StreamStatusError(error, stackTrace));
    if (!_stream.isClosed) _stream.addError(error, stackTrace);
  }

  /// Registers a subscription for cleanup on [close] / [reset].
  void addSubscription(StreamSubscription sub) => _subs.add(sub);

  // ── Operators ─────────────────────────────────────────────────────

  /// Returns a child whose items are filtered by [test].
  StreamWithStatus<T> where(bool Function(T) test) {
    final child = StreamWithStatus<T>();
    child.addStatus(status.value);
    child.addSubscription(
      replayStream.where(test).listen(child.add, onError: child.addError),
    );
    child.addSubscription(
      status.listen(child.addStatus, onError: child.addError),
    );
    return child;
  }

  /// Returns a child whose items are synchronously transformed.
  StreamWithStatus<R> map<R>(R Function(T) fn) {
    final child = StreamWithStatus<R>();
    child.addStatus(status.value);
    child.addSubscription(
      replayStream.map(fn).listen(child.add, onError: child.addError),
    );
    child.addSubscription(
      status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(child.addStatus, onError: child.addError),
    );
    return child;
  }

  /// Returns a child whose per-item events are async-transformed.
  ///
  /// "Completion" statuses ([StreamStatusLive], [StreamStatusQueryComplete])
  /// are deferred until all in-flight async operations finish, so the child
  /// never advertises "live" while work is still pending.
  StreamWithStatus<R> asyncMap<R>(FutureOr<R> Function(T) fn) {
    final child = StreamWithStatus<R>();
    child.addStatus(status.value);
    var pending = 0;

    child.addSubscription(
      replayStream.listen((item) {
        pending++;
        Future<R>.value(fn(item))
            .then((mapped) {
              if (child._stream.isClosed) return;
              child.add(mapped);
            })
            .catchError((Object e, StackTrace st) {
              child.addError(e, st);
            })
            .whenComplete(() {
              pending--;
              if (pending == 0) child.addStatus(status.value);
            });
      }, onError: (Object e, StackTrace st) => child.addError(e, st)),
    );

    child.addSubscription(
      status.distinct((a, b) => a.runtimeType == b.runtimeType).listen((s) {
        if (pending > 0) return;
        child.addStatus(s);
      }),
    );

    return child;
  }

  /// Returns a new stream that merges items and status from [sources].
  static StreamWithStatus<T> combineAll<T>(List<StreamWithStatus<T>> sources) {
    final combined = StreamWithStatus<T>();

    for (final source in sources) {
      combined.combine(source);
    }

    if (sources.isEmpty) {
      combined.addStatus(StreamStatusLive());
    }

    return combined;
  }

  /// Merges [source] into this stream, forwarding its current items,
  /// future per-item events, and lifecycle status.
  void combine(StreamWithStatus<T> source) {
    final sourceId = _nextCombinedSourceId++;
    _combinedSourceStatuses[sourceId] = source.status.value;

    // Replay existing items from source.
    if (source.items.isNotEmpty) {
      addAll(source.items);
    }
    addStatus(recomputeStatus(_combinedSourceStatuses.values));

    var detached = false;

    void detach() {
      if (detached) return;
      detached = true;
      _combinedSourceStatuses.remove(sourceId);
      addStatus(
        _combinedSourceStatuses.isEmpty
            ? StreamStatusLive()
            : recomputeStatus(_combinedSourceStatuses.values),
      );
    }

    late final StreamSubscription<T> dataSub;
    late final StreamSubscription<StreamStatus> statusSub;

    dataSub = source.stream.listen(add, onError: addError, onDone: detach);

    statusSub = source.status
        .distinct((a, b) => a.runtimeType == b.runtimeType)
        .listen(
          (s) {
            _combinedSourceStatuses[sourceId] = s;
            addStatus(recomputeStatus(_combinedSourceStatuses.values));
          },
          onError: addError,
          onDone: detach,
        );

    _subs.add(dataSub);
    _subs.add(statusSub);
  }

  /// Returns a child that accumulates per-item events with [accumulator],
  /// starting from [seed]. Each emission replaces the single-item list
  /// with the latest accumulator value.
  StreamWithStatus<R> scan<R>(R seed, R Function(R acc, T item) accumulator) {
    final child = StreamWithStatus<R>();
    child.addStatus(status.value);
    var acc = seed;
    child.add(acc);
    child.addSubscription(
      replayStream.listen((item) {
        acc = accumulator(acc, item);
        // Reset and re-add so the child always has exactly one item.
        child._items$.add(List.unmodifiable([acc]));
        child._stream.add(acc);
      }, onError: (Object e, StackTrace st) => child.addError(e, st)),
    );
    child.addSubscription(status.listen(child.addStatus));
    return child;
  }

  /// Returns a child that accumulates per-item events into a [Map<K, T>]
  /// keyed by [keyOf], emitting the map's values as a [List<T>] after each
  /// update.
  ///
  /// This is a convenience wrapper around [scan] for the common
  /// "upsert-by-key" pattern.
  StreamWithStatus<List<T>> accumulateByKey<K>(K Function(T item) keyOf) {
    return scan<List<T>>([], (acc, item) {
      final map = {for (final existing in acc) keyOf(existing): existing};
      map[keyOf(item)] = item;
      return map.values.toList();
    });
  }

  // ── Piping ──────────────────────────────────────────────────────

  /// Pipes items and status from [source] into this stream (1:1 mirror).
  ///
  /// Replays all existing items from the source, then forwards future
  /// per-item events. Status is also forwarded.
  ///
  /// Typical usage: keep a **final** `StreamWithStatus` as the public API,
  /// call [reset] on logout, then [pipeFrom] a fresh source on login.
  void pipeFrom(StreamWithStatus<T> source) {
    addSubscription(source.replayStream.listen(add, onError: addError));
    addSubscription(
      source.status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(addStatus, onError: addError),
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────

  /// Resets to idle, cancels subscriptions, clears items.
  Future<void> reset() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _combinedSourceStatuses.clear();
    if (!_items$.isClosed) _items$.add(const []);
    if (!_status.isClosed) _status.add(StreamStatusIdle());
    await onClose?.call();
    onClose = null;
  }

  /// Permanently closes both subjects and cancels subscriptions.
  Future<void> close() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _combinedSourceStatuses.clear();
    await onClose?.call();
    await _stream.close();
    await _items$.close();
    await _status.close();
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toString()).toList(),
  };
}

// ── Helpers ──────────────────────────────────────────────────────────

/// Computes the most severe [StreamStatus] from a collection.
///
/// Priority: Error > Querying > Live > QueryComplete > Idle.
StreamStatus recomputeStatus(Iterable<StreamStatus> statuses) {
  for (final s in statuses) {
    if (s is StreamStatusError) return StreamStatusError(s.error, s.stackTrace);
  }
  if (statuses.any((s) => s is StreamStatusQuerying)) {
    return StreamStatusQuerying();
  }
  if (statuses.any((s) => s is StreamStatusLive)) return StreamStatusLive();
  if (statuses.any((s) => s is StreamStatusQueryComplete)) {
    return StreamStatusQueryComplete();
  }
  return StreamStatusIdle();
}
