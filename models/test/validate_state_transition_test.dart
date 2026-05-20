import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

// ── Helpers ────────────────────────────────────────────────────────────

/// Build a [OrderTransition] with the given transition parameters,
/// properly signed by [signer].
OrderTransition _transition({
  required OrderTransitionType type,
  required OrderStage from,
  required OrderStage to,
  KeyPair? signer,
  String? reason,
  Map<String, dynamic>? updatedFields,
  String? prevTransitionId,
}) {
  final key = signer ?? MockKeys.guest;

  final content = OrderTransitionContent(
    transitionType: type,
    fromStage: from,
    toStage: to,
    reason: reason,
    updatedFields: updatedFields,
  );

  final unsigned = Nip01Event(
    kind: kNostrKindOrderTransition,
    pubKey: key.publicKey,
    tags: [
      ['d', 'trade-1'],
      if (prevTransitionId != null) ['prev', prevTransitionId],
    ],
    content: content.toString(),
  );

  final signed = Nip01Utils.signWithPrivateKey(
    event: unsigned,
    privateKey: key.privateKey!,
  );

  return OrderTransition.fromNostrEvent(signed);
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
            type: OrderTransitionType.counterOffer,
            from: OrderStage.negotiate,
            to: OrderStage.negotiate,
          ),
        ]);
        expect(result.isValid, isTrue);
      });

      test('negotiate → commit (commit)', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.commit,
            from: OrderStage.negotiate,
            to: OrderStage.commit,
          ),
        ]);
        expect(result.isValid, isTrue);
      });

      test('negotiate → cancel', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.cancel,
            from: OrderStage.negotiate,
            to: OrderStage.cancel,
          ),
        ]);
        expect(result.isValid, isTrue);
      });

      test('commit → cancel', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.cancel,
            from: OrderStage.commit,
            to: OrderStage.cancel,
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
            type: OrderTransitionType.counterOffer,
            from: OrderStage.commit,
            to: OrderStage.negotiate,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 0);
        expect(result.reason, contains('Illegal transition'));
      });

      test('cancel → negotiate is illegal', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.counterOffer,
            from: OrderStage.cancel,
            to: OrderStage.negotiate,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 0);
      });

      test('cancel → commit is illegal', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.commit,
            from: OrderStage.cancel,
            to: OrderStage.commit,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 0);
      });

      test('cancel → cancel is illegal', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.cancel,
            from: OrderStage.cancel,
            to: OrderStage.cancel,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 0);
      });

      test('commit → commit is illegal', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.commit,
            from: OrderStage.commit,
            to: OrderStage.commit,
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
            type: OrderTransitionType.counterOffer,
            from: OrderStage.negotiate,
            to: OrderStage.commit,
          ),
        ]);
        expect(result.isValid, isFalse);
        expect(result.reason, contains('does not match stages'));
      });

      test('commit type with commit → cancel', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.commit,
            from: OrderStage.commit,
            to: OrderStage.cancel,
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
        final first = _transition(
          type: OrderTransitionType.counterOffer,
          from: OrderStage.negotiate,
          to: OrderStage.negotiate,
        );
        final second = _transition(
          type: OrderTransitionType.counterOffer,
          from: OrderStage.negotiate,
          to: OrderStage.negotiate,
          prevTransitionId: first.id,
        );
        final third = _transition(
          type: OrderTransitionType.commit,
          from: OrderStage.negotiate,
          to: OrderStage.commit,
          prevTransitionId: second.id,
        );
        final result = validateStateTransitions([
          third,
          first,
          second,
        ]);
        expect(result.isValid, isTrue);
      });

      test('negotiate → commit → cancel', () {
        final first = _transition(
          type: OrderTransitionType.commit,
          from: OrderStage.negotiate,
          to: OrderStage.commit,
        );
        final second = _transition(
          type: OrderTransitionType.cancel,
          from: OrderStage.commit,
          to: OrderStage.cancel,
          prevTransitionId: first.id,
        );
        final result = validateStateTransitions([
          second,
          first,
        ]);
        expect(result.isValid, isTrue);
      });

      test('negotiate → cancel (direct)', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.cancel,
            from: OrderStage.negotiate,
            to: OrderStage.cancel,
          ),
        ]);
        expect(result.isValid, isTrue);
      });
    });

    group('invalid chains (chain break)', () {
      test('negotiate → commit then negotiate → commit (gap)', () {
        final first = _transition(
          type: OrderTransitionType.commit,
          from: OrderStage.negotiate,
          to: OrderStage.commit,
        );
        final second = _transition(
          type: OrderTransitionType.commit,
          from: OrderStage.negotiate,
          to: OrderStage.commit,
          prevTransitionId: first.id,
        );
        final result = validateStateTransitions([
          first,
          // After commit, fromStage should be commit, not negotiate.
          second,
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 1);
        expect(result.reason, contains('Chain break'));
      });

      test('negotiate → cancel then commit → cancel (continues after cancel)',
          () {
        final first = _transition(
          type: OrderTransitionType.cancel,
          from: OrderStage.negotiate,
          to: OrderStage.cancel,
        );
        final second = _transition(
          type: OrderTransitionType.cancel,
          from: OrderStage.commit,
          to: OrderStage.cancel,
          prevTransitionId: first.id,
        );
        final result = validateStateTransitions([
          first,
          // cancel → cancel is illegal edge.
          second,
        ]);
        expect(result.isValid, isFalse);
        expect(result.failedIndex, 1);
      });

      test('multiple genesis transitions are invalid', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.commit,
            from: OrderStage.negotiate,
            to: OrderStage.commit,
          ),
          _transition(
            type: OrderTransitionType.cancel,
            from: OrderStage.commit,
            to: OrderStage.cancel,
          ),
        ]);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('Multiple genesis'));
      });

      test('missing previous transition is invalid', () {
        final result = validateStateTransitions([
          _transition(
            type: OrderTransitionType.cancel,
            from: OrderStage.commit,
            to: OrderStage.cancel,
            prevTransitionId: 'missing',
          ),
        ]);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('Missing previous transition'));
      });

      test('forked previous transition is invalid', () {
        final first = _transition(
          type: OrderTransitionType.counterOffer,
          from: OrderStage.negotiate,
          to: OrderStage.negotiate,
        );
        final second = _transition(
          type: OrderTransitionType.commit,
          from: OrderStage.negotiate,
          to: OrderStage.commit,
          prevTransitionId: first.id,
        );
        final fork = _transition(
          type: OrderTransitionType.cancel,
          from: OrderStage.negotiate,
          to: OrderStage.cancel,
          prevTransitionId: first.id,
        );

        final result = validateStateTransitions([first, second, fork]);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('fork'));
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

  group('validateEscrowStateTransitions', () {
    test('escrow may not cancel after commit', () {
      final first = _transition(
        type: OrderTransitionType.confirm,
        from: OrderStage.commit,
        to: OrderStage.commit,
        signer: MockKeys.escrow,
      );
      final second = _transition(
        type: OrderTransitionType.cancel,
        from: OrderStage.commit,
        to: OrderStage.cancel,
        signer: MockKeys.escrow,
        prevTransitionId: first.id,
      );

      final result = validateEscrowStateTransitions([second, first]);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('Escrow cannot cancel after commit'));
    });

    test('escrow may reject before commit', () {
      final result = validateEscrowStateTransitions([
        _transition(
          type: OrderTransitionType.cancel,
          from: OrderStage.negotiate,
          to: OrderStage.cancel,
          signer: MockKeys.escrow,
        ),
      ]);

      expect(result.isValid, isTrue);
    });
  });
}
