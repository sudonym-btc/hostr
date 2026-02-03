import 'dart:async';
import 'dart:math';

import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/nostr_parser.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Ndk, Nip01Event;
import 'package:rxdart/rxdart.dart';

class SubscriptionStatus {}

class SubscriptionStatusIdle extends SubscriptionStatus {}

class SubscriptionStatusQuerying extends SubscriptionStatus {}

class SubscriptionStatusQueryComplete extends SubscriptionStatus {}

class SubscriptionStatusLive extends SubscriptionStatus {}

class SubscriptionStatusError extends SubscriptionStatus {
  final Object? error;
  final StackTrace? stackTrace;
  SubscriptionStatusError(this.error, this.stackTrace);
}

enum SubscriptionPhase { querying, queryComplete, live, error, idle }

/// Represents a response from a Nostr Development Kit (NDK) subscription.
class SubscriptionResponse<T extends Nip01Event> {
  /// The unique identifier for the request that generated this response.
  String requestId;

  Function? onClose;

  StreamController<T> controller = StreamController<T>.broadcast();
  StreamController<SubscriptionStatus> statusController =
      StreamController<SubscriptionStatus>.broadcast();

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

  /// A stream reporting the subscription status.
  late final ValueStream<SubscriptionStatus> status = statusController.stream
      .shareValueSeeded(SubscriptionStatusIdle());

  SubscriptionResponse(this.requestId, {this.onClose}) {
    _replaySubscription = controller.stream.listen(
      _replaySubject.add,
      onError: _replaySubject.addError,
      onDone: _replaySubject.close,
    );
  }

  addError(Object error, StackTrace? stackTrace) {
    statusController.add(SubscriptionStatusError(error, stackTrace));
    controller.addError(error, stackTrace);
  }

  addStatus(SubscriptionStatus status) {
    statusController.add(status);
  }

  add(T item) {
    controller.add(item);
    final current = _listSubject.value;
    _listSubject.add(List.unmodifiable([...current, item]));
  }

  addAll(List<T> items) {
    for (final item in items) {
      add(item);
    }
  }

  close() {
    controller.close();
    statusController.close();
    _listSubject.close();
    _replaySubscription.cancel();
    _replaySubject.close();
    onClose?.call();
  }

  Map<String, dynamic> toJson() {
    return {
      "requestId": requestId,
      "items": list.value.map((el) => el.toString()),
    };
  }

  // static SubscriptionResponse<T> fromJson<T extends Nip01Event>(
  //   Map<String, dynamic> json,
  // ) {
  //   final response = SubscriptionResponse(json["requestId"]);
  //   response.addAll(jsonDecode(json["items"]).map((el)));
  // }
}

abstract class RequestsModel {
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  });
  SubscriptionResponse<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  });
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  });

  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  });

  Future<void> mock();
}

@Singleton(env: Env.allButTestAndMock)
class Requests extends RequestsModel {
  final Ndk ndk;
  Requests({required this.ndk});

  // NDK does not let us subscribe to fetch old events, complete, and keep streaming, so we have to implement our own version
  @override
  SubscriptionResponse<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  }) {
    final queryResponse = ndk.requests.query(
      filter: filter,
      cacheRead: false,
      cacheWrite: false,
    );

    final subName = '${queryResponse.requestId}-sub';

    final response = SubscriptionResponse<T>(
      queryResponse.requestId,
      onClose: () {
        ndk.requests.closeSubscription(subName);
      },
    );

    response.addStatus(SubscriptionStatusQuerying());

    queryResponse.stream
        .asyncMap((event) async => parserWithGiftWrap<T>(event, ndk))
        .doOnError(response.addError)
        .doOnDone(() {
          response.addStatus(SubscriptionStatusQueryComplete());

          final liveFilter = filter.clone();
          final maxCreatedAt = response.list.value.isEmpty
              ? null
              : response.list.value.map((e) => e.createdAt).reduce(max);
          liveFilter.since = maxCreatedAt == null
              ? liveFilter.since
              : (liveFilter.since == null ||
                        maxCreatedAt + 1 > liveFilter.since!
                    ? maxCreatedAt + 1
                    : liveFilter.since);
          final subResponse = ndk.requests.subscription(
            id: subName,
            filter: liveFilter,
            cacheRead: false,
            cacheWrite: false,
          );
          response.requestId = subResponse.requestId;
          response.addStatus(SubscriptionStatusLive());

          subResponse.stream
              .asyncMap((event) async => parserWithGiftWrap<T>(event, ndk))
              .listen(response.add, onError: response.addError);
        })
        .listen(response.add);

    return response;
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
  }) {
    return ndk.requests
        .query(
          filter: filter,
          cacheRead: false,
          cacheWrite: false,
          timeout: timeout,
        )
        .stream
        .asyncMap((event) async {
          return parserWithGiftWrap<T>(event, ndk);
        });
  }

  // @TODO: There must be a better way to do this
  @override
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  }) async {
    var results = await query(
      filter: filter,
      timeout: timeout,
      relays: relays,
    ).toList();
    return results.length;
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) {
    return ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;
  }

  @override
  Future<void> mock() {
    // TODO: implement mock
    throw UnimplementedError();
  }
}
