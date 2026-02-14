import 'dart:async';
import 'dart:math';

import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:injectable/injectable.dart';
import 'package:models/nostr_parser.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Ndk, Nip01Event;
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:rxdart/rxdart.dart';

abstract class RequestsModel {
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  });
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
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
  final bool useCache = false;
  Requests({required this.ndk});

  // NDK does not let us subscribe to fetch old events, complete, and keep streaming, so we have to implement our own version
  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  }) {
    final ndkSubName = "sub-${Helpers.getRandomString(10)}";

    final response = StreamWithStatus<T>(
      onClose: () async {
        await ndk.requests.closeSubscription(ndkSubName);
      },
    );

    response.addStatus(StreamStatusQuerying());

    // @todo: should i be using queryFn, liveFn, which automatically cancels subscriptions, rather than adding the subscription manually here.
    final subscription = ndk.requests
        .query(filter: cleanTags(filter), cacheRead: true, cacheWrite: true)
        .stream
        .doOnDone(() => response.addStatus(StreamStatusQueryComplete()))
        .concatWith([
          Rx.defer(() {
            final liveFilter = filter.clone();
            final maxCreatedAt = response.list.value.isEmpty
                ? null
                : response.list.value.map((e) => e.createdAt).reduce(max);
            final nextSince = maxCreatedAt == null ? null : maxCreatedAt + 1;
            liveFilter.since = maxCreatedAt == null
                ? liveFilter.since
                : (liveFilter.since == null || nextSince! > liveFilter.since!
                      ? nextSince
                      : liveFilter.since);
            response.addStatus(StreamStatusLive());

            return ndk.requests
                .subscription(
                  id: ndkSubName,
                  filter: cleanTags(liveFilter),
                  cacheRead: useCache,
                  cacheWrite: true,
                )
                .stream;
          }),
        ])
        .asyncMap((event) async => parserWithGiftWrap<T>(event, ndk))
        .listen(response.add, onError: response.addError);
    response.addSubscription(subscription);

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
          cacheRead: useCache,
          cacheWrite: true,
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
