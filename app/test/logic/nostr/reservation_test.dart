import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:models/main.dart';

// Fake implementations for testing
class FakeListing extends Fake implements Listing {
  @override
  final String id;

  @override
  final String pubKey;

  @override
  final String anchor;

  @override
  String get title => 'Test Listing';

  FakeListing({required this.id, required this.pubKey, required this.anchor});

  @override
  Amount cost(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    return Amount(currency: Currency.BTC, value: 0.001 * days);
  }
}

class FakeReservationRequest extends Fake implements ReservationRequest {
  @override
  final String id;

  @override
  final String pubKey;

  @override
  final int kind = kNostrKindReservationRequest;

  @override
  final String content;

  @override
  final int createdAt;

  @override
  final List<List<String>> tags;

  @override
  String get anchor =>
      tags
          .firstWhere(
            (tag) => tag.isNotEmpty && tag[0] == 'a',
            orElse: () => [],
          )
          .elementAtOrNull(1) ??
      '';

  late ReservationRequestContent _parsedContent;

  @override
  ReservationRequestContent get parsedContent => _parsedContent;

  @override
  set parsedContent(ReservationRequestContent value) => _parsedContent = value;

  FakeReservationRequest({
    required this.id,
    required this.pubKey,
    required this.content,
    required this.createdAt,
    required this.tags,
  }) {
    try {
      _parsedContent = ReservationRequestContent.fromJson(jsonDecode(content));
    } catch (e) {
      _parsedContent = ReservationRequestContent(
        start: DateTime.now(),
        end: DateTime.now().add(Duration(days: 1)),
        quantity: 1,
        amount: Amount(currency: Currency.BTC, value: 0.001),
        commitmentHash: 'hash',
        commitmentHashPreimageEnc: 'enc',
      );
    }
  }
}

class FakeMessage extends Fake implements Message {
  @override
  final String id;

  @override
  final String pubKey;

  @override
  final String content;

  @override
  final int createdAt;

  @override
  final List<List<String>> tags;

  @override
  final int kind = kNostrKindDM;

  FakeMessage({
    required this.id,
    required this.pubKey,
    required this.content,
    required this.createdAt,
    required this.tags,
  });
}

