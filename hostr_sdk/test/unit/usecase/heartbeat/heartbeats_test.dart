@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/heartbeat/heartbeat.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeRequests extends Fake implements Requests {
  final StreamWithStatus<ReceivedHeartbeat> subscribeSource =
      StreamWithStatus<ReceivedHeartbeat>();
  final StreamController<ReceivedHeartbeat> queryController =
      StreamController<ReceivedHeartbeat>.broadcast();

  Filter? lastSubscribeFilter;
  Filter? lastQueryFilter;
  Nip01Event? lastBroadcastEvent;

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  }) {
    lastSubscribeFilter = filter;
    return subscribeSource as StreamWithStatus<T>;
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
  }) {
    lastQueryFilter = filter;
    return queryController.stream as Stream<T>;
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    lastBroadcastEvent = event;
    return const <RelayBroadcastResponse>[];
  }

  Future<void> dispose() async {
    await subscribeSource.close();
    if (!queryController.isClosed) {
      await queryController.close();
    }
  }
}

class _FakeAuth extends Fake implements Auth {
  @override
  KeyPair? activeKeyPair = MockKeys.hoster;

  @override
  KeyPair getActiveKey() => activeKeyPair!;
}

ReceivedHeartbeat _heartbeat({
  required KeyPair keyPair,
  required int createdAt,
}) {
  return ReceivedHeartbeat.create(
    pubKey: keyPair.publicKey,
    createdAt: createdAt,
  ).signAs(keyPair, ReceivedHeartbeat.fromNostrEvent);
}

void main() {
  late Heartbeats heartbeats;
  late _FakeRequests requests;
  late _FakeAuth auth;

  setUp(() {
    requests = _FakeRequests();
    auth = _FakeAuth();
    heartbeats = Heartbeats(
      requests: requests,
      logger: CustomLogger(),
      auth: auth,
    );
  });

  tearDown(() async {
    await requests.dispose();
  });

  test('upsertCurrent broadcasts a signed heartbeat for the active user', () async {
    final heartbeat = await heartbeats.upsertCurrent(createdAt: 1710000000);

    expect(heartbeat.pubKey, MockKeys.hoster.publicKey);
    expect(heartbeat.kind, kNostrKindReceivedHeartbeat);
    expect(heartbeat.sig, isNotNull);
    expect(heartbeat.valid(), isTrue);

    final broadcast = requests.lastBroadcastEvent as ReceivedHeartbeat?;
    expect(broadcast, isNotNull);
    expect(broadcast!.pubKey, MockKeys.hoster.publicKey);
    expect(broadcast.createdAt, 1710000000);
  });

  test('subscribeUsers constrains the filter to heartbeat kind and authors', () {
    final stream = heartbeats.subscribeUsers([
      MockKeys.hoster.publicKey,
      MockKeys.guest.publicKey,
      MockKeys.hoster.publicKey,
    ]);

    expect(stream, isNotNull);
    expect(
      requests.lastSubscribeFilter?.authors,
      orderedEquals([MockKeys.guest.publicKey, MockKeys.hoster.publicKey]..sort()),
    );
    expect(
      requests.lastSubscribeFilter?.kinds,
      orderedEquals([kNostrKindReceivedHeartbeat]),
    );
  });

  test('queryUsers constrains the filter to heartbeat kind and authors', () async {
    final stream = heartbeats.queryUsers([MockKeys.hoster.publicKey]);

    expect(stream, isNotNull);
    expect(requests.lastQueryFilter?.authors, [MockKeys.hoster.publicKey]);
    expect(requests.lastQueryFilter?.kinds, [kNostrKindReceivedHeartbeat]);

    await stream.close();
  });

  test('latestForUsers returns the newest heartbeat per pubkey', () async {
    final future = heartbeats.latestForUsers([
      MockKeys.hoster.publicKey,
      MockKeys.guest.publicKey,
    ]);

    requests.queryController
      ..add(_heartbeat(keyPair: MockKeys.hoster, createdAt: 100))
      ..add(_heartbeat(keyPair: MockKeys.guest, createdAt: 200))
      ..add(_heartbeat(keyPair: MockKeys.hoster, createdAt: 300));
    await requests.queryController.close();

    final latest = await future;

    expect(latest.keys, containsAll([MockKeys.hoster.publicKey, MockKeys.guest.publicKey]));
    expect(latest[MockKeys.hoster.publicKey]?.createdAt, 300);
    expect(latest[MockKeys.guest.publicKey]?.createdAt, 200);
  });

  test('subscribeUsers rejects empty pubkey lists', () {
    expect(() => heartbeats.subscribeUsers(const []), throwsArgumentError);
  });
}
