import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/presentation/signer_request_popup_listener.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

void main() {
  group('signer request popup policy', () {
    test('does not show the full-page popup for heartbeat publications', () {
      final now = DateTime(2026, 1, 1, 12);
      final heartbeat = _request(
        id: 'heartbeat',
        kind: kNostrKindReceivedHeartbeat,
        createdAt: now.subtract(kSignerApprovalDelay * 2),
      );

      expect(shouldShowFullPageSignerRequest(heartbeat), isFalse);
      expect(
        visibleFullPageSignerRequest(
          requests: [heartbeat],
          dismissedRequestIds: const {},
          now: now,
        ),
        isNull,
      );
    });

    test('skips non-blocking publications and shows the next blocking one', () {
      final now = DateTime(2026, 1, 1, 12);
      final heartbeat = _request(
        id: 'heartbeat',
        kind: kNostrKindReceivedHeartbeat,
        createdAt: now.subtract(kSignerApprovalDelay * 2),
      );
      final reservation = _request(
        id: 'reservation',
        kind: kNostrKindReservation,
        createdAt: now.subtract(kSignerApprovalDelay * 2),
      );

      expect(
        visibleFullPageSignerRequest(
          requests: [heartbeat, reservation],
          dismissedRequestIds: const {},
          now: now,
        )?.id,
        'reservation',
      );
    });

    test('does not show blocking publications before the approval delay', () {
      final now = DateTime(2026, 1, 1, 12);
      final reservation = _request(
        id: 'reservation',
        kind: kNostrKindReservation,
        createdAt: now.subtract(const Duration(seconds: 4)),
      );

      expect(
        visibleFullPageSignerRequest(
          requests: [reservation],
          dismissedRequestIds: const {},
          now: now,
        ),
        isNull,
      );
    });

    test('describes non-blocking, blocking, and unknown event kinds', () {
      expect(
        signerRequestEventKindDescription(kNostrKindReceivedHeartbeat),
        'heartbeat',
      );
      expect(
        signerRequestEventKindDescription(kNostrKindReservation),
        'reservation update',
      );
      expect(
        signerRequestEventKindDescription(424242),
        'Nostr event kind 424242',
      );
    });
  });
}

PendingSignerRequest _request({
  required String id,
  required int kind,
  required DateTime createdAt,
}) {
  return PendingSignerRequest(
    id: id,
    method: SignerMethod.signEvent,
    createdAt: createdAt,
    signerPubkey: _pubkey,
    event: Nip01Event(
      pubKey: _pubkey,
      kind: kind,
      tags: const [],
      content: '',
      createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
    ),
  );
}

const _pubkey =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
