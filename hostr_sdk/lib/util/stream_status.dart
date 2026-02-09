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

  late final ReplaySubject<T> _replaySubject = ReplaySubject<T>();
  late final StreamSubscription<T> _replaySubscription;

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
    _replaySubscription = controller.stream.listen(
      _replaySubject.add,
      onError: _replaySubject.addError,
      onDone: _replaySubject.close,
    );

    if (queryFn != null || liveFn != null) {
      _init(queryFn: queryFn, liveFn: liveFn);
    }
  }

  static StreamWithStatus<T> combineAll<T>(
    Iterable<StreamWithStatus<T>> streams, {
    bool closeInner = true,
  }) {
    final combined = StreamWithStatus<T>();
    final streamList = streams.toList();

    if (streamList.isEmpty) {
      combined.addStatus(StreamStatusLive());
      return combined;
    }

    final statusMap = List<StreamStatus>.generate(
      streamList.length,
      (index) => streamList[index].status.value,
    );

    void recomputeStatus() {
      StreamStatusError? errorStatus;
      for (final status in statusMap) {
        if (status is StreamStatusError) {
          errorStatus = status;
          break;
        }
      }
      if (errorStatus != null) {
        combined.addStatus(
          StreamStatusError(errorStatus.error, errorStatus.stackTrace),
        );
        return;
      }
      if (statusMap.any((s) => s is StreamStatusQuerying)) {
        combined.addStatus(StreamStatusQuerying());
        return;
      }
      if (statusMap.any((s) => s is StreamStatusLive)) {
        combined.addStatus(StreamStatusLive());
        return;
      }
      if (statusMap.any((s) => s is StreamStatusQueryComplete)) {
        combined.addStatus(StreamStatusQueryComplete());
        return;
      }
      combined.addStatus(StreamStatusIdle());
    }

    final streamSubscriptions = <StreamSubscription>[],
        statusSubscriptions = <StreamSubscription>[];

    for (var i = 0; i < streamList.length; i++) {
      final current = streamList[i];
      streamSubscriptions.add(
        current.stream.listen(combined.add, onError: combined.addError),
      );
      statusSubscriptions.add(
        current.status.listen((status) {
          statusMap[i] = status;
          recomputeStatus();
        }, onError: combined.addError),
      );
    }

    recomputeStatus();

    combined.onClose = () {
      for (final sub in streamSubscriptions) {
        sub.cancel();
      }
      for (final sub in statusSubscriptions) {
        sub.cancel();
      }
      if (closeInner) {
        for (final stream in streamList) {
          stream.close();
        }
      }
    };

    return combined;
  }

  static StreamWithStatus<T> combineAsync<T>(
    Future<Iterable<StreamWithStatus<T>>> streamsFuture, {
    bool closeInner = true,
  }) {
    final combined = StreamWithStatus<T>();
    combined.addStatus(StreamStatusQuerying());

    StreamWithStatus<T>? innerCombined;
    StreamSubscription<T>? innerStreamSub;
    StreamSubscription<StreamStatus>? innerStatusSub;

    streamsFuture
        .then((streams) {
          innerCombined = StreamWithStatus.combineAll(
            streams,
            closeInner: closeInner,
          );
          innerStreamSub = innerCombined!.stream.listen(
            combined.add,
            onError: combined.addError,
          );
          innerStatusSub = innerCombined!.status.listen(
            combined.addStatus,
            onError: combined.addError,
          );
        })
        .catchError((error, stackTrace) {
          combined.addError(error, stackTrace);
        });

    combined.onClose = () {
      innerStreamSub?.cancel();
      innerStatusSub?.cancel();
      innerCombined?.close();
    };

    return combined;
  }

  StreamWithStatus<T> combineWith(
    StreamWithStatus<T> other, {
    bool closeInner = true,
  }) {
    return StreamWithStatus.combineAll([this, other], closeInner: closeInner);
  }

  void _init({Stream<T> Function()? queryFn, Stream<T> Function()? liveFn}) {
    if (queryFn != null) {
      addStatus(StreamStatusQuerying());
      final sub = queryFn().listen(
        add,
        onError: addError,
        onDone: () {
          addStatus(StreamStatusQueryComplete());
          if (liveFn != null) {
            addStatus(StreamStatusLive());
            final liveSub = liveFn().listen(add, onError: addError);
            _subscriptions.add(liveSub);
          }
        },
      );
      _subscriptions.add(sub);
      return;
    }
  }

  void addError(Object error, StackTrace? stackTrace) {
    status.add(StreamStatusError(error, stackTrace));
    controller.addError(error, stackTrace);
  }

  void addStatus(StreamStatus newStatus) {
    status.add(newStatus);
  }

  void add(T item) {
    controller.add(item);
    final current = _listSubject.value;
    _listSubject.add(List.unmodifiable([...current, item]));
  }

  void addAll(List<T> items) {
    for (final item in items) {
      add(item);
    }
  }

  void close() {
    controller.close();
    status.close();
    _listSubject.close();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _replaySubscription.cancel();
    _replaySubject.close();
    onClose?.call();
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
