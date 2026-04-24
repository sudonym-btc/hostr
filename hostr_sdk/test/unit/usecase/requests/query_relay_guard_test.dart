@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/requests/requests.dart'
    show
        applyQueryRelayGuard,
        applyQueryRelayGuardForFilter,
        parseNostrEventsForSdk,
        requestInFlightKeyFor;
import 'package:models/main.dart' show ProfileMetadata;
import 'package:models/nostr_kinds.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:test/test.dart';

const _hostrRelay = 'wss://relay.hostr.test';
const _externalRelay = 'wss://relay.damus.io';

void main() {
  // ── applyQueryRelayGuard (single kind) ─────────────────────────────

  group('applyQueryRelayGuard', () {
    for (final kind in kHostrOnlyKinds) {
      test('kind $kind with no relays → hostr relay only', () {
        final result = applyQueryRelayGuard(
          eventKind: kind,
          hostrRelay: _hostrRelay,
          relays: null,
        );
        expect(result, equals([_hostrRelay]));
      });

      test('kind $kind with external relays → forced to hostr relay', () {
        final result = applyQueryRelayGuard(
          eventKind: kind,
          hostrRelay: _hostrRelay,
          relays: [_externalRelay, _hostrRelay],
        );
        expect(result, equals([_hostrRelay]));
      });

      test('kind $kind already on hostr relay → unchanged', () {
        final result = applyQueryRelayGuard(
          eventKind: kind,
          hostrRelay: _hostrRelay,
          relays: [_hostrRelay],
        );
        expect(result, equals([_hostrRelay]));
      });
    }

    for (final kind in [0, 1, 3, 7, 14, 9734, 9735, 24133]) {
      test('standard kind $kind → relays pass through', () {
        final relays = [_externalRelay, _hostrRelay];
        final result = applyQueryRelayGuard(
          eventKind: kind,
          hostrRelay: _hostrRelay,
          relays: relays,
        );
        expect(result, same(relays));
      });
    }

    test('standard kind with null relays → null pass through', () {
      final result = applyQueryRelayGuard(
        eventKind: 1,
        hostrRelay: _hostrRelay,
        relays: null,
      );
      expect(result, isNull);
    });
  });

  // ── applyQueryRelayGuardForFilter (multi-kind) ─────────────────────

  group('applyQueryRelayGuardForFilter', () {
    test('filter with only hostr kinds → forced to hostr relay', () {
      final filter = Filter(kinds: [kNostrKindListing, kNostrKindReservation]);
      final result = applyQueryRelayGuardForFilter(
        filter: filter,
        hostrRelay: _hostrRelay,
        relays: [_externalRelay],
      );
      expect(result, equals([_hostrRelay]));
    });

    test('filter with only standard kinds → relays pass through', () {
      final relays = [_externalRelay, _hostrRelay];
      final filter = Filter(kinds: [0, 1, 7]);
      final result = applyQueryRelayGuardForFilter(
        filter: filter,
        hostrRelay: _hostrRelay,
        relays: relays,
      );
      expect(result, same(relays));
    });

    test('filter with mixed kinds → forced to hostr relay', () {
      final filter = Filter(kinds: [0, kNostrKindListing]);
      final result = applyQueryRelayGuardForFilter(
        filter: filter,
        hostrRelay: _hostrRelay,
        relays: [_externalRelay],
      );
      expect(result, equals([_hostrRelay]));
    });

    test('filter with no kinds → relays pass through', () {
      final relays = [_externalRelay];
      final filter = Filter();
      final result = applyQueryRelayGuardForFilter(
        filter: filter,
        hostrRelay: _hostrRelay,
        relays: relays,
      );
      expect(result, same(relays));
    });

    test('filter with null relays and hostr kinds → forced to hostr relay', () {
      final filter = Filter(kinds: [kNostrKindListing]);
      final result = applyQueryRelayGuardForFilter(
        filter: filter,
        hostrRelay: _hostrRelay,
        relays: null,
      );
      expect(result, equals([_hostrRelay]));
    });

    test('filter already on hostr relay with hostr kinds → unchanged', () {
      final filter = Filter(kinds: [kNostrKindListing]);
      final relays = [_hostrRelay];
      final result = applyQueryRelayGuardForFilter(
        filter: filter,
        hostrRelay: _hostrRelay,
        relays: relays,
      );
      expect(result, same(relays));
    });
  });

  group('requestInFlightKeyFor', () {
    test('includes request behavior inputs', () {
      final filter = Filter(kinds: [1], authors: ['alice']);
      final base = requestInFlightKeyFor(filter: filter);

      expect(
        requestInFlightKeyFor(filter: filter, relays: [_externalRelay]),
        isNot(base),
      );
      expect(
        requestInFlightKeyFor(filter: filter, timeout: Duration(seconds: 2)),
        isNot(base),
      );
      expect(
        requestInFlightKeyFor(filter: filter, cacheRead: false),
        isNot(base),
      );
      expect(
        requestInFlightKeyFor(filter: filter, cacheWrite: false),
        isNot(base),
      );
    });

    test('keeps identical behavior inputs stable', () {
      final filter = Filter(kinds: [1], authors: ['alice']);

      expect(
        requestInFlightKeyFor(
          filter: filter,
          relays: [_externalRelay],
          timeout: Duration(seconds: 2),
          cacheRead: false,
          cacheWrite: false,
        ),
        requestInFlightKeyFor(
          filter: filter,
          relays: [_externalRelay],
          timeout: Duration(seconds: 2),
          cacheRead: false,
          cacheWrite: false,
        ),
      );
    });
  });

  group('parseNostrEventsForSdk', () {
    test('logs parse failures and continues with later events', () async {
      final badEvent = Nip01Event(
        pubKey: 'bad',
        kind: 1,
        tags: [],
        content: 'plain note',
        createdAt: 1,
      );
      final goodEvent = Nip01Event(
        pubKey: 'good',
        kind: 0,
        tags: [],
        content: '{}',
        createdAt: 2,
      );
      final failures = <({Nip01Event event, Object error})>[];

      final parsed = await parseNostrEventsForSdk<ProfileMetadata>(
        source: Stream.fromIterable([badEvent, goodEvent]),
        onParseError: (event, error, stackTrace) {
          failures.add((event: event, error: error));
        },
      ).toList();

      expect(parsed, hasLength(1));
      expect(parsed.single.pubKey, equals('good'));
      expect(failures, hasLength(1));
      expect(failures.single.event, same(badEvent));
      expect(failures.single.error, isA<TypeError>());
    });
  });
}
