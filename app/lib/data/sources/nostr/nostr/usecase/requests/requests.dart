import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/nostr_parser.dart';
import 'package:ndk/entities.dart'
    show RelayBroadcastResponse, RelayConnectivity;
import 'package:ndk/ndk.dart' show Nip01Event, Filter, Ndk;

abstract class RequestsModel {
  Stream<T> startRequest<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  });
  Stream<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  });
  Future<List<T>> startRequestAsync<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
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

  List<RelayConnectivity> connectivity();

  Future<void> mock();
}

@Singleton(env: Env.allButTestAndMock)
class Requests extends RequestsModel {
  final Ndk ndk;
  Requests({required this.ndk});

  @override
  Stream<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  }) {
    return ndk.requests
        .subscription(filter: filter, cacheRead: false, cacheWrite: false)
        .stream
        .asyncMap((event) async {
          return parserWithGiftWrap<T>(event, ndk);
        })
        .cast<T>();
  }

  @override
  Stream<T> startRequest<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  }) {
    return ndk.requests
        .query(filter: filter, cacheRead: false, cacheWrite: false)
        .stream
        .asyncMap((event) async {
          return parserWithGiftWrap<T>(event, ndk);
        })
        .cast<T>();
  }

  @override
  startRequestAsync<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  }) async {
    return startRequest<T>(filter: filter).toList();
  }

  @override
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  }) async {
    var results = await startRequestAsync(
      filter: filter,
      timeout: timeout,
      relays: relays,
    );
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
  List<RelayConnectivity> connectivity() {
    return ndk.relays.connectedRelays;
  }

  @override
  Future<void> mock() {
    // TODO: implement mock
    throw UnimplementedError();
  }

  // @override
  // count(Filter filter) {
  //   return ndk.requests.;
  // }
}
