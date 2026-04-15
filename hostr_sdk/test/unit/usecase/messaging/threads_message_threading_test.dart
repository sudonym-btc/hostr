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
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeUserSubscriptions extends Fake implements UserSubscriptions {
  @override
  final StreamWithStatus<Nip01Event> giftwraps$ =
      StreamWithStatus<Nip01Event>();

  @override
  final StreamWithStatus<ReceivedHeartbeat> latestHeartbeats$ =
      StreamWithStatus<ReceivedHeartbeat>();

  @override
  bool get started => true;

  void emit(Message event) => giftwraps$.add(event);

  void emitStatus(StreamStatus status) => giftwraps$.addStatus(status);

  void emitHeartbeat(ReceivedHeartbeat event) => latestHeartbeats$.add(event);

  Future<void> close() async {
    await giftwraps$.close();
    await latestHeartbeats$.close();
  }
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
  String? conversationTag,
  required int createdAt,
}) {
  return Message(
    id: id,
    pubKey: sender,
    content: 'hello-$id',
    createdAt: createdAt,
    tags: MessageTags([
      for (final recipient in recipients) ['p', recipient],
      if (conversationTag != null) [kConversationTag, conversationTag],
    ]),
  );
}

/// Flush the event loop so stream listeners have a chance to process events.
Future<void> _pump() => Future<void>.delayed(Duration.zero);

/// Shorthand: conversation ID for guest+hoster (+ optional extras) with a tag.
String _cid(String tag, [List<String> extra = const []]) =>
    Threads.conversationIdentifier([
      MockKeys.guest.publicKey,
      MockKeys.hoster.publicKey,
      ...extra,
    ], conversationTag: tag);

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
        userSubscriptions: userSubscriptions,
      );
    });

    threads = Threads(
      auth: auth,
      userSubscriptions: userSubscriptions,
      logger: CustomLogger(),
    );
  });

  tearDown(() async {
    await threads.stop();
    await getIt.reset();
  });

  test(
    'groups same participants and conversation tag into one thread',
    () async {
      final createdAnchors = <String>[];
      final sub = threads.threadStream.listen((thread) {
        createdAnchors.add(thread.anchor);
      });
      final conversationId = _cid('trade-1');

      userSubscriptions.emitStatus(StreamStatusLive());
      userSubscriptions.emit(
        _textMessage(
          id: 'm-1',
          sender: MockKeys.guest.publicKey,
          recipients: [MockKeys.hoster.publicKey],
          conversationTag: 'trade-1',
          createdAt: 100,
        ),
      );
      await _pump();

      expect(threads.threads.length, 1);
      expect(threads.threads.containsKey(conversationId), isTrue);
      expect(
        threads.threads[conversationId]!.state.value.events
            .whereType<Message>()
            .length,
        1,
      );

      userSubscriptions.emit(
        _textMessage(
          id: 'm-2',

          sender: MockKeys.hoster.publicKey,
          recipients: [MockKeys.guest.publicKey],
          conversationTag: 'trade-1',
          createdAt: 101,
        ),
      );
      await _pump();

      expect(threads.threads.length, 1);
      expect(
        threads.threads[conversationId]!.state.value.events
            .whereType<Message>()
            .length,
        2,
      );

      userSubscriptions.emit(
        _textMessage(
          id: 'm-3',

          sender: MockKeys.guest.publicKey,
          recipients: [MockKeys.hoster.publicKey],
          conversationTag: 'trade-1',
          createdAt: 102,
        ),
      );
      await _pump();

      expect(threads.threads.length, 1);
      expect(
        threads.threads[conversationId]!.state.value.events
            .whereType<Message>()
            .length,
        3,
      );
      expect(createdAnchors, [conversationId]);

      await sub.cancel();
    },
  );

  test('creates a new thread when conversation tag changes', () async {
    final firstConversationId = _cid('trade-x');
    final secondConversationId = _cid('trade-y');

    userSubscriptions.emit(
      _textMessage(
        id: 'm-4',
        sender: MockKeys.guest.publicKey,
        recipients: [MockKeys.hoster.publicKey],
        conversationTag: 'trade-x',
        createdAt: 110,
      ),
    );
    userSubscriptions.emit(
      _textMessage(
        id: 'm-5',
        sender: MockKeys.hoster.publicKey,
        recipients: [MockKeys.guest.publicKey],
        conversationTag: 'trade-y',
        createdAt: 111,
      ),
    );
    await _pump();

    expect(threads.threads.length, 2);
    expect(threads.threads.containsKey(firstConversationId), isTrue);
    expect(threads.threads.containsKey(secondConversationId), isTrue);
    expect(
      threads.threads[firstConversationId]!.state.value.events
          .whereType<Message>()
          .length,
      1,
    );
    expect(
      threads.threads[secondConversationId]!.state.value.events
          .whereType<Message>()
          .length,
      1,
    );
  });

  test('creates a new thread when participant set changes', () async {
    final guestHostConversation = _cid('trade-z');
    final guestHostEscrowConversation = _cid('trade-z', [
      MockKeys.escrow.publicKey,
    ]);

    userSubscriptions.emit(
      _textMessage(
        id: 'm-6',
        sender: MockKeys.guest.publicKey,
        recipients: [MockKeys.hoster.publicKey],
        conversationTag: 'trade-z',
        createdAt: 120,
      ),
    );
    userSubscriptions.emit(
      _textMessage(
        id: 'm-7',
        sender: MockKeys.guest.publicKey,
        recipients: [MockKeys.hoster.publicKey, MockKeys.escrow.publicKey],
        conversationTag: 'trade-z',
        createdAt: 121,
      ),
    );
    await _pump();

    expect(threads.threads.length, 2);
    expect(threads.threads.containsKey(guestHostConversation), isTrue);
    expect(threads.threads.containsKey(guestHostEscrowConversation), isTrue);
  });

  test('ignores duplicate message ids from stream', () async {
    final conversationId = _cid('trade-dup');
    final message = _textMessage(
      id: 'm-dup',
      sender: MockKeys.guest.publicKey,
      recipients: [MockKeys.hoster.publicKey],
      conversationTag: 'trade-dup',
      createdAt: 110,
    );

    userSubscriptions.emit(message);
    userSubscriptions.emit(message);
    await _pump();

    expect(threads.state.length, 1);
    expect(threads.threads.length, 1);
    expect(
      threads.threads[conversationId]!.state.value.events
          .whereType<Message>()
          .length,
      1,
    );
  });

  test(
    'replyTextAndWait sends to current counterparties for the thread',
    () async {
      final thread = Thread(
        'thread-reply',
        logger: CustomLogger(),
        auth: auth,
        messaging: messaging,
        userSubscriptions: userSubscriptions,
      );

      thread.process(
        _textMessage(
          id: 'existing',
          sender: MockKeys.hoster.publicKey,
          recipients: [MockKeys.guest.publicKey],
          conversationTag: 'trade-reply',
          createdAt: 100,
        ),
      );
      thread.configureConversation(
        conversationTag: 'trade-reply',
        participants: [MockKeys.guest.publicKey, MockKeys.hoster.publicKey],
      );
      await _pump();

      final message = await thread.replyTextAndWait('  hello back  ');

      expect(message.id, 'awaited-message');
      expect(messaging.lastContent, 'hello back');
      expect(messaging.lastTags, [
        [kConversationTag, 'trade-reply'],
      ]);
      expect(messaging.lastRecipientPubkeys, [MockKeys.hoster.publicKey]);

      await thread.close();
    },
  );
}
