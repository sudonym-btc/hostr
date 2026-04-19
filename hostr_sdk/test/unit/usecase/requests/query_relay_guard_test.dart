@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/requests/requests.dart'
    show applyQueryRelayGuard, applyQueryRelayGuardForFilter;
import 'package:models/nostr_kinds.dart';
import 'package:ndk/ndk.dart' show Filter;
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
}
