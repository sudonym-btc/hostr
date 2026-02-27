@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/datasources/nostr/mock.relay.dart' show matchEvent;
import 'package:hostr_sdk/usecase/crud.usecase.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:test/test.dart';

// ── Fake Requests that supports query with filter matching ──────────

class _FakeRequests extends Fake implements hostr_requests.Requests {
  final List<Nip01Event> events = [];

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
  }) async* {
    for (final event in events) {
      if (matchEvent(event, filter)) {
        yield event as T;
      }
    }
  }

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  }) {
    throw UnimplementedError('Not needed for findByTag tests');
  }
}

// ── Helpers ─────────────────────────────────────────────────────────

Reservation _reservation({
  required String pubkey,
  required String tradeId,
  required String listingAnchor,
  String? id,
}) {
  return Reservation(
    id: id,
    pubKey: pubkey,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    tags: ReservationTags([
      [kListingRefTag, listingAnchor],
      ['d', tradeId],
    ]),
    content: ReservationContent(
      start: DateTime.utc(2026, 3, 1),
      end: DateTime.utc(2026, 3, 5),
    ),
  );
}

void main() {
  group('CrudUseCase.findByTag', () {
    late _FakeRequests fakeRequests;
    late CrudUseCase<Reservation> useCase;

    setUp(() {
      fakeRequests = _FakeRequests();
      useCase = CrudUseCase<Reservation>(
        requests: fakeRequests,
        kind: Reservation.kinds[0],
        logger: CustomLogger(),
      );
    });

    test('returns matching events for a single value', () async {
      final r1 = _reservation(
        pubkey: 'pub1',
        tradeId: 'hash-a',
        listingAnchor: '32121:host:listing-1',
      );
      fakeRequests.events.add(r1);

      final results = await useCase.findByTag('d', 'hash-a');
      expect(results, hasLength(1));
      expect(results.first.getDtag(), 'hash-a');
    });

    test('returns empty list when no events match', () async {
      final r1 = _reservation(
        pubkey: 'pub1',
        tradeId: 'hash-a',
        listingAnchor: '32121:host:listing-1',
      );
      fakeRequests.events.add(r1);

      final results = await useCase.findByTag('d', 'hash-z');
      expect(results, isEmpty);
    });

    test('returns multiple events for the same tag value', () async {
      final r1 = _reservation(
        pubkey: 'guest1',
        tradeId: 'hash-shared',
        listingAnchor: '32121:host:listing-1',
      );
      final r2 = _reservation(
        pubkey: 'host1',
        tradeId: 'hash-shared',
        listingAnchor: '32121:host:listing-1',
      );
      fakeRequests.events.addAll([r1, r2]);

      final results = await useCase.findByTag('d', 'hash-shared');
      expect(results, hasLength(2));
    });

    test('batches concurrent calls into a single query', () async {
      final r1 = _reservation(
        pubkey: 'pub1',
        tradeId: 'hash-a',
        listingAnchor: '32121:host:listing-1',
      );
      final r2 = _reservation(
        pubkey: 'pub2',
        tradeId: 'hash-b',
        listingAnchor: '32121:host:listing-1',
      );
      final r3 = _reservation(
        pubkey: 'pub3',
        tradeId: 'hash-c',
        listingAnchor: '32121:host:listing-1',
      );
      fakeRequests.events.addAll([r1, r2, r3]);

      // Fire all three calls concurrently — they should batch.
      final futures = [
        useCase.findByTag('d', 'hash-a'),
        useCase.findByTag('d', 'hash-b'),
        useCase.findByTag('d', 'hash-c'),
      ];

      final results = await Future.wait(futures);
      expect(results[0], hasLength(1));
      expect(results[0].first.getDtag(), 'hash-a');
      expect(results[1], hasLength(1));
      expect(results[1].first.getDtag(), 'hash-b');
      expect(results[2], hasLength(1));
      expect(results[2].first.getDtag(), 'hash-c');
    });

    test('deduplicates identical values in the same batch', () async {
      final r1 = _reservation(
        pubkey: 'pub1',
        tradeId: 'hash-dup',
        listingAnchor: '32121:host:listing-1',
      );
      fakeRequests.events.add(r1);

      // Two callers ask for the same value.
      final futures = [
        useCase.findByTag('d', 'hash-dup'),
        useCase.findByTag('d', 'hash-dup'),
      ];

      final results = await Future.wait(futures);
      expect(results[0], hasLength(1));
      expect(results[1], hasLength(1));
      // Both should get the same result.
      expect(results[0].first.pubKey, results[1].first.pubKey);
    });

    test('propagates query errors to all requesters', () async {
      // Use a custom fake that throws on query.
      final errorRequests = _ErrorOnQueryRequests();
      final errorUseCase = CrudUseCase<Reservation>(
        requests: errorRequests,
        kind: Reservation.kinds[0],
        logger: CustomLogger(),
      );

      final futures = [
        errorUseCase.findByTag('d', 'hash-a'),
        errorUseCase.findByTag('d', 'hash-b'),
      ];

      expect(futures[0], throwsA(isA<StateError>()));
      expect(futures[1], throwsA(isA<StateError>()));
    });
  });
}

class _ErrorOnQueryRequests extends Fake implements hostr_requests.Requests {
  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
  }) {
    return Stream<T>.error(StateError('query failed'));
  }
}
