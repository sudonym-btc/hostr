import 'dart:async';

import 'package:rxdart/rxdart.dart';

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

/// Represents a response from a Nostr Development Kit (NDK) subscription.
class StreamWithStatus<T> {
  Function? onClose;

  final List<StreamSubscription<T>> _subscriptions = [];

  final StreamController<T> controller = StreamController<T>.broadcast();
  final BehaviorSubject<StreamStatus> status =
      BehaviorSubject<StreamStatus>.seeded(StreamStatusIdle());

  late ReplaySubject<T> _replaySubject = ReplaySubject<T>();
  late StreamSubscription<T> _replaySubscription;

  /// A stream of [T] objects returned by the request.
  ///
  /// This stream can be listened to for real-time processing of events
  /// as they arrive from the nostr request.
  Stream<T> get stream => controller.stream;

  /// A replaying stream of all [T] objects emitted since subscription start.
  Stream<T> get replay => _replaySubject.stream;

  /// A stream of all items received so far, emitted when new items arrive.
  late final BehaviorSubject<List<T>> _listSubject = BehaviorSubject.seeded(
    <T>[],
  );

  ValueStream<List<T>> get list => _listSubject;

  StreamWithStatus({
    this.onClose,
    Stream<T> Function()? queryFn,
    Stream<T> Function()? liveFn,
  }) {
    _setupReplay();

    if (queryFn != null || liveFn != null) {
      _init(queryFn: queryFn, liveFn: liveFn);
    }
  }

  void _setupReplay() {
    _replaySubscription = controller.stream.listen(
      _replaySubject.add,
      onError: _replaySubject.addError,
      onDone: _replaySubject.close,
    );
  }

  void _init({Stream<T> Function()? queryFn, Stream<T> Function()? liveFn}) {
    void startLive() {
      if (liveFn != null) {
        addStatus(StreamStatusLive());
        final liveSub = liveFn().listen(add, onError: addError);
        _subscriptions.add(liveSub);
      }
    }

    if (queryFn != null) {
      addStatus(StreamStatusQuerying());
      final sub = queryFn().listen(
        add,
        onError: addError,
        onDone: () {
          addStatus(StreamStatusQueryComplete());
          startLive();
        },
      );
      _subscriptions.add(sub);
    } else {
      startLive();
    }
  }

  void addError(Object error, StackTrace? stackTrace) {
    print('-----ERROR----');
    print(error.toString());
    print(stackTrace.toString());
    status.add(StreamStatusError(error, stackTrace));
    controller.addError(error, stackTrace);
  }

  void addStatus(StreamStatus newStatus) {
    if (status.isClosed) return;
    status.add(newStatus);
  }

  void setSnapshot(List<T> snapshot) {
    if (_listSubject.isClosed) return;
    _listSubject.add(List.unmodifiable(snapshot));
  }

  void add(T item) {
    final current = _listSubject.value;
    _listSubject.add(List.unmodifiable([...current, item]));
    controller.add(item);
  }

  void addAll(List<T> items) {
    for (final item in items) {
      add(item);
    }
  }

  void addSubscription(StreamSubscription<T> subscription) {
    _subscriptions.add(subscription);
  }

  StreamWithStatus<R> map<R>(
    R Function(T item) mapper, {
    bool closeInner = true,
  }) {
    final mapped = StreamWithStatus<R>();

    StreamSubscription<T>? dataSub;
    StreamSubscription<StreamStatus>? statusSub;

    dataSub = stream.listen((item) {
      try {
        mapped.add(mapper(item));
      } catch (error, stackTrace) {
        mapped.addError(error, stackTrace);
      }
    }, onError: (error, stackTrace) => mapped.addError(error, stackTrace));
    statusSub = status.listen(
      mapped.addStatus,
      onError: (error, stackTrace) => mapped.addError(error, stackTrace),
    );

    mapped.onClose = () async {
      await dataSub?.cancel();
      await statusSub?.cancel();
      if (closeInner) {
        await close();
      }
    };

    return mapped;
  }

