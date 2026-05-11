@Tags(['unit'])
library;

import 'dart:convert';

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
        listingAnchor: '30402:${'b' * 64}:listing-1',
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

    test('rejects reservation events without listing anchors', () {
      final event = Nip01Event(
        pubKey: 'a' * 64,
        kind: kNostrKindReservation,
        tags: const [
          ['d', 'trade-123'],
        ],
        content: '{"stage":"negotiate","quantity":1}',
        createdAt: 124,
      );

      expect(
        () => parser<Reservation>(event),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('missing required tag "a"'),
          ),
        ),
      );
    });

    test('rejects every typed event with declared missing tags', () {
      final event = Nip01Event(
        pubKey: 'a' * 64,
        kind: kNostrKindEscrowServiceSelected,
        tags: const [],
        content: '{}',
        createdAt: 124,
      );

      expect(
        () => parser<Nip01Event>(event),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('missing required tag "d"'),
          ),
        ),
      );
    });

    test('rejects JSON child messages with malformed children', () {
      final child = Nip01Event(
        pubKey: 'a' * 64,
        kind: kNostrKindReservation,
        tags: const [
          ['d', 'trade-123'],
        ],
        content: '{"stage":"negotiate","quantity":1}',
        createdAt: 123,
      );
      final event = Nip01Event(
        pubKey: 'a' * 64,
        kind: kNostrKindJsonMessage,
        tags: const [
          ['p', 'b'],
        ],
        content: jsonEncode(Nip01EventModel.fromEntity(child).toJson()),
        createdAt: 124,
      );

      expect(
        () => parser<Nip01Event>(event),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('missing or invalid child event'),
          ),
        ),
      );
    });
  });
}
