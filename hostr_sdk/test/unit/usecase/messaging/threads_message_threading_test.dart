@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/messaging/thread.dart';
import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeUserSubscriptions extends Fake implements UserSubscriptions {
  @override
  final StreamWithStatus<Message> messages$ = StreamWithStatus<Message>();

  @override
  bool get started => true;

  void emit(Message event) => messages$.add(event);

  void emitStatus(StreamStatus status) => messages$.addStatus(status);

  Future<void> close() => messages$.close();
}

class _FakeMessaging extends Fake implements Messaging {
  String? lastContent;
  List<List<String>>? lastTags;
  List<String>? lastRecipientPubkeys;

  @override
  Future<Message> broadcastTextAndAwait({
    required String content,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) async {
    lastContent = content;
    lastTags = tags;
    lastRecipientPubkeys = recipientPubkeys;

    return Message(
      id: 'awaited-message',
      pubKey: MockKeys.guest.publicKey,
      content: content,
      createdAt: 999,
      tags: MessageTags([
        ...tags,
        for (final recipient in recipientPubkeys) ['p', recipient],
      ]),
    );
  }
}

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
  late _FakeUserSubscriptions userSubscriptions;
  late _FakeAuth auth;
  late _FakeMessaging messaging;

  setUp(() async {
    userSubscriptions = _FakeUserSubscriptions();
    auth = _FakeAuth();
    messaging = _FakeMessaging();

    await getIt.reset();
    getIt.registerFactoryParam<Thread, String, dynamic>((anchor, _) {
      return Thread(
        anchor,
        logger: CustomLogger(),
        auth: auth,
        messaging: messaging,
      );
    });

    threads = Threads(
      messaging: messaging,
      userSubscriptions: userSubscriptions,
      logger: CustomLogger(),
    );
  });

  tearDown(() async {
    await threads.stop();
    await getIt.reset();
  });

  test(
    'creates threads from stream and reuses existing thread anchors',
    () async {
      final createdAnchors = <String>[];
      final sub = threads.threadStream.listen((thread) {
        createdAnchors.add(thread.anchor);
      });

      await threads.sync();

      userSubscriptions.emitStatus(StreamStatusLive());
      userSubscriptions.emit(
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

      userSubscriptions.emit(
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

      userSubscriptions.emit(
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
      await threads.sync();

      userSubscriptions.emit(
        _textMessage(
          id: 'm-4',
          sender: MockKeys.guest.publicKey,
          recipients: [MockKeys.hoster.publicKey],
          threadTag: 'thread-x',
          createdAt: 110,
        ),
      );
      userSubscriptions.emit(
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
    await threads.sync();

    final message = _textMessage(
      id: 'm-dup',
      sender: MockKeys.guest.publicKey,
      recipients: [MockKeys.hoster.publicKey],
      threadTag: 'thread-dup',
      createdAt: 110,
    );

    userSubscriptions.emit(message);
    userSubscriptions.emit(message);
    await _pump();

    expect(threads.state.length, 1);
    expect(threads.threads.length, 1);
    expect(threads.threads['thread-dup']!.state.value.messages.length, 1);
  });

  test(
    'replyTextAndWait sends to current counterparties for the thread',
    () async {
      final thread = Thread(
        'thread-reply',
        logger: CustomLogger(),
        auth: auth,
        messaging: messaging,
      );

      thread.messages.add(
        _textMessage(
          id: 'existing',
          sender: MockKeys.hoster.publicKey,
          recipients: [MockKeys.guest.publicKey],
          threadTag: 'thread-reply',
          createdAt: 100,
        ),
      );
      await _pump();

      final message = await thread.replyTextAndWait('  hello back  ');

      expect(message.id, 'awaited-message');
      expect(messaging.lastContent, 'hello back');
      expect(messaging.lastTags, [
        [kThreadRefTag, 'thread-reply'],
      ]);
      expect(messaging.lastRecipientPubkeys, [MockKeys.hoster.publicKey]);

      await thread.close();
    },
  );
}
