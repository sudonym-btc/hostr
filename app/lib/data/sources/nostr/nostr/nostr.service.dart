import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/local/key_storage.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

abstract class NostrService {
  CustomLogger logger = CustomLogger();
  ReplaySubject<Event> events = ReplaySubject<Event>();

  Stream<T> startRequest<T extends Event>(
      {required List<Filter> filters, List<String>? relays});
  Stream<T> subscribe<T extends Event>(
      {required List<Filter> filters, List<String>? relays});
  Future<List<T>> startRequestAsync<T extends Event>(
      {required List<Filter> filters, Duration? timeout, List<String>? relays});
  Future<int> count(
      {required List<Filter> filters, Duration? timeout, List<String>? relays});

  Future<List<RelayBroadcastResponse>> broadcast(
      {required Nip01Event event, List<String>? relays});
}

@Singleton(as: NostrService)
class ProdNostrService extends NostrService {
  @override
  Stream<T> subscribe<T extends Event>(
      {required List<Filter> filters, List<String>? relays}) {
    return getIt<Ndk>()
        .requests
        .subscription(filters: filters, cacheRead: false, cacheWrite: false)
        .stream
        .asyncMap((event) async {
      return parser<T>(event, await getIt<KeyStorage>().getActiveKeyPair());
    });
  }

  @override
  Stream<T> startRequest<T extends Event>(
      {required List<Filter> filters, List<String>? relays}) {
    return getIt<Ndk>()
        .requests
        .query(filters: filters, cacheRead: false, cacheWrite: false)
        .stream
        .asyncMap((event) async {
      return parser<T>(event, await getIt<KeyStorage>().getActiveKeyPair());
    });
  }

  @override
  startRequestAsync<T extends Event>(
      {required List<Filter> filters,
      Duration? timeout,
      List<String>? relays}) async {
    return startRequest<T>(filters: filters).toList();
  }

  @override
  Future<int> count(
      {required List<Filter> filters,
      Duration? timeout,
      List<String>? relays}) async {
    var results = await startRequestAsync(
        filters: filters, timeout: timeout, relays: relays);
    return results.length;
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast(
      {required Nip01Event event, List<String>? relays}) {
    return getIt<Ndk>()
        .broadcast
        .broadcast(nostrEvent: event)
        .broadcastDoneFuture;
  }

  // @override
  // count(Filter filter) {
  //   return ndk.requests.;
  // }
}