  StreamWithStatus<R> whereType<R extends Object>({bool closeInner = true}) {
    final filtered = StreamWithStatus<R>();

    StreamSubscription<R>? dataSub;
    StreamSubscription<StreamStatus>? statusSub;

    dataSub = stream
        .where((item) => item is R)
        .cast<R>()
        .listen(filtered.add, onError: filtered.addError);
    statusSub = status.listen(
      filtered.addStatus,
      onError: (error, stackTrace) => filtered.addError(error, stackTrace),
    );

    filtered.onClose = () async {
      await dataSub?.cancel();
      await statusSub?.cancel();
      if (closeInner) {
        await close();
      }
    };

    return filtered;
  }

  StreamWithStatus<T> where(bool Function(T) test, {bool closeInner = true}) {
    final filtered = StreamWithStatus<T>();

    // Pipe matching items through controller → replay subject.
    // Using parent's `.replay` ensures already-accumulated items are included
    // for new subscribers on the filtered stream.
    StreamSubscription<T>? replaySub;
    replaySub = replay
        .where(test)
        .listen(
          (item) => filtered.controller.add(item),
          onError: filtered.addError,
        );

    // Keep filtered list snapshot in sync with parent list.
    StreamSubscription<List<T>>? listSub;
    listSub = list.listen(
      (snapshot) => filtered.setSnapshot(snapshot.where(test).toList()),
      onError: filtered.addError,
    );

    StreamSubscription<StreamStatus>? statusSub;
    statusSub = status.listen(
      filtered.addStatus,
      onError: (error, stackTrace) => filtered.addError(error, stackTrace),
    );

    filtered.onClose = () async {
      await replaySub?.cancel();
      await listSub?.cancel();
      await statusSub?.cancel();
      if (closeInner) {
        await close();
      }
    };

    return filtered;
  }

  // @todo: suspect a status update would emit before the async mapper completes. Could be problem if trying to get stream result when listening to status changes
  StreamWithStatus<R> asyncMap<R>(
    Future<R> Function(T item) mapper, {
    bool closeInner = true,
  }) {
    final mapped = StreamWithStatus<R>();

    StreamSubscription<R>? dataSub;
    StreamSubscription<StreamStatus>? statusSub;

    dataSub = stream
        .asyncMap(mapper)
        .listen(mapped.add, onError: mapped.addError);
    statusSub = status.listen(
      mapped.addStatus,
      onError: (error, stackTrace) => mapped.addError(error, stackTrace),
    );

    mapped.onClose = () async {
      await dataSub?.cancel();
      await statusSub?.cancel();
      if (closeInner) {
        await close();
      }
    };

    return mapped;
  }

  /// Resets this stream to its initial idle state.
  ///
  /// Cancels all inner data subscriptions, drains accumulated replay and
  /// list state, and sets [status] back to [StreamStatusIdle]. The stream
  /// object identity is preserved — existing listeners on [stream] and
  /// [status] stay attached and will see new data when [_init] is called
  /// again.
  ///
  /// Callers that derived streams via [where], [map], etc. with
  /// `closeInner: false` will naturally stop receiving data after reset
  /// (source goes idle) and resume when new data flows in.
  Future<void> reset() async {
    // 1. Cancel all inner data-producing subscriptions.
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    // 2. Tear down and rebuild the replay infrastructure.
    await _replaySubscription.cancel();
    await _replaySubject.close();
    _replaySubject = ReplaySubject<T>();
    _setupReplay();

    // 3. Reset accumulated list.
    _listSubject.add(List<T>.unmodifiable(<T>[]));

    // 4. Return to idle.
    status.add(StreamStatusIdle());

    // 5. Notify derived streams (onClose callback handles their cleanup).
    await onClose?.call();
    onClose = null;
  }

