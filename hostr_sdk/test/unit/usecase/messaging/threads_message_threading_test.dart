@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/messaging/thread.dart';
import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/payments/payments.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart' as hydrated;
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _InMemoryHydratedStorage implements hydrated.Storage {
  final Map<String, dynamic> _values = {};

  @override
  dynamic read(String key) => _values[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }

  @override
  Future<void> close() async {}
}

class _FakeRequests extends Fake implements Requests {
  final StreamWithStatus<Message> _source = StreamWithStatus<Message>();

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  }) {
    return _source as StreamWithStatus<T>;
  }

  void emit(Message event) => _source.add(event);

  void emitStatus(StreamStatus status) => _source.addStatus(status);

  Future<void> close() => _source.close();
}

class _FakeMessaging extends Fake implements Messaging {}

class _FakePayments extends Fake implements Payments {}

class _FakeAuth extends Fake implements Auth {
  @override
  KeyPair? activeKeyPair = MockKeys.guest;

  @override
  KeyPair getActiveKey() => activeKeyPair!;
}

Message _textMessage({
  required String id,
  required String sender,
  required List<String> recipients,
  String? threadTag,
  required int createdAt,
}) {
  return Message(
    id: id,
    pubKey: sender,
    content: 'hello-$id',
    createdAt: createdAt,
    tags: MessageTags([
      for (final recipient in recipients) ['p', recipient],
      if (threadTag != null) [kThreadRefTag, threadTag],
    ]),
  );
}

Future<void> _pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  late Threads threads;
  late _FakeRequests requests;
  late _FakeAuth auth;

  setUpAll(() {
    hydrated.HydratedBloc.storage = _InMemoryHydratedStorage();
  });

  setUp(() async {
    requests = _FakeRequests();
    auth = _FakeAuth();

    await getIt.reset();
    getIt.registerFactoryParam<Thread, String, dynamic>((anchor, _) {
      return Thread(
        anchor,
        logger: CustomLogger(),
        auth: auth,
        messaging: _FakeMessaging(),
      );
    });

    threads = Threads(
      messaging: _FakeMessaging(),
      requests: requests,
      auth: auth,
      logger: CustomLogger(),
      payments: _FakePayments(),
    );
  });

  tearDown(() async {
    threads.stop();
    await getIt.reset();
  });

  test(
    'creates threads from stream and reuses existing thread anchors',
    () async {
      final createdAnchors = <String>[];
      final sub = threads.threadStream.listen((thread) {
        createdAnchors.add(thread.anchor);
      });

      threads.sync();

      requests.emitStatus(StreamStatusLive());
      requests.emit(
        _textMessage(
          id: 'm-1',
          sender: MockKeys.guest.publicKey,
          recipients: [MockKeys.hoster.publicKey],
          threadTag: 'thread-a',
          createdAt: 100,
        ),
      );
      await _pump();

      expect(threads.threads.length, 1);
      expect(threads.threads.containsKey('thread-a'), isTrue);
      expect(threads.threads['thread-a']!.state.value.messages.length, 1);

      requests.emit(
        _textMessage(
          id: 'm-2',
          sender: MockKeys.hoster.publicKey,
          recipients: [MockKeys.guest.publicKey],
          threadTag: 'thread-a',
          createdAt: 101,
        ),
      );
      await _pump();

      expect(threads.threads.length, 1);
      expect(threads.threads['thread-a']!.state.value.messages.length, 2);

      requests.emit(
        _textMessage(
          id: 'm-3',
          sender: MockKeys.guest.publicKey,
          recipients: [MockKeys.hoster.publicKey],
          threadTag: 'thread-b',
          createdAt: 102,
        ),
      );
      await _pump();

      expect(threads.threads.length, 2);
      expect(threads.threads.containsKey('thread-b'), isTrue);
      expect(createdAnchors, ['thread-a', 'thread-b']);

      await sub.cancel();
    },
  );

  test(
    'creates a new thread when a new thread tag appears in stream',
    () async {
      threads.sync();

      requests.emit(
        _textMessage(
          id: 'm-4',
          sender: MockKeys.guest.publicKey,
          recipients: [MockKeys.hoster.publicKey],
          threadTag: 'thread-x',
          createdAt: 110,
        ),
      );
      requests.emit(
        _textMessage(
          id: 'm-5',
          sender: MockKeys.hoster.publicKey,
          recipients: [MockKeys.guest.publicKey],
          threadTag: 'thread-y',
          createdAt: 111,
        ),
      );
      await _pump();

      expect(threads.threads.length, 2);
      expect(threads.threads.containsKey('thread-x'), isTrue);
      expect(threads.threads.containsKey('thread-y'), isTrue);
      expect(threads.threads['thread-x']!.state.value.messages.length, 1);
      expect(threads.threads['thread-y']!.state.value.messages.length, 1);
    },
  );

  test('ignores duplicate message ids from stream', () async {
    threads.sync();

    final message = _textMessage(
      id: 'm-dup',
      sender: MockKeys.guest.publicKey,
      recipients: [MockKeys.hoster.publicKey],
      threadTag: 'thread-dup',
      createdAt: 110,
    );

    requests.emit(message);
    requests.emit(message);
    await _pump();

    expect(threads.state.length, 1);
    expect(threads.threads.length, 1);
    expect(threads.threads['thread-dup']!.state.value.messages.length, 1);
  });
}
