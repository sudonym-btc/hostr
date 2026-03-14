import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

void main() {
  group('Read receipt models', () {
    test('ReceivedHeartbeat creates and parses kind 10017 events', () {
      final heartbeat = ReceivedHeartbeat.create(
        pubKey: MockKeys.hoster.publicKey,
        createdAt: 1710000000,
      ).signAs(MockKeys.hoster, ReceivedHeartbeat.fromNostrEvent);

      final parsed = parser<ReceivedHeartbeat>(heartbeat);

      expect(parsed.kind, kNostrKindReceivedHeartbeat);
      expect(parsed.content, isEmpty);
      expect(parsed.receivedAt, DateTime.utc(2024, 3, 9, 16));
    });

    test('SeenStatus exposes counterparty and seen timestamp', () {
      final seenStatus = SeenStatus.create(
        pubKey: MockKeys.hoster.publicKey,
        counterpartyPubKey: MockKeys.guest.publicKey,
        seenUntil: 1710000123,
        createdAt: 1710000200,
      ).signAs(MockKeys.hoster, SeenStatus.fromNostrEvent);

      final parsed = parser<SeenStatus>(seenStatus);

      expect(parsed.kind, kNostrKindSeenStatus);
      expect(parsed.counterpartyPubKey, MockKeys.guest.publicKey);
      expect(parsed.seenUntil, 1710000123);
      expect(parsed.seenUntilAt, DateTime.utc(2024, 3, 9, 16, 2, 3));
      expect(parsed.content, isEmpty);
    });

    test('TypingIndicator exposes room and expiration', () {
      final typing = TypingIndicator.create(
        pubKey: MockKeys.hoster.publicKey,
        room: 'room-filter',
        expiration: 1710000900,
        createdAt: 1710000800,
      ).signAs(MockKeys.hoster, TypingIndicator.fromNostrEvent);

      final parsed = parser<TypingIndicator>(typing);

      expect(parsed.kind, kNostrKindTypingIndicator);
      expect(parsed.room, 'room-filter');
      expect(parsed.expiration, 1710000900);
      expect(parsed.isExpiredAt(DateTime.utc(2024, 3, 9, 16, 15)), isTrue);
      expect(parsed.isExpiredAt(DateTime.utc(2024, 3, 9, 16, 14, 59)), isFalse);
    });

    test('SeenMessages stores addressable bloom filter content', () {
      final seenMessages = SeenMessages.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'conversation-hash',
        bloomFilter: 'size:3:bits:salt',
        counterpartyPubKey: MockKeys.guest.publicKey,
        createdAt: 1710000300,
      ).signAs(MockKeys.hoster, SeenMessages.fromNostrEvent);

      final parsed = parser<SeenMessages>(seenMessages);

      expect(parsed.kind, kNostrKindSeenMessages);
      expect(parsed.getDtag(), 'conversation-hash');
      expect(parsed.conversationId, 'conversation-hash');
      expect(parsed.counterpartyPubKey, MockKeys.guest.publicKey);
      expect(parsed.bloomFilter, 'size:3:bits:salt');
    });
  });
}
