@Tags(['unit'])
library;

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('message parser', () {
    test('parses plain kind 14 as TextMessage', () {
      final event = Nip01Event(
        pubKey: 'a' * 64,
        kind: kNostrKindDM,
        tags: const [
          ['p', 'b'],
        ],
        content: 'hello',
        createdAt: 123,
      );

      final parsed = parser(event);

      expect(parsed, isA<TextMessage>());
      expect(parsed, isA<Message>());
      expect((parsed as TextMessage).content, 'hello');
      expect(parsed.kind, kNostrKindDM);
    });

    test('parses JSON child message as JsonMessage', () {
      final child = ReceivedHeartbeat.create(pubKey: 'a' * 64, createdAt: 123);
      final event = Nip01Event(
        pubKey: 'a' * 64,
        kind: kNostrKindJsonMessage,
        tags: const [
          ['p', 'b'],
        ],
        content: child.toString(),
        createdAt: 124,
      );

      final parsed = parser(event);

      expect(parsed, isA<JsonMessage>());
      expect(parsed, isA<Message>());
      expect((parsed as JsonMessage).child, isA<ReceivedHeartbeat>());
      expect(parsed.kind, kNostrKindJsonMessage);
      expect(parsed.kind, lessThan(10000));
    });

    test('parses legacy kind 14 JSON child message as JsonMessage', () {
      final child = ReceivedHeartbeat.create(pubKey: 'a' * 64, createdAt: 123);
      final event = Nip01Event(
        pubKey: 'a' * 64,
        kind: kNostrKindDM,
        tags: const [
          ['p', 'b'],
        ],
        content: child.toString(),
        createdAt: 124,
      );

      final parsed = parser(event);

      expect(parsed, isA<JsonMessage>());
      expect((parsed as JsonMessage).child, isA<ReceivedHeartbeat>());
      expect(parsed.kind, kNostrKindDM);
    });

    test('parses reservation child message without generic cast failure', () {
      final child = Reservation.create(
        pubKey: 'a' * 64,
        dTag: 'trade-123',
        listingAnchor: '32121:${'b' * 64}:listing-1',
        recipient: 'c' * 64,
      );
      final event = Nip01Event(
        pubKey: 'a' * 64,
        kind: kNostrKindJsonMessage,
        tags: const [
          ['p', 'b'],
        ],
        content: child.toString(),
        createdAt: 124,
      );

      final parsed = parser<Nip01Event>(event);

      expect(parsed, isA<JsonMessage>());
      expect((parsed as JsonMessage).child, isA<Reservation>());
      expect((parsed.child as Reservation).getDtag(), 'trade-123');
    });
  });
}