  Future<void> close() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _replaySubscription.cancel();
    await _replaySubject.close();
    await onClose?.call();
    await controller.close();
    await status.close();
    await _listSubject.close();
  }

  Map<String, dynamic> toJson() {
    return {"items": list.value.map((el) => el.toString())};
  }

  // static SubscriptionResponse<T> fromJson<T extends Nip01Event>(
  //   Map<String, dynamic> json,
  // ) {
  //   final response = SubscriptionResponse(json["requestId"]);
  //   response.addAll(jsonDecode(json["items"]).map((el)));
  // }
}

class DynamicCombinedStreamWithStatus<T> extends StreamWithStatus<T> {
  final bool closeInner;

  final List<StreamWithStatus<T>> _streams = [];
  final List<StreamSubscription<T>> _streamSubscriptions = [];
  final List<StreamSubscription<StreamStatus>> _statusSubscriptions = [];
  final List<StreamStatus> _statusMap = [];

  DynamicCombinedStreamWithStatus({
    Iterable<StreamWithStatus<T>> streams = const [],
    this.closeInner = true,
  }) {
    for (final stream in streams) {
      combine(stream);
    }

    if (_streams.isEmpty) {
      addStatus(StreamStatusLive());
    }

    onClose = () {
      for (final sub in _streamSubscriptions) {
        sub.cancel();
      }
      for (final sub in _statusSubscriptions) {
        sub.cancel();
      }
      if (closeInner) {
        for (final stream in _streams) {
          stream.close();
        }
      }
    };
  }

  @override
  Future<void> reset() async {
    // Cancel all per-stream subscriptions.
    for (final sub in _streamSubscriptions) {
      await sub.cancel();
    }
    _streamSubscriptions.clear();
    for (final sub in _statusSubscriptions) {
      await sub.cancel();
    }
    _statusSubscriptions.clear();

    // Optionally close inner streams.
    if (closeInner) {
      for (final stream in _streams) {
        await stream.close();
      }
    }
    _streams.clear();
    _statusMap.clear();

    await super.reset();
  }

  void combine(StreamWithStatus<T> stream) {
    _streams.add(stream);
    _statusMap.add(stream.status.value);

    _streamSubscriptions.add(stream.stream.listen(add, onError: addError));
    _statusSubscriptions.add(
      stream.status.listen(
        (status) {
          final index = _streams.indexOf(stream);
          if (index != -1) {
            _statusMap[index] = status;
            _recomputeStatus();
          }
        },
        onError: addError,
        onDone: () {
          // When a child stream closes, treat it as live/done so it
          // doesn't permanently block the combined status.
          final index = _streams.indexOf(stream);
          if (index != -1) {
            _statusMap[index] = StreamStatusLive();
            _recomputeStatus();
          }
        },
      ),
    );

    _recomputeStatus();
  }

  void _recomputeStatus() {
    StreamStatusError? errorStatus;
    for (final status in _statusMap) {
      if (status is StreamStatusError) {
        errorStatus = status;
        break;
      }
    }
    if (errorStatus != null) {
      addStatus(StreamStatusError(errorStatus.error, errorStatus.stackTrace));
      return;
    }
    if (_statusMap.any((s) => s is StreamStatusQuerying)) {
      addStatus(StreamStatusQuerying());
      return;
    }
    if (_statusMap.any((s) => s is StreamStatusLive)) {
      addStatus(StreamStatusLive());
      return;
    }
    if (_statusMap.any((s) => s is StreamStatusQueryComplete)) {
      addStatus(StreamStatusQueryComplete());
      return;
    }
    addStatus(StreamStatusIdle());
  }
}

/// Emits StreamStatusLive only when both streams are live
Stream<StreamStatus> combineStatuses(StreamWithStatus s1, StreamWithStatus s2) {
  return Rx.combineLatest2<StreamStatus, StreamStatus, StreamStatus>(
    s1.status,
    s2.status,
    (a, b) {
      if (a is StreamStatusLive && b is StreamStatusLive) {
        return StreamStatusLive();
      }
      // Optionally, emit other statuses or null
      return StreamStatusIdle();
    },
  ).distinct();
}
