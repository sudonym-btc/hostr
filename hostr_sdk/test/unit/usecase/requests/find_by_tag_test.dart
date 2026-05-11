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
  final List<Filter> queryFilters = [];
  final List<bool> queryCacheReads = [];

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) async* {
    queryFilters.add(filter);
    queryCacheReads.add(cacheRead);
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
    bool setSinceOnLiveFilter = true,
  }) {
    throw UnimplementedError('Not needed for findByTag tests');
  }
}

// ── Helpers ─────────────────────────────────────────────────────────

Reservation _reservation({
  required String pubkey,
  required String tradeId,
  required String listingAnchor,
}) {
  return Reservation.create(
    pubKey: pubkey,
    dTag: tradeId,
    listingAnchor: listingAnchor,
    start: DateTime.utc(2026, 3, 1),
    end: DateTime.utc(2026, 3, 5),
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
        listingAnchor: '30402:host:listing-1',
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
        listingAnchor: '30402:host:listing-1',
      );
      fakeRequests.events.add(r1);

      final results = await useCase.findByTag('d', 'hash-z');
      expect(results, isEmpty);
    });

    test('returns multiple events for the same tag value', () async {
      final r1 = _reservation(
        pubkey: 'guest1',
        tradeId: 'hash-shared',
        listingAnchor: '30402:host:listing-1',
      );
      final r2 = _reservation(
        pubkey: 'host1',
        tradeId: 'hash-shared',
        listingAnchor: '30402:host:listing-1',
      );
      fakeRequests.events.addAll([r1, r2]);

      final results = await useCase.findByTag('d', 'hash-shared');
      expect(results, hasLength(2));
    });

    test('batches concurrent calls into a single query', () async {
      final r1 = _reservation(
        pubkey: 'pub1',
        tradeId: 'hash-a',
        listingAnchor: '30402:host:listing-1',
      );
      final r2 = _reservation(
        pubkey: 'pub2',
        tradeId: 'hash-b',
        listingAnchor: '30402:host:listing-1',
      );
      final r3 = _reservation(
        pubkey: 'pub3',
        tradeId: 'hash-c',
        listingAnchor: '30402:host:listing-1',
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
        listingAnchor: '30402:host:listing-1',
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

  group('CrudUseCase.getOne', () {
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

    test('coalesces identical concurrent calls onto one query', () async {
      final reservation = _reservation(
        pubkey: 'pub1',
        tradeId: 'hash-dup',
        listingAnchor: '30402:host:listing-1',
      );
      fakeRequests.events.add(reservation);

      final futures = [
        useCase.getOne(Filter(authors: ['pub1'], dTags: ['hash-dup'])),
        useCase.getOne(Filter(authors: ['pub1'], dTags: ['hash-dup'])),
        useCase.getOne(Filter(authors: ['pub1'], dTags: ['hash-dup'])),
      ];

      final results = await Future.wait(futures);

      expect(results.map((item) => item?.getDtag()), everyElement('hash-dup'));
      expect(fakeRequests.queryFilters, hasLength(1));
      expect(fakeRequests.queryFilters.single.authors, ['pub1']);
      expect(fakeRequests.queryFilters.single.dTags, ['hash-dup']);
    });

    test('deduplicates merged filter values in batched queries', () async {
      final first = _reservation(
        pubkey: 'pub1',
        tradeId: 'hash-a',
        listingAnchor: '30402:host:listing-1',
      );
      final second = _reservation(
        pubkey: 'pub1',
        tradeId: 'hash-b',
        listingAnchor: '30402:host:listing-1',
      );
      fakeRequests.events.addAll([first, second]);

      final results = await Future.wait([
        useCase.getOne(Filter(authors: ['pub1'], dTags: ['hash-a'])),
        useCase.getOne(Filter(authors: ['pub1'], dTags: ['hash-b'])),
      ]);

      expect(
        results.map((item) => item?.getDtag()),
        containsAll(['hash-a', 'hash-b']),
      );
      expect(fakeRequests.queryFilters, hasLength(1));
      final filter = fakeRequests.queryFilters.single;
      expect(filter.authors, ['pub1']);
      expect(filter.dTags, unorderedEquals(['hash-a', 'hash-b']));
    });

    test('cacheRead false bypasses batching and forwards to query', () async {
      final reservation = _reservation(
        pubkey: 'pub1',
        tradeId: 'hash-no-cache',
        listingAnchor: '30402:host:listing-1',
      );
      fakeRequests.events.add(reservation);

      final result = await useCase.getOne(
        Filter(authors: ['pub1'], dTags: ['hash-no-cache']),
        cacheRead: false,
      );

      expect(result?.getDtag(), 'hash-no-cache');
      expect(fakeRequests.queryFilters, hasLength(1));
      expect(fakeRequests.queryCacheReads, [isFalse]);
      expect(fakeRequests.queryFilters.single.limit, 1);
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
    bool cacheRead = true,
    bool cacheWrite = true,
  }) {
    return Stream<T>.error(StateError('query failed'));
  }
}