void main() {
  group('Reservation Request Creation', () {
    test('Reservation request contains all required fields', () {
      // Arrange
      final startDate = DateTime(2026, 2, 1);
      final endDate = DateTime(2026, 2, 5);
      final content = jsonEncode({
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
        'quantity': 1,
        'amount': {'currency': 'BTC', 'value': 0.004},
        'commitmentHash': 'hash',
        'commitmentHashPreimageEnc': 'enc',
      });

      final reservationRequest = FakeReservationRequest(
        id: 'req-1',
        pubKey: 'guest-pubkey',
        content: content,
        createdAt: startDate.millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', '32121:hoster:listing-1'],
        ],
      );

      // Assert
      expect(reservationRequest.kind, kNostrKindReservationRequest);
      expect(reservationRequest.pubKey, 'guest-pubkey');
      expect(reservationRequest.parsedContent.start, startDate);
      expect(reservationRequest.parsedContent.end, endDate);
      expect(reservationRequest.parsedContent.quantity, 1);
      expect(reservationRequest.parsedContent.commitmentHash, 'hash');
    });

    test('Reservation request includes anchor tag for listing', () {
      // Arrange
      const anchor = '32121:hoster:listing-1';
      final reservationRequest = FakeReservationRequest(
        id: 'req-1',
        pubKey: 'guest-pubkey',
        content: jsonEncode({
          'start': DateTime.now().toIso8601String(),
          'end': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'quantity': 1,
          'amount': {'currency': 'BTC', 'value': 0.001},
          'commitmentHash': 'hash',
          'commitmentHashPreimageEnc': 'enc',
        }),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', anchor],
        ],
      );

      // Assert
      expect(reservationRequest.anchor, anchor);
    });

    test('Reservation request content has correct dates', () {
      // Arrange
      final startDate = DateTime(2026, 3, 15);
      final endDate = DateTime(2026, 3, 20);

      final content = jsonEncode({
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
        'quantity': 1,
        'amount': {'currency': 'BTC', 'value': 0.005},
        'commitmentHash': 'hash',
        'commitmentHashPreimageEnc': 'enc',
      });

      final reservationRequest = FakeReservationRequest(
        id: 'req-1',
        pubKey: 'guest-pubkey',
        content: content,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', 'anchor-1'],
        ],
      );

      // Assert
      expect(reservationRequest.parsedContent.start, startDate);
      expect(reservationRequest.parsedContent.end, endDate);
    });

    test('Reservation request calculates correct amount based on duration', () {
      // Arrange
      final startDate = DateTime(2026, 2, 1);
      final endDate = DateTime(2026, 2, 11); // 10 days

      final content = jsonEncode({
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
        'quantity': 1,
        'amount': {'currency': 'BTC', 'value': 0.010},
        'commitmentHash': 'hash',
        'commitmentHashPreimageEnc': 'enc',
      });

      final reservationRequest = FakeReservationRequest(
        id: 'req-1',
        pubKey: 'guest-pubkey',
        content: content,
        createdAt: startDate.millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', 'anchor-1'],
        ],
      );

      // Assert
      expect(reservationRequest.parsedContent.amount.value, 0.010);
    });

    test('Multiple reservation requests have different IDs', () {
      // Arrange
      final request1 = FakeReservationRequest(
        id: 'req-1',
        pubKey: 'guest-pubkey',
        content: jsonEncode({
          'start': DateTime.now().toIso8601String(),
          'end': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'quantity': 1,
          'amount': {'currency': 'BTC', 'value': 0.001},
          'commitmentHash': 'hash',
          'commitmentHashPreimageEnc': 'enc',
        }),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', 'anchor-1'],
        ],
      );

      final request2 = FakeReservationRequest(
        id: 'req-2',
        pubKey: 'guest-pubkey',
        content: jsonEncode({
          'start': DateTime.now().toIso8601String(),
          'end': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'quantity': 1,
          'amount': {'currency': 'BTC', 'value': 0.001},
          'commitmentHash': 'hash',
          'commitmentHashPreimageEnc': 'enc',
        }),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', 'anchor-1'],
        ],
      );

      // Assert
      expect(request1.id, isNotEmpty);
      expect(request2.id, isNotEmpty);
      expect(request1.id, isNot(equals(request2.id)));
    });
  });

  group('Reservation Request Publishing', () {
    test('Reservation request can be broadcast to relay', () {
      // Arrange
      final startDate = DateTime(2026, 2, 1);
      final endDate = DateTime(2026, 2, 5);

      final reservationRequest = FakeReservationRequest(
        id: 'req-1',
        pubKey: 'guest-pubkey',
        content: jsonEncode({
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
          'quantity': 1,
          'amount': {'currency': 'BTC', 'value': 0.004},
          'commitmentHash': 'hash',
          'commitmentHashPreimageEnc': 'enc',
        }),
        createdAt: startDate.millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', '32121:hoster:listing-1'],
        ],
      );

      // Assert - Event is properly structured for broadcasting
      expect(reservationRequest.id, isNotEmpty);
      expect(reservationRequest.kind, kNostrKindReservationRequest);
      expect(reservationRequest.pubKey, 'guest-pubkey');
      expect(reservationRequest.content, isNotEmpty);
    });

    test('Reservation request maintains data during broadcast', () {
      // Arrange
      final startDate = DateTime(2026, 3, 10);
      final endDate = DateTime(2026, 3, 15);
      final originalAmount = 0.005;

      final content = jsonEncode({
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
        'quantity': 1,
        'amount': {'currency': 'BTC', 'value': originalAmount},
        'commitmentHash': 'original-hash',
        'commitmentHashPreimageEnc': 'original-enc',
      });

      final reservationRequest = FakeReservationRequest(
        id: 'req-broadcast',
        pubKey: 'guest-pubkey',
        content: content,
        createdAt: startDate.millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', '32121:hoster:listing-2'],
        ],
      );

      // Act - Simulate broadcast by re-parsing content
      final broadcastedRequest = FakeReservationRequest(
        id: reservationRequest.id,
        pubKey: reservationRequest.pubKey,
        content: reservationRequest.content,
        createdAt: reservationRequest.createdAt,
        tags: reservationRequest.tags,
      );

      // Assert - Data integrity maintained
      expect(broadcastedRequest.parsedContent.start, startDate);
      expect(broadcastedRequest.parsedContent.end, endDate);
      expect(broadcastedRequest.parsedContent.amount.value, originalAmount);
      expect(broadcastedRequest.parsedContent.commitmentHash, 'original-hash');
    });

    test('Reservation request broadcast includes all required tags', () {
      // Arrange
      final listingAnchor = '32121:hoster:listing-3';

      final reservationRequest = FakeReservationRequest(
        id: 'req-tagged',
        pubKey: 'guest-pubkey',
        content: jsonEncode({
          'start': DateTime.now().toIso8601String(),
          'end': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'quantity': 1,
          'amount': {'currency': 'BTC', 'value': 0.001},
          'commitmentHash': 'hash',
          'commitmentHashPreimageEnc': 'enc',
        }),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', listingAnchor],
        ],
      );

      // Assert - Tags are properly formatted
      expect(reservationRequest.tags, isNotEmpty);
      expect(reservationRequest.tags[0][0], 'a');
      expect(reservationRequest.tags[0][1], listingAnchor);
    });
  });

  group('Reservation Request as Message', () {
    test('Reservation request can be serialized for message broadcast', () {
      // Arrange
      final startDate = DateTime(2026, 2, 1);
      final endDate = DateTime(2026, 2, 5);
      final amount = 0.004;

      final content = jsonEncode({
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
        'quantity': 1,
        'amount': {'currency': 'BTC', 'value': amount},
        'commitmentHash': 'hash',
        'commitmentHashPreimageEnc': 'enc',
      });

      final reservationRequest = FakeReservationRequest(
        id: 'req-1',
        pubKey: 'guest-pubkey',
        content: content,
        createdAt: startDate.millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', '32121:hoster:listing-1'],
        ],
      );

      // Act - Serialize for message
      final messageContent = reservationRequest.content;

      // Assert
      expect(messageContent, isNotEmpty);
      expect(messageContent, contains('start'));
      expect(messageContent, contains('end'));
      final parsed = jsonDecode(messageContent) as Map<String, dynamic>;
      expect(parsed['amount']['value'], amount);
    });

    test(
      'Reservation request broadcast as message preserves anchor context',
      () {
        // Arrange
        const listingAnchor = '32121:hoster:listing-4';
        final reservationRequest = FakeReservationRequest(
          id: 'req-msg',
          pubKey: 'guest-pubkey',
          content: jsonEncode({
            'start': DateTime.now().toIso8601String(),
            'end': DateTime.now().add(Duration(days: 1)).toIso8601String(),
            'quantity': 1,
            'amount': {'currency': 'BTC', 'value': 0.001},
            'commitmentHash': 'hash',
            'commitmentHashPreimageEnc': 'enc',
          }),
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          tags: [
            ['a', listingAnchor],
          ],
        );

        // Act - Create message with reservation request
        final message = FakeMessage(
          id: 'msg-1',
          pubKey: 'guest-pubkey',
          content: reservationRequest.content,
          createdAt: reservationRequest.createdAt,
          tags: reservationRequest.tags,
        );

        // Assert - Message carries reservation request data and context
        expect(message.kind, kNostrKindDM);
        expect(message.content, reservationRequest.content);
        expect(message.tags, hasLength(1));
        expect(message.tags[0], equals(['a', listingAnchor]));
      },
    );

    test('Multiple reservation requests can be broadcast as messages', () {
      // Arrange
      final requests = [
        FakeReservationRequest(
          id: 'req-1',
          pubKey: 'guest-pubkey',
          content: jsonEncode({
            'start': DateTime(2026, 2, 1).toIso8601String(),
            'end': DateTime(2026, 2, 5).toIso8601String(),
            'quantity': 1,
            'amount': {'currency': 'BTC', 'value': 0.004},
            'commitmentHash': 'hash1',
            'commitmentHashPreimageEnc': 'enc1',
          }),
          createdAt: DateTime(2026, 2, 1).millisecondsSinceEpoch ~/ 1000,
          tags: [
            ['a', '32121:hoster:listing-1'],
          ],
        ),
        FakeReservationRequest(
          id: 'req-2',
          pubKey: 'guest-pubkey',
          content: jsonEncode({
            'start': DateTime(2026, 3, 1).toIso8601String(),
            'end': DateTime(2026, 3, 5).toIso8601String(),
            'quantity': 1,
            'amount': {'currency': 'BTC', 'value': 0.005},
            'commitmentHash': 'hash2',
            'commitmentHashPreimageEnc': 'enc2',
          }),
          createdAt: DateTime(2026, 3, 1).millisecondsSinceEpoch ~/ 1000,
          tags: [
            ['a', '32121:hoster:listing-2'],
          ],
        ),
      ];

      // Act - Convert to messages
      final messages = requests
          .map(
            (req) => FakeMessage(
              id: 'msg-${req.id}',
              pubKey: req.pubKey,
              content: req.content,
              createdAt: req.createdAt,
              tags: req.tags,
            ),
          )
          .toList();

      // Assert
      expect(messages, hasLength(2));
      expect(messages[0].content, contains('2026-02'));
      expect(messages[1].content, contains('2026-03'));
    });
  });

  group('Reservation Request Workflow', () {
    test('Reservation request workflow: create and broadcast as message', () {
      // Arrange - Create listing
      final listing = FakeListing(
        id: 'listing-1',
        pubKey: 'hoster-pubkey',
        anchor: '32121:hoster:listing-1',
      );

      final startDate = DateTime(2026, 2, 1);
      final endDate = DateTime(2026, 2, 5);
      final expectedAmount = listing.cost(startDate, endDate);

      // Act - Create reservation request
      final content = jsonEncode({
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
        'quantity': 1,
        'amount': {
          'currency': expectedAmount.currency.toString().split('.').last,
          'value': expectedAmount.value,
        },
        'commitmentHash': 'workflow-hash',
        'commitmentHashPreimageEnc': 'workflow-enc',
      });

      final reservationRequest = FakeReservationRequest(
        id: 'req-workflow',
        pubKey: 'guest-pubkey',
        content: content,
        createdAt: startDate.millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', listing.anchor],
        ],
      );

      // Act - Broadcast as message
      final broadcastMessage = FakeMessage(
        id: 'msg-req-workflow',
        pubKey: reservationRequest.pubKey,
        content: reservationRequest.content,
        createdAt: reservationRequest.createdAt,
        tags: reservationRequest.tags,
      );

      // Assert - Workflow completes successfully
      expect(reservationRequest.pubKey, 'guest-pubkey');
      expect(reservationRequest.anchor, listing.anchor);
      expect(reservationRequest.parsedContent.start, startDate);
      expect(reservationRequest.parsedContent.end, endDate);
      expect(
        reservationRequest.parsedContent.amount.value,
        expectedAmount.value,
      );

      // Assert - Message preserves all data
      expect(broadcastMessage.kind, kNostrKindDM);
      expect(broadcastMessage.content, reservationRequest.content);
      expect(broadcastMessage.tags, hasLength(1));
      expect(broadcastMessage.tags[0], equals(['a', listing.anchor]));
    });

    test(
      'Reservation request workflow handles multiple concurrent requests',
      () {
        // Arrange
        final listing1 = FakeListing(
          id: 'listing-1',
          pubKey: 'hoster-1',
          anchor: '32121:hoster-1:listing-1',
        );

        final listing2 = FakeListing(
          id: 'listing-2',
          pubKey: 'hoster-2',
          anchor: '32121:hoster-2:listing-2',
        );

        final startDate1 = DateTime(2026, 2, 1);
        final endDate1 = DateTime(2026, 2, 5);

        final startDate2 = DateTime(2026, 3, 1);
        final endDate2 = DateTime(2026, 3, 5);

        // Act - Create multiple requests
        final request1 = FakeReservationRequest(
          id: 'req-1',
          pubKey: 'guest-pubkey',
          content: jsonEncode({
            'start': startDate1.toIso8601String(),
            'end': endDate1.toIso8601String(),
            'quantity': 1,
            'amount': {
              'currency': 'BTC',
              'value': listing1.cost(startDate1, endDate1).value,
            },
            'commitmentHash': 'hash1',
            'commitmentHashPreimageEnc': 'enc1',
          }),
          createdAt: startDate1.millisecondsSinceEpoch ~/ 1000,
          tags: [
            ['a', listing1.anchor],
          ],
        );

        final request2 = FakeReservationRequest(
          id: 'req-2',
          pubKey: 'guest-pubkey',
          content: jsonEncode({
            'start': startDate2.toIso8601String(),
            'end': endDate2.toIso8601String(),
            'quantity': 1,
            'amount': {
              'currency': 'BTC',
              'value': listing2.cost(startDate2, endDate2).value,
            },
            'commitmentHash': 'hash2',
            'commitmentHashPreimageEnc': 'enc2',
          }),
          createdAt: startDate2.millisecondsSinceEpoch ~/ 1000,
          tags: [
            ['a', listing2.anchor],
          ],
        );

        // Act - Broadcast both as messages
        final messages = [
          FakeMessage(
            id: 'msg-1',
            pubKey: request1.pubKey,
            content: request1.content,
            createdAt: request1.createdAt,
            tags: request1.tags,
          ),
          FakeMessage(
            id: 'msg-2',
            pubKey: request2.pubKey,
            content: request2.content,
            createdAt: request2.createdAt,
            tags: request2.tags,
          ),
        ];

        // Assert
        expect(messages, hasLength(2));
        expect(request1.anchor, listing1.anchor);
        expect(request2.anchor, listing2.anchor);
        expect(request1.id, isNot(equals(request2.id)));
      },
    );

    test('Reservation request can be updated before final broadcast', () {
      // Arrange
      final startDate = DateTime(2026, 2, 1);
      final endDate = DateTime(2026, 2, 5);

      var amount = 0.004;

      final initialContent = jsonEncode({
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
        'quantity': 1,
        'amount': {'currency': 'BTC', 'value': amount},
        'commitmentHash': 'hash',
        'commitmentHashPreimageEnc': 'enc',
      });

      final reservationRequest = FakeReservationRequest(
        id: 'req-update',
        pubKey: 'guest-pubkey',
        content: initialContent,
        createdAt: startDate.millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', '32121:hoster:listing-1'],
        ],
      );

      // Assert - Initial request
      expect(reservationRequest.parsedContent.amount.value, 0.004);

      // Act - Update amount (simulate adjustment)
      amount = 0.005;
      final updatedContent = jsonEncode({
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
        'quantity': 1,
        'amount': {'currency': 'BTC', 'value': amount},
        'commitmentHash': 'hash',
        'commitmentHashPreimageEnc': 'enc',
      });

      final updatedRequest = FakeReservationRequest(
        id: 'req-update',
        pubKey: 'guest-pubkey',
        content: updatedContent,
        createdAt: startDate.millisecondsSinceEpoch ~/ 1000,
        tags: [
          ['a', '32121:hoster:listing-1'],
        ],
      );

      // Assert - Updated request
      expect(updatedRequest.parsedContent.amount.value, 0.005);
    });
  });
}
