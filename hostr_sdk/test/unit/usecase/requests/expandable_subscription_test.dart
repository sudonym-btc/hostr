@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/crud.usecase.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:test/test.dart';

class _FakeRequests extends Fake implements Requests {
  final Completer<List<RelayBroadcastResponse>>? broadcastCompleter;

  _FakeRequests({this.broadcastCompleter});

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) => Stream<T>.empty();

  @override
  LiveSubscriptionHandle liveSubscription<T extends Nip01Event>({
    required Filter filter,
    required void Function(T event) onData,
    void Function(Object error, StackTrace? stackTrace)? onError,
    required String name,
    List<String>? relays,
  }) => LiveSubscriptionHandle(() async {}, name);

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) => broadcastCompleter?.future ?? Future.value(const []);
}

RelayBroadcastResponse _broadcastResponse({required bool success}) {
  return RelayBroadcastResponse(
    relayUrl: 'wss://relay.test',
    okReceived: true,
    broadcastSuccessful: success,
    msg: success ? '' : 'rejected',
  );
}

void main() {
  test('local updates are emitted when they match the active filter', () async {
    const kind = 123456;
    const tradeId = 'trade-1';
    final updates = StreamController<Nip01Event>.broadcast();
    final filters = StreamWithStatus<Filter>();
    final subscription = ExpandableSubscription<Nip01Event>(
      requests: _FakeRequests(),
      logger: CustomLogger(),
      name: 'test',
      filterSource: filters,
      localUpdates: updates.stream,
      debounceDuration: Duration.zero,
    );

    filters.add(Filter(kinds: [kind], dTags: const [tradeId]));
    filters.addStatus(StreamStatusLive());
    await Future<void>.delayed(Duration.zero);

    updates.add(
      Nip01Event(
        id: 'other-event',
        pubKey: 'author',
        kind: kind,
        tags: const [
          ['d', 'other-trade'],
        ],
        content: '',
      ),
    );

    final matching = Nip01Event(
      id: 'matching-event',
      pubKey: 'author',
      kind: kind,
      tags: const [
        ['d', tradeId],
      ],
      content: '',
    );

    final emitted = expectLater(subscription.stream.stream, emits(matching));
    updates.add(matching);
    await emitted;

    await subscription.close();
    await filters.close();
    await updates.close();
  });

  test('upsert emits local updates after broadcast completes', () async {
    const kind = 123456;
    final broadcastCompleter = Completer<List<RelayBroadcastResponse>>();
    final useCase = CrudUseCase<Nip01Event>(
      requests: _FakeRequests(broadcastCompleter: broadcastCompleter),
      kind: kind,
      logger: CustomLogger(),
    );
    final event = Nip01Event(
      id: 'upsert-event',
      pubKey: 'author',
      kind: kind,
      tags: const [
        ['d', 'trade-1'],
      ],
      content: '',
    );

    var emitted = false;
    final sub = useCase.updates.listen((_) {
      emitted = true;
    });
    final upsertFuture = useCase.upsert(event);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isFalse);
    broadcastCompleter.complete([_broadcastResponse(success: true)]);
    await upsertFuture;
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isTrue);
    await sub.cancel();
  });

  test('upsert does not emit local updates when broadcast fails', () async {
    const kind = 123456;
    final broadcastCompleter = Completer<List<RelayBroadcastResponse>>();
    final useCase = CrudUseCase<Nip01Event>(
      requests: _FakeRequests(broadcastCompleter: broadcastCompleter),
      kind: kind,
      logger: CustomLogger(),
    );
    final event = Nip01Event(
      id: 'failed-upsert-event',
      pubKey: 'author',
      kind: kind,
      tags: const [
        ['d', 'trade-1'],
      ],
      content: '',
    );

    var emitted = false;
    final sub = useCase.updates.listen((_) {
      emitted = true;
    });
    final upsertFuture = useCase.upsert(event);
    await Future<void>.delayed(Duration.zero);

    broadcastCompleter.completeError(StateError('relay rejected event'));
    await expectLater(upsertFuture, throwsStateError);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isFalse);
    await sub.cancel();
  });

  test('upsert does not emit local updates when all relays reject', () async {
    const kind = 123456;
    final broadcastCompleter = Completer<List<RelayBroadcastResponse>>();
    final useCase = CrudUseCase<Nip01Event>(
      requests: _FakeRequests(broadcastCompleter: broadcastCompleter),
      kind: kind,
      logger: CustomLogger(),
    );
    final event = Nip01Event(
      id: 'rejected-upsert-event',
      pubKey: 'author',
      kind: kind,
      tags: const [
        ['d', 'trade-1'],
      ],
      content: '',
    );

    var emitted = false;
    final sub = useCase.updates.listen((_) {
      emitted = true;
    });
    final upsertFuture = useCase.upsert(event);
    await Future<void>.delayed(Duration.zero);

    broadcastCompleter.complete([_broadcastResponse(success: false)]);
    await expectLater(upsertFuture, throwsStateError);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isFalse);
    await sub.cancel();
  });
}
