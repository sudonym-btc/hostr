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

/// A per-item event source with a lifecycle status side-channel.
///
/// ## Read API
///
/// - [items]        — current accumulated items (synchronous).
/// - [status]       — lifecycle as a [ValueStream<StreamStatus>].
/// - [stream]       — per-item broadcast of new arrivals.
/// - [replayStream] — emits current [items] then continues with [stream].
///
/// ## Write API
///
/// - [add] / [addAll]   — append items.
/// - [addStatus]        — update lifecycle status.
/// - [addError]         — error on both channels.
/// - [replaceAll]       — wholesale-replace the item list.
///
/// ## Operators
///
/// - [where]    — filtered child (does not own parent).
/// - [asyncMap] — async-transformed child (does not own parent).
/// - [combineAll]  — merge multiple streams into a new combined stream.
class StreamWithStatus<T> {
  Function? onClose;

  final PublishSubject<T> _perItem = PublishSubject<T>();
  final BehaviorSubject<StreamStatus> _status;
  List<T> _items;
  final List<StreamSubscription> _subs = [];
  final Map<int, StreamStatus> _combinedSourceStatuses = {};
  int _nextCombinedSourceId = 0;

  // ── Constructors ──────────────────────────────────────────────────

  /// Creates an empty stream in [StreamStatusIdle].
  StreamWithStatus({this.onClose})
    : _status = BehaviorSubject.seeded(StreamStatusIdle()),
      _items = const [];

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

  /// Current accumulated items.
  List<T> get items => _items;

  /// Lifecycle status as a [ValueStream] (replays latest on subscribe).
  ValueStream<StreamStatus> get status => _status;

  /// Per-item broadcast of new arrivals only.
  Stream<T> get stream => _perItem.stream;

  /// Emits the current items list whenever items or status change.
  /// [status] being a [BehaviorSubject] ensures an immediate emission on listen.
  Stream<List<T>> get itemsStream =>
      Rx.merge<dynamic>([_perItem, _status]).map((_) => _items);

