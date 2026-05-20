import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

// ── Helpers ────────────────────────────────────────────────────────────

/// Listing anchor that resolves to [MockKeys.hoster]'s pubkey via
/// [getPubKeyFromAnchor].
final _listingAnchor = '30402:${MockKeys.hoster.publicKey}:test-listing';

Order _order({
  KeyPair? signer,
  OrderStage stage = OrderStage.negotiate,
  DateTime? start,
  DateTime? end,
}) {
  final key = signer ?? MockKeys.hoster;
  return Order.create(
    pubKey: key.publicKey,
    dTag: 'test-order',
    listingAnchor: _listingAnchor,
    start: start ?? DateTime.utc(2026, 2, 1),
    end: end ?? DateTime.utc(2026, 2, 5),
    stage: stage,
    createdAt: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
  ).signAs(key, Order.fromNostrEvent);
}

OrderGroup _group({
  Order? sellerOrder,
  Order? buyerOrder,
}) {
  return OrderGroup(
    orders: [
      if (sellerOrder != null) sellerOrder,
      if (buyerOrder != null) buyerOrder,
    ],
  );
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  group('OrderGroupStatus', () {
    group('date range', () {
      test('falls back to first non-null dates when committed order is blank',
          () {
        final start = DateTime.utc(2026, 4, 27);
        final end = DateTime.utc(2026, 4, 28);
        final blankCommittedSeller = Order.create(
          pubKey: MockKeys.hoster.publicKey,
          dTag: 'test-order',
          listingAnchor: _listingAnchor,
          stage: OrderStage.commit,
        ).signAs(MockKeys.hoster, Order.fromNostrEvent);
        final datedBuyer = _order(
          signer: MockKeys.guest,
          stage: OrderStage.commit,
          start: start,
          end: end,
        );

        final status = OrderGroup(
          orders: [blankCommittedSeller, datedBuyer],
        );

        expect(status.start, start);
        expect(status.end, end);
      });
    });

    group('cancelled', () {
      test('returns false when empty', () {
        final status = OrderGroup();
        expect(status.cancelled, isFalse);
      });

      test('returns false when both are negotiate stage', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.negotiate,
          ),
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.negotiate,
          ),
        );
        expect(status.cancelled, isFalse);
      });

      test('returns true when seller has cancel stage', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.cancel,
          ),
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.commit,
          ),
        );
        expect(status.cancelled, isTrue);
        expect(status.sellerCancelled, isTrue);
        expect(status.buyerCancelled, isFalse);
      });

      test('returns true when buyer has cancel stage', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.commit,
          ),
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.cancel,
          ),
        );
        expect(status.cancelled, isTrue);
        expect(status.sellerCancelled, isFalse);
        expect(status.buyerCancelled, isTrue);
      });

      test('returns true when cancelled flag is set (legacy)', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.cancel,
          ),
        );
        expect(status.cancelled, isTrue);
      });

      test('returns true when only seller is present and cancelled', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.cancel,
          ),
        );
        expect(status.cancelled, isTrue);
      });

      test('returns true when only buyer is present and cancelled', () {
        final status = _group(
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.cancel,
          ),
        );
        expect(status.cancelled, isTrue);
      });
    });

    group('stage', () {
      test('returns negotiate when empty', () {
        final status = OrderGroup();
        expect(status.stage, OrderStage.negotiate);
      });

      test('returns negotiate when both are negotiating', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.negotiate,
          ),
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.negotiate,
          ),
        );
        expect(status.stage, OrderStage.negotiate);
      });

      test('returns commit when seller has committed', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.commit,
          ),
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.negotiate,
          ),
        );
        expect(status.stage, OrderStage.commit);
      });

      test('returns commit when buyer has committed', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.negotiate,
          ),
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.commit,
          ),
        );
        expect(status.stage, OrderStage.commit);
      });

      test('returns cancel when either cancelled (overrides commit)', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.cancel,
          ),
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.commit,
          ),
        );
        expect(status.stage, OrderStage.cancel);
      });
    });

    group('start / end', () {
      test('returns null when no orders', () {
        final status = OrderGroup();
        expect(status.start, isNull);
        expect(status.end, isNull);
      });

      test('returns dates from seller when only seller is present', () {
        final s = DateTime.utc(2026, 3, 1);
        final e = DateTime.utc(2026, 3, 5);
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            start: s,
            end: e,
          ),
        );
        expect(status.start, s);
        expect(status.end, e);
      });

      test('prefers committed order dates', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.commit,
            start: DateTime.utc(2026, 4, 1),
            end: DateTime.utc(2026, 4, 5),
          ),
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.negotiate,
            start: DateTime.utc(2026, 5, 1),
            end: DateTime.utc(2026, 5, 5),
          ),
        );
        expect(status.start, DateTime.utc(2026, 4, 1));
        expect(status.end, DateTime.utc(2026, 4, 5));
      });
    });

    group('isActive', () {
      test('false when no orders', () {
        expect(OrderGroup().isActive, isFalse);
      });

      test('false when only negotiate (no commit)', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.negotiate,
          ),
        );
        expect(status.isActive, isFalse);
      });

      test('true when committed and not cancelled', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.commit,
          ),
        );
        expect(status.isActive, isTrue);
      });

      test('false when committed but cancelled', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.commit,
          ),
          buyerOrder: _order(
            signer: MockKeys.guest,
            stage: OrderStage.cancel,
          ),
        );
        expect(status.isActive, isFalse);
      });
    });

    group('isCompleted', () {
      test('true when end date has passed and not cancelled', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            start: DateTime.utc(2020, 1, 1),
            end: DateTime.utc(2020, 1, 5),
          ),
        );
        expect(status.isCompleted, isTrue);
      });

      test('false when end date has not passed', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            start: DateTime.utc(2099, 1, 1),
            end: DateTime.utc(2099, 1, 5),
          ),
        );
        expect(status.isCompleted, isFalse);
      });

      test('false when cancelled even if end date has passed', () {
        final status = _group(
          sellerOrder: _order(
            signer: MockKeys.hoster,
            stage: OrderStage.cancel,
            start: DateTime.utc(2020, 1, 1),
            end: DateTime.utc(2020, 1, 5),
          ),
        );
        expect(status.isCompleted, isFalse);
      });
    });
  });
}
