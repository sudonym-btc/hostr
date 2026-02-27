import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

// ── Helpers ────────────────────────────────────────────────────────────

/// Build a [ReservationTransition] with the given transition parameters,
/// properly signed by [signer].
ReservationTransition _transition({
  required ReservationTransitionType type,
  required ReservationStage from,
  required ReservationStage to,
  KeyPair? signer,
  String? reason,
  Map<String, dynamic>? updatedFields,
}) {
  final key = signer ?? MockKeys.guest;

  final content = ReservationTransitionContent(
    transitionType: type,
    fromStage: from,
    toStage: to,
    reason: reason,
    updatedFields: updatedFields,
  );

  final unsigned = Nip01Event(
    kind: kNostrKindReservationTransition,
    pubKey: key.publicKey,
    tags: [
      ['d', 'trade-1'],
    ],
    content: content.toString(),
  );

  final signed = Nip01Utils.signWithPrivateKey(
    event: unsigned,
    privateKey: key.privateKey!,
  );

  return ReservationTransition.fromNostrEvent(signed);
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  group('validateStateTransitions', () {
    test('empty list is valid', () {
      final result = validateStateTransitions([]);
      expect(result.isValid, isTrue);
      expect(result.reason, isNull);
      expect(result.failedIndex, isNull);
    });

    // ── Single transitions ────────────────────────────────────────────

    group('single valid transition', () {
      test('negotiate → negotiate (counterOffer)', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.counterOffer,
            from: ReservationStage.negotiate,
            to: ReservationStage.negotiate,
          ),
        ]);
        expect(result.isValid, isTrue);
      });

      test('negotiate → commit (sellerAck)', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.sellerAck,
            from: ReservationStage.negotiate,
            to: ReservationStage.commit,
          ),
        ]);
        expect(result.isValid, isTrue);
      });

      test('negotiate → commit (commit)', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.commit,
            from: ReservationStage.negotiate,
            to: ReservationStage.commit,
          ),
        ]);
        expect(result.isValid, isTrue);
      });

      test('negotiate → cancel', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.cancel,
            from: ReservationStage.negotiate,
            to: ReservationStage.cancel,
          ),
        ]);
        expect(result.isValid, isTrue);
      });

      test('commit → cancel', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.cancel,
            from: ReservationStage.commit,
            to: ReservationStage.cancel,
          ),
        ]);
        expect(result.isValid, isTrue);
      });
    });

    // ── Invalid single transitions ────────────────────────────────────

    group('single invalid transition', () {
      test('commit → negotiate is illegal', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.counterOffer,
            from: ReservationStage.commit,
            to: ReservationStage.negotiate,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 0);
        expect(result.reason, contains('Illegal transition'));
      });

      test('cancel → negotiate is illegal', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.counterOffer,
            from: ReservationStage.cancel,
            to: ReservationStage.negotiate,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 0);
      });

      test('cancel → commit is illegal', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.commit,
            from: ReservationStage.cancel,
            to: ReservationStage.commit,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 0);
      });

      test('cancel → cancel is illegal', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.cancel,
            from: ReservationStage.cancel,
            to: ReservationStage.cancel,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 0);
      });

      test('commit → commit is illegal', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.commit,
            from: ReservationStage.commit,
            to: ReservationStage.commit,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 0);
      });
    });

    // ── Type / stage mismatch ─────────────────────────────────────────

    group('transition type does not match stages', () {
      test('counterOffer with negotiate → commit', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.counterOffer,
            from: ReservationStage.negotiate,
            to: ReservationStage.commit,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.reason, contains('does not match stages'));
      });

      test('sellerAck with negotiate → cancel', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.sellerAck,
            from: ReservationStage.negotiate,
            to: ReservationStage.cancel,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.reason, contains('does not match stages'));
      });

      test('commit type with commit → cancel', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.commit,
            from: ReservationStage.commit,
            to: ReservationStage.cancel,
          ),
        ]);
        // commit → cancel is a legal edge, but commit TYPE only allows
        // negotiate → commit.
        expect(result.isValid, isFalse);
        expect(result.reason, contains('does not match stages'));
      });
    });

    // ── Multi-step chains ─────────────────────────────────────────────

    group('valid chains', () {
      test('negotiate → negotiate → negotiate → commit', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.counterOffer,
            from: ReservationStage.negotiate,
            to: ReservationStage.negotiate,
          ),
          _transition(
            type: ReservationTransitionType.counterOffer,
            from: ReservationStage.negotiate,
            to: ReservationStage.negotiate,
          ),
          _transition(
            type: ReservationTransitionType.sellerAck,
            from: ReservationStage.negotiate,
            to: ReservationStage.commit,
          ),
        ]);
        expect(result.isValid, isTrue);
      });

      test('negotiate → commit → cancel', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.commit,
            from: ReservationStage.negotiate,
            to: ReservationStage.commit,
          ),
          _transition(
            type: ReservationTransitionType.cancel,
            from: ReservationStage.commit,
            to: ReservationStage.cancel,
          ),
        ]);
        expect(result.isValid, isTrue);
      });

      test('negotiate → cancel (direct)', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.cancel,
            from: ReservationStage.negotiate,
            to: ReservationStage.cancel,
          ),
        ]);
        expect(result.isValid, isTrue);
      });
    });

    group('invalid chains (chain break)', () {
      test('negotiate → commit then negotiate → commit (gap)', () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.commit,
            from: ReservationStage.negotiate,
            to: ReservationStage.commit,
          ),
          // After commit, fromStage should be commit, not negotiate.
          _transition(
            type: ReservationTransitionType.commit,
            from: ReservationStage.negotiate,
            to: ReservationStage.commit,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 1);
        expect(result.reason, contains('Chain break'));
      });

      test('negotiate → cancel then commit → cancel (continues after cancel)',
          () {
        final result = validateStateTransitions([
          _transition(
            type: ReservationTransitionType.cancel,
            from: ReservationStage.negotiate,
            to: ReservationStage.cancel,
          ),
          // cancel → cancel is illegal edge.
          _transition(
            type: ReservationTransitionType.cancel,
            from: ReservationStage.commit,
            to: ReservationStage.cancel,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 1);
      });
    });

    // ── toString ──────────────────────────────────────────────────────

    group('TransitionValidationResult toString', () {
      test('valid', () {
        const r = TransitionValidationResult.valid();
        expect(r.toString(), contains('valid'));
      });

      test('invalid', () {
        const r = TransitionValidationResult.invalid(
          reason: 'bad',
          failedIndex: 2,
        );
        expect(r.toString(), contains('invalid'));
        expect(r.toString(), contains('2'));
        expect(r.toString(), contains('bad'));
      });
    });
  });
}