  /// Emits all current [items] synchronously, then continues with [stream].
  Stream<T> get replayStream {
    late StreamController<T> controller;
    StreamSubscription<T>? sub;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        for (final item in _items) {
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

  // ── Write API ─────────────────────────────────────────────────────

  /// Appends [item] and fires on [stream].
  void add(T item) {
    if (_perItem.isClosed) return;
    _items = List.unmodifiable([..._items, item]);
    _perItem.add(item);
  }

  /// Appends all [items].
  void addAll(List<T> items) => items.forEach(add);

  /// Updates lifecycle status.
  void addStatus(StreamStatus s) {
    if (!_status.isClosed) _status.add(s);
  }

  /// Sets error status and pushes error through [stream].
  void addError(Object error, [StackTrace? stackTrace]) {
    addStatus(StreamStatusError(error, stackTrace));
    if (!_perItem.isClosed) _perItem.addError(error, stackTrace);
  }

  /// Wholesale-replaces the accumulated items and notifies [itemsStream]
  /// listeners. Individual per-item events are **not** fired.
  void replaceAll(List<T> items) {
    _items = List.unmodifiable(items);
    if (!_status.isClosed) _status.add(_status.value);
  }

  /// Registers a subscription for cleanup on [close] / [reset].
  void addSubscription(StreamSubscription sub) => _subs.add(sub);

  // ── Operators ─────────────────────────────────────────────────────

  /// Returns a child whose items are filtered by [test].
  ///
  /// Closing the child does **not** close this stream.
  StreamWithStatus<T> where(bool Function(T) test) {
    final child = StreamWithStatus<T>();
    child._items = List.unmodifiable(_items.where(test).toList());
    child._subs.add(
      itemsStream.listen((items) {
        child.replaceAll(items.where(test).toList());
      }, onError: child.addError),
    );
    child._subs.add(
      stream.where(test).listen((item) {
        if (!child._perItem.isClosed) {
          child._perItem.add(item);
        }
      }, onError: child.addError),
    );
    child._subs.add(
      status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(child.addStatus, onError: child.addError),
    );
    return child;
  }

  /// Returns a child whose per-item events are synchronously transformed.
  ///
  /// Closing the child does **not** close this stream.
  StreamWithStatus<R> map<R>(R Function(T) fn) {
    final child = StreamWithStatus<R>();
    child._items = List.unmodifiable(_items.map(fn).toList());
    child._subs.add(
      itemsStream.listen((items) {
        child.replaceAll(items.map(fn).toList());
      }, onError: child.addError),
    );
    child._subs.add(
      stream.map(fn).listen((item) {
        if (!child._perItem.isClosed) {
          child._perItem.add(item);
        }
      }, onError: child.addError),
    );
    child._subs.add(
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
  ///
  /// Closing the child does **not** close this stream.
  StreamWithStatus<R> asyncMap<R>(FutureOr<R> Function(T) fn) {
    final child = StreamWithStatus<R>();
    var pending = 0;

    child._subs.add(
      stream.listen((item) {
        pending++;
        Future<R>.value(fn(item))
            .then((mapped) {
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

    child._subs.add(
      status.distinct((a, b) => a.runtimeType == b.runtimeType).listen((s) {
        // will be picked up from status.value when pending hits 0
        if (pending > 0) return;
        child.addStatus(s);
      }),
    );

    return child;
  }

  /// Returns a new stream that merges items and status from [sources].
  ///
  /// Items from all sources are collected. Per-item events are forwarded.
  /// Status is recomputed from all sources via [recomputeStatus].
  /// Closing the combined stream does **not** close the sources.
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
  ///
  /// This is the in-place counterpart to [combineAll]. It lets additional
  /// sources be attached over time, while still detaching closed children so
  /// they do not permanently hold the parent in a stale state.
  void combine(StreamWithStatus<T> source) {
    final sourceId = _nextCombinedSourceId++;
    _combinedSourceStatuses[sourceId] = source.status.value;

    _items = List.unmodifiable([..._items, ...source.items]);
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
  /// starting from [seed]. Emits the running accumulator as a single-item
  /// list after each item.
  ///
  /// This is RxDart's `scan` — like JS `reduce` but emits intermediate
  /// values.
  ///
  /// ```dart
  /// source.scan(<String, ReservationPair>{}, (acc, item) {
  ///   return {...acc, item.tradeId: item};
  /// });
  /// ```
  ///
  /// Closing the child does **not** close this stream.
  StreamWithStatus<R> scan<R>(R seed, R Function(R acc, T item) accumulator) {
    final child = StreamWithStatus<R>();
    var acc = seed;
    child._items = List.unmodifiable([acc]);
    child._subs.add(
      stream.listen((item) {
        acc = accumulator(acc, item);
        child._items = List.unmodifiable([acc]);
        child._perItem.add(acc);
      }, onError: (Object e, StackTrace st) => child.addError(e, st)),
    );
    child._subs.add(status.listen(child.addStatus));
    return child;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────

  /// Resets to idle, cancels subscriptions, clears items.
  Future<void> reset() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _items = const [];
    _combinedSourceStatuses.clear();
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
    await _perItem.close();
    await _status.close();
  }

  Map<String, dynamic> toJson() => {
    'items': _items.map((e) => e.toString()).toList(),
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

extension StreamWithStatusListX<T> on StreamWithStatus<List<T>> {
  /// Emits the latest inner list from this snapshot stream.
  Stream<List<T>> get latestItemsStream =>
      itemsStream.map((snapshots) => snapshots.lastOrNull ?? <T>[]);

  /// Exposes the latest snapshot's items as a normal current-items stream.
  StreamWithStatus<T> currentItems() {
    final current = StreamWithStatus<T>();

    final latest = items.lastOrNull;
    if (latest != null) {
      current.replaceAll(latest);
    }

    current.addSubscription(
      latestItemsStream.listen(current.replaceAll, onError: current.addError),
    );
    current.addSubscription(
      status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(current.addStatus, onError: current.addError),
    );

    return current;
  }

  /// Exposes the latest snapshot's items as a deduplicated current-items
  /// stream keyed by [keyOf].
  ///
  /// - [items] always contains the most recent snapshot, deduplicated by key.
  /// - [stream] emits only items whose keyed value is new or changed compared
  ///   with the previous snapshot.
  StreamWithStatus<T> currentItemsBy<K>(K Function(T item) keyOf) {
    final current = StreamWithStatus<T>();

    Map<K, T> latestByKey = {
      for (final item in items.lastOrNull ?? <T>[]) keyOf(item): item,
    };

    if (latestByKey.isNotEmpty) {
      current.replaceAll(latestByKey.values.toList());
    }

    void syncLatest(List<T> latest) {
      final nextByKey = <K, T>{for (final item in latest) keyOf(item): item};
      final changed = <T>[];

      for (final entry in nextByKey.entries) {
        if (latestByKey[entry.key] != entry.value) {
          changed.add(entry.value);
        }
      }

      latestByKey = nextByKey;
      current.replaceAll(nextByKey.values.toList());

      for (final item in changed) {
        if (!current._perItem.isClosed) {
          current._perItem.add(item);
        }
      }
    }

    current.addSubscription(
      latestItemsStream.listen(syncLatest, onError: current.addError),
    );
    current.addSubscription(
      status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(current.addStatus, onError: current.addError),
    );

    return current;
  }

  /// Filters items inside the latest snapshot.
  StreamWithStatus<T> whereItems(bool Function(T item) test) {
    final filtered = StreamWithStatus<T>();
    final latest = items.lastOrNull ?? <T>[];
    filtered.replaceAll(latest.where(test).toList());

    filtered.addSubscription(
      latestItemsStream.listen((items) {
        filtered.replaceAll(items.where(test).toList());
      }, onError: filtered.addError),
    );
    filtered.addSubscription(
      status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(filtered.addStatus, onError: filtered.addError),
    );

    return filtered;
  }

  /// Maps items inside the latest snapshot.
  StreamWithStatus<R> mapItems<R>(R Function(T item) fn) {
    final mapped = StreamWithStatus<R>();
    final latest = items.lastOrNull ?? <T>[];
    mapped.replaceAll(latest.map(fn).toList());

    mapped.addSubscription(
      latestItemsStream.listen((items) {
        mapped.replaceAll(items.map(fn).toList());
      }, onError: mapped.addError),
    );
    mapped.addSubscription(
      status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(mapped.addStatus, onError: mapped.addError),
    );

    return mapped;
  }
}
