@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/messaging/thread.dart';
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeUserSubscriptions extends Fake implements UserSubscriptions {
  @override
  final StreamWithStatus<ReceivedHeartbeat> latestHeartbeats$ =
      StreamWithStatus<ReceivedHeartbeat>();

  Future<void> close() async {
    await latestHeartbeats$.close();
  }
}

class _RecordingMessaging extends Fake implements Messaging {
  int seenReceiptCount = 0;

  @override
  Future<void> broadcastSeenReceipt({
    required int seenUntil,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) async {
    seenReceiptCount++;
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
  required int createdAt,
}) {
  return Message(
    id: id,
    pubKey: sender,
    content: 'hello-$id',
    createdAt: createdAt,
    tags: MessageTags([
      for (final recipient in recipients) ['p', recipient],
      ['conversation', 'trade-1'],
    ]),
  );
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  late Thread thread;
  late _FakeAuth auth;
  late _RecordingMessaging messaging;
  late _FakeUserSubscriptions userSubscriptions;

  setUp(() {
    auth = _FakeAuth();
    messaging = _RecordingMessaging();
    userSubscriptions = _FakeUserSubscriptions();
    thread = Thread(
      'anchor-1',
      logger: CustomLogger(),
      auth: auth,
      messaging: messaging,
      userSubscriptions: userSubscriptions,
    );
    thread.configureConversation(
      conversationTag: 'trade-1',
      participants: [MockKeys.guest.publicKey, MockKeys.hoster.publicKey],
    );
    thread.addRoutingParticipants([
      MockKeys.guest.publicKey,
      MockKeys.hoster.publicKey,
    ]);
  });

  tearDown(() async {
    await thread.close();
    await userSubscriptions.close();
  });

  test(
    'does not request a seen receipt for historical backlog after arming',
    () async {
      thread.process(
        _textMessage(
          id: 'm-1',
          sender: MockKeys.hoster.publicKey,
          recipients: [MockKeys.guest.publicKey],
          createdAt: 100,
        ),
      );
      await _pump();

      expect(thread.state.value.unreadCount(MockKeys.guest.publicKey), 1);
      expect(thread.shouldSendReceiptNow, isTrue);

      thread.markHistoryAsReadLocally();

      expect(thread.state.value.unreadCount(MockKeys.guest.publicKey), 0);
      expect(thread.shouldSendReceiptNow, isFalse);
    },
  );

  test(
    'requests a seen receipt for new messages that arrive after arming',
    () async {
      thread.process(
        _textMessage(
          id: 'm-1',
          sender: MockKeys.hoster.publicKey,
          recipients: [MockKeys.guest.publicKey],
          createdAt: 100,
        ),
      );
      await _pump();
      thread.markHistoryAsReadLocally();

      thread.process(
        _textMessage(
          id: 'm-2',
          sender: MockKeys.hoster.publicKey,
          recipients: [MockKeys.guest.publicKey],
          createdAt: 101,
        ),
      );
      await _pump();

      expect(thread.state.value.unreadCount(MockKeys.guest.publicKey), 1);
      expect(thread.shouldSendReceiptNow, isTrue);
    },
  );

  test('does not broadcast seen receipts before hydration is armed', () async {
    thread.process(
      _textMessage(
        id: 'm-1',
        sender: MockKeys.hoster.publicKey,
        recipients: [MockKeys.guest.publicKey],
        createdAt: 100,
      ),
    );
    await _pump();

    thread.markAsRead();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(messaging.seenReceiptCount, 0);
  });

  test('broadcasts seen receipts after hydration is armed', () async {
    thread.process(
      _textMessage(
        id: 'm-1',
        sender: MockKeys.hoster.publicKey,
        recipients: [MockKeys.guest.publicKey],
        createdAt: 100,
      ),
    );
    await _pump();
    thread.armSeenReceiptsAfterHydration();

    thread.process(
      _textMessage(
        id: 'm-2',
        sender: MockKeys.hoster.publicKey,
        recipients: [MockKeys.guest.publicKey],
        createdAt: 101,
      ),
    );
    await _pump();

    thread.markAsRead();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(messaging.seenReceiptCount, 1);
  });
}
