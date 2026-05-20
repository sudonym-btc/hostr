@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/requests/requests.dart'
    show applyBroadcastRelayGuard;
import 'package:models/nostr_kinds.dart';
import 'package:test/test.dart';

const _hostrRelay = 'wss://relay.hostr.test';
const _externalRelay = 'wss://relay.damus.io';

void main() {
  // ── Guard: hostr-only kinds ──────────────────────────────────────────

  group('applyBroadcastRelayGuard', () {
    for (final kind in kHostrOnlyKinds) {
      test('kind $kind with no explicit relays → hostr relay only', () {
        final result = applyBroadcastRelayGuard(
          eventKind: kind,
          hostrRelay: _hostrRelay,
          relays: null,
        );
        expect(result, equals([_hostrRelay]));
      });

      test(
        'kind $kind with external relays → stripped to hostr relay only',
        () {
          final result = applyBroadcastRelayGuard(
            eventKind: kind,
            hostrRelay: _hostrRelay,
            relays: [_externalRelay, _hostrRelay],
          );
          expect(result, equals([_hostrRelay]));
        },
      );

      test('kind $kind with only hostr relay → passes through unchanged', () {
        final input = [_hostrRelay];
        final result = applyBroadcastRelayGuard(
          eventKind: kind,
          hostrRelay: _hostrRelay,
          relays: input,
        );
        expect(result, same(input));
      });
    }

    // ── Standard kinds pass through ──────────────────────────────────

    const standardKinds = <int, String>{
      kNostrKindProfile: 'profile (kind 0)',
      kNostrKindReaction: 'reaction (kind 7)',
      kNostrKindGiftWrap: 'gift wrap (kind 1059)',
      kNostrKindZapRequest: 'zap request (kind 9734)',
      kNostrKindZapReceipt: 'zap receipt (kind 9735)',
      kNostrKindProfileBadges: 'profile badges (kind 10008)',
      kNostrKindReview: 'marketplace review (kind 31555)',
    };

    for (final entry in standardKinds.entries) {
      test('${entry.value} allows external relays', () {
        final input = [_externalRelay, _hostrRelay];
        final result = applyBroadcastRelayGuard(
          eventKind: entry.key,
          hostrRelay: _hostrRelay,
          relays: input,
        );
        expect(result, same(input));
      });
    }

    test('standard kind with null relays passes through as null', () {
      final result = applyBroadcastRelayGuard(
        eventKind: kNostrKindProfile,
        hostrRelay: _hostrRelay,
        relays: null,
      );
      expect(result, isNull);
    });
  });

  // ── Completeness: every hostr-specific kind is in the guard set ─────

  group('kHostrOnlyKinds completeness', () {
    const allHostrSpecificKinds = <int>{
      kNostrKindListing,
      kNostrKindOrder,
      kNostrKindOrderTransition,
      kNostrKindEscrowService,
      kNostrKindEscrowMethod,
      kNostrKindEscrowServiceSelected,
      kNostrKindJsonMessage,
      kNostrKindSeal,
      kNostrKindSeenStatus,
      kNostrKindReceivedHeartbeat,
      kNostrKindSeenMessages,
      kNostrKindBadgeAward,
      kNostrKindBadgeDefinition,
    };

    test('kHostrOnlyKinds contains every hostr-specific kind', () {
      final missing = allHostrSpecificKinds.difference(kHostrOnlyKinds);
      expect(
        missing,
        isEmpty,
        reason:
            'These kinds are hostr-specific but NOT in kHostrOnlyKinds — '
            'they would leak to external relays: $missing',
      );
    });

    test('kHostrOnlyKinds does not contain standard nostr kinds', () {
      const standardKinds = <int>{
        kNostrKindProfile, // 0
        kNostrKindReaction, // 7
        kNostrKindDM, // 14 — inner rumor, never broadcast directly
        kNostrKindZapRequest, // 9734
        kNostrKindZapReceipt, // 9735
        kNostrKindProfileBadges, // 10008
        kNostrKindReview, // 31555
        kNostrKindConnect, // 24133
      };

      final wronglyGuarded = kHostrOnlyKinds.intersection(standardKinds);
      expect(
        wronglyGuarded,
        isEmpty,
        reason:
            'These standard nostr kinds are in kHostrOnlyKinds — '
            'they would be blocked from external relays: $wronglyGuarded',
      );
    });
  });
}
