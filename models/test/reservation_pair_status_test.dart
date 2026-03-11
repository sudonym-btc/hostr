import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

// ── Helpers ────────────────────────────────────────────────────────────

Reservation _reservation({
  KeyPair? signer,
  ReservationStage stage = ReservationStage.negotiate,
  DateTime? start,
  DateTime? end,
}) {
  final key = signer ?? MockKeys.hoster;
  return Reservation.create(
    pubKey: key.publicKey,
    dTag: 'test-reservation',
    listingAnchor: 'listing-anchor',
    start: start ?? DateTime.utc(2026, 2, 1),
    end: end ?? DateTime.utc(2026, 2, 5),
    stage: stage,
    createdAt: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
  ).signAs(key, Reservation.fromNostrEvent);
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  group('ReservationPairStatus', () {
    group('cancelled', () {
      test('returns false when both are null', () {
        final status = ReservationPair();
        expect(status.cancelled, isFalse);
      });

      test('returns false when both are negotiate stage', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.negotiate,
          ),
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.negotiate,
          ),
        );
        expect(status.cancelled, isFalse);
      });

      test('returns true when seller has cancel stage', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.cancel,
          ),
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.commit,
          ),
        );
        expect(status.cancelled, isTrue);
        expect(status.sellerCancelled, isTrue);
        expect(status.buyerCancelled, isFalse);
      });

      test('returns true when buyer has cancel stage', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.commit,
          ),
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.cancel,
          ),
        );
        expect(status.cancelled, isTrue);
        expect(status.sellerCancelled, isFalse);
        expect(status.buyerCancelled, isTrue);
      });

      test('returns true when cancelled flag is set (legacy)', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.cancel,
          ),
        );
        expect(status.cancelled, isTrue);
      });

      test('returns true when only seller is present and cancelled', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.cancel,
          ),
        );
        expect(status.cancelled, isTrue);
      });

      test('returns true when only buyer is present and cancelled', () {
        final status = ReservationPair(
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.cancel,
          ),
        );
        expect(status.cancelled, isTrue);
      });
    });

    group('stage', () {
      test('returns negotiate when both are null', () {
        final status = ReservationPair();
        expect(status.stage, ReservationStage.negotiate);
      });

      test('returns negotiate when both are negotiating', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.negotiate,
          ),
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.negotiate,
          ),
        );
        expect(status.stage, ReservationStage.negotiate);
      });

      test('returns commit when seller has committed', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.commit,
          ),
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.negotiate,
          ),
        );
        expect(status.stage, ReservationStage.commit);
      });

      test('returns commit when buyer has committed', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.negotiate,
          ),
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.commit,
          ),
        );
        expect(status.stage, ReservationStage.commit);
      });

      test('returns cancel when either cancelled (overrides commit)', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.cancel,
          ),
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.commit,
          ),
        );
        expect(status.stage, ReservationStage.cancel);
      });
    });

    group('start / end', () {
      test('returns null when no reservations', () {
        final status = ReservationPair();
        expect(status.start, isNull);
        expect(status.end, isNull);
      });

      test('returns dates from seller when only seller is present', () {
        final s = DateTime.utc(2026, 3, 1);
        final e = DateTime.utc(2026, 3, 5);
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            start: s,
            end: e,
          ),
        );
        expect(status.start, s);
        expect(status.end, e);
      });

      test('prefers committed reservation dates', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.commit,
            start: DateTime.utc(2026, 4, 1),
            end: DateTime.utc(2026, 4, 5),
          ),
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.negotiate,
            start: DateTime.utc(2026, 5, 1),
            end: DateTime.utc(2026, 5, 5),
          ),
        );
        expect(status.start, DateTime.utc(2026, 4, 1));
        expect(status.end, DateTime.utc(2026, 4, 5));
      });
    });

    group('isActive', () {
      test('false when no reservations', () {
        expect(ReservationPair().isActive, isFalse);
      });

      test('false when only negotiate (no commit)', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.negotiate,
          ),
        );
        expect(status.isActive, isFalse);
      });

      test('true when committed and not cancelled', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.commit,
          ),
        );
        expect(status.isActive, isTrue);
      });

      test('false when committed but cancelled', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.commit,
          ),
          buyerReservation: _reservation(
            signer: MockKeys.guest,
            stage: ReservationStage.cancel,
          ),
        );
        expect(status.isActive, isFalse);
      });
    });

    group('isCompleted', () {
      test('true when end date has passed and not cancelled', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            start: DateTime.utc(2020, 1, 1),
            end: DateTime.utc(2020, 1, 5),
          ),
        );
        expect(status.isCompleted, isTrue);
      });

      test('false when end date has not passed', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            start: DateTime.utc(2099, 1, 1),
            end: DateTime.utc(2099, 1, 5),
          ),
        );
        expect(status.isCompleted, isFalse);
      });

      test('false when cancelled even if end date has passed', () {
        final status = ReservationPair(
          sellerReservation: _reservation(
            signer: MockKeys.hoster,
            stage: ReservationStage.cancel,
            start: DateTime.utc(2020, 1, 1),
            end: DateTime.utc(2020, 1, 5),
          ),
        );
        expect(status.isCompleted, isFalse);
      });
    });
  });
}
