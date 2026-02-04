import 'dart:async';
import 'dart:math';

import 'package:hostr/data/repositories/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/nostr_parser.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Ndk, Nip01Event;
import 'package:ndk/shared/nips/nip01/helpers.dart';
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
  Function? onClose;

  StreamController<T> controller = StreamController<T>.broadcast();
  BehaviorSubject<SubscriptionStatus> status =
      BehaviorSubject<SubscriptionStatus>.seeded(SubscriptionStatusIdle());

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

  SubscriptionResponse({this.onClose}) {
    _replaySubscription = controller.stream.listen(
      _replaySubject.add,
      onError: _replaySubject.addError,
      onDone: _replaySubject.close,
    );
  }

  addError(Object error, StackTrace? stackTrace) {
    status.add(SubscriptionStatusError(error, stackTrace));
    controller.addError(error, stackTrace);
  }

  addStatus(SubscriptionStatus newStatus) {
    status.add(newStatus);
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
    status.close();
    _listSubject.close();
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
    final ndkSubName = "sub-${Helpers.getRandomString(10)}";

    final response = SubscriptionResponse<T>(
      onClose: () {
        ndk.requests.closeSubscription(ndkSubName);
      },
    );

    response.addStatus(SubscriptionStatusQuerying());

    ndk.requests
        .query(filter: cleanTags(filter), cacheRead: false, cacheWrite: false)
        .stream
        .doOnDone(() => response.addStatus(SubscriptionStatusQueryComplete()))
        .concatWith([
          Rx.defer(() {
            final liveFilter = filter.clone();
            final maxCreatedAt = response.list.value.isEmpty
                ? null
                : response.list.value.map((e) => e.createdAt).reduce(max);
            liveFilter.since = maxCreatedAt == null
                ? liveFilter.since
                : (liveFilter.since == null || maxCreatedAt > liveFilter.since!
                      ? maxCreatedAt
                      : liveFilter.since);
            response.addStatus(SubscriptionStatusLive());

            return ndk.requests
                .subscription(
                  id: ndkSubName,
                  filter: cleanTags(liveFilter),
                  cacheRead: false,
                  cacheWrite: false,
                )
                .stream;
          }),
        ])
        .asyncMap((event) async => parserWithGiftWrap<T>(event, ndk))
        .listen(response.add, onError: response.addError);

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
          filter: cleanTags(filter),
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
