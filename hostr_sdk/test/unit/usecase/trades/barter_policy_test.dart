@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/trades/actions/reservation_request.dart';
import 'package:hostr_sdk/usecase/trades/actions/trade_action_resolver.dart';
import 'package:hostr_sdk/usecase/trades/trade.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

Listing _listing({int pricePerNightSats = 100000, bool allowBarter = true}) {
  return Listing.create(
    pubKey: MockKeys.hoster.publicKey,
    dTag: 'listing-barter-policy',
    title: 'Test Listing',
    description: 'Test Description',
    images: const [],
    price: [
      Price(
        amount: Amount(
          currency: Currency.BTC,
          value: BigInt.from(pricePerNightSats),
        ),
        frequency: Frequency.daily,
      ),
    ],
    location: 'test-location',
    type: ListingType.house,
    amenities: Amenities(),
    allowBarter: allowBarter,
  ).signAs(MockKeys.hoster, Listing.fromNostrEvent);
}

Reservation _request({
  required String pubKey,
  required int amountSats,
  required DateTime start,
  required DateTime end,
  int createdAt = 0,
}) {
  return Reservation.create(
    pubKey: pubKey,
    dTag: 'trade-1',
    listingAnchor: _listing().anchor!,
    start: start,
    end: end,
    stage: ReservationStage.negotiate,
    amount: Amount(currency: Currency.BTC, value: BigInt.from(amountSats)),
    createdAt: createdAt,
  );
}

void main() {
  group('ReservationRequestActions.resolve', () {
    final start = DateTime.utc(2026, 1, 1);
    final end = DateTime.utc(2026, 1, 2);
    final listing = _listing();
    final hostPubkey = MockKeys.hoster.publicKey;
    final guestPubkey = MockKeys.guest.publicKey;

    test('host gets accept and counter when guest sent latest offer', () {
      final actions = ReservationRequestActions.resolve(
        [
          _request(
            pubKey: guestPubkey,
            amountSats: 85000,
            start: start,
            end: end,
            createdAt: 1,
          ),
        ],
        listing,
        hostPubkey,
        TradeRole.host,
      );

      expect(actions, contains(TradeAction.accept));
      expect(actions, contains(TradeAction.counter));
    });

    test('host does not get accept when guest latest offer meets listing', () {
      final actions = ReservationRequestActions.resolve(
        [
          _request(
            pubKey: guestPubkey,
            amountSats: 100000,
            start: start,
            end: end,
            createdAt: 1,
          ),
        ],
        listing,
        hostPubkey,
        TradeRole.host,
      );

      expect(actions, isNot(contains(TradeAction.accept)));
    });
  });

  group('ReservationRequestActions.resolvePolicy', () {
    final start = DateTime.utc(2026, 1, 1);
    final end = DateTime.utc(2026, 1, 2);
    final listing = _listing();
    final hostPubkey = MockKeys.hoster.publicKey;
    final guestPubkey = MockKeys.guest.publicKey;

    test('guest can pay when host sent latest offer at listing price', () {
      final policy = ReservationRequestActions.resolvePolicy(
        [
          _request(
            pubKey: guestPubkey,
            amountSats: 90000,
            start: start,
            end: end,
            createdAt: 1,
          ),
          _request(
            pubKey: hostPubkey,
            amountSats: 100000,
            start: start,
            end: end,
            createdAt: 2,
          ),
        ],
        listing,
        guestPubkey,
        TradeRole.guest,
      );

      expect(
        policy.canPay,
        isTrue,
        reason:
            'latestByUs=${policy.latestOfferSentByUs} listing=${policy.listingPrice?.value} latest=${policy.latestOffer?.amount?.value}',
      );
      expect(policy.canCounter, isFalse);
    });

    test('guest can pay when latest host offer is below listing price', () {
      final policy = ReservationRequestActions.resolvePolicy(
        [
          _request(
            pubKey: guestPubkey,
            amountSats: 80000,
            start: start,
            end: end,
            createdAt: 1,
          ),
          _request(
            pubKey: hostPubkey,
            amountSats: 90000,
            start: start,
            end: end,
            createdAt: 2,
          ),
        ],
        listing,
        guestPubkey,
        TradeRole.guest,
      );

      expect(policy.canPay, isTrue);
      expect(policy.canCounter, isTrue);
      expect(policy.counterMin?.value, BigInt.from(90001));
      expect(policy.counterMax?.value, BigInt.from(100000));
    });

    test('guest cannot counter when host accepts their last offer', () {
      final policy = ReservationRequestActions.resolvePolicy(
        [
          _request(
            pubKey: guestPubkey,
            amountSats: 90000,
            start: start,
            end: end,
            createdAt: 1,
          ),
          _request(
            pubKey: hostPubkey,
            amountSats: 90000,
            start: start,
            end: end,
            createdAt: 2,
          ),
        ],
        listing,
        guestPubkey,
        TradeRole.guest,
      );

      expect(policy.canPay, isTrue);
      expect(policy.canCounter, isFalse);
      expect(policy.latestOfferAcceptsPrevious, isTrue);
    });

    test('host can counter only when guest sent latest offer', () {
      final canCounter = ReservationRequestActions.resolvePolicy(
        [
          _request(
            pubKey: guestPubkey,
            amountSats: 85000,
            start: start,
            end: end,
            createdAt: 1,
          ),
        ],
        listing,
        hostPubkey,
        TradeRole.host,
      );

      final cannotCounter = ReservationRequestActions.resolvePolicy(
        [
          _request(
            pubKey: guestPubkey,
            amountSats: 85000,
            start: start,
            end: end,
            createdAt: 1,
          ),
          _request(
            pubKey: hostPubkey,
            amountSats: 95000,
            start: start,
            end: end,
            createdAt: 2,
          ),
        ],
        listing,
        hostPubkey,
        TradeRole.host,
      );

      expect(canCounter.canCounter, isTrue);
      expect(canCounter.latestOfferAcceptsPrevious, isFalse);
      expect(canCounter.counterMin?.value, BigInt.from(85001));
      expect(canCounter.counterMax?.value, BigInt.from(100000));
      expect(cannotCounter.canCounter, isFalse);
    });

    test(
      'guest counter must be above their last offer and under host/list max',
      () {
        final policy = ReservationRequestActions.resolvePolicy(
          [
            _request(
              pubKey: guestPubkey,
              amountSats: 70000,
              start: start,
              end: end,
              createdAt: 1,
            ),
            _request(
              pubKey: hostPubkey,
              amountSats: 85000,
              start: start,
              end: end,
              createdAt: 2,
            ),
          ],
          listing,
          guestPubkey,
          TradeRole.guest,
        );

        expect(policy.canCounter, isTrue);
        expect(policy.counterMin?.value, BigInt.from(85001));
        expect(policy.counterMax?.value, BigInt.from(100000));
      },
    );

    test('guest can pay when their own latest offer meets listing price', () {
      final policy = ReservationRequestActions.resolvePolicy(
        [
          _request(
            pubKey: guestPubkey,
            amountSats: 100000,
            start: start,
            end: end,
            createdAt: 1,
          ),
        ],
        listing,
        guestPubkey,
        TradeRole.guest,
      );

      expect(policy.canPay, isTrue);
      expect(policy.canCounter, isFalse);
    });

    test('guest actions are only pay when host mirrors their latest offer', () {
      final actions = ReservationRequestActions.resolve(
        [
          _request(
            pubKey: guestPubkey,
            amountSats: 90000,
            start: start,
            end: end,
            createdAt: 1,
          ),
          _request(
            pubKey: hostPubkey,
            amountSats: 90000,
            start: start,
            end: end,
            createdAt: 2,
          ),
        ],
        listing,
        guestPubkey,
        TradeRole.guest,
      );

      expect(actions, [TradeAction.pay]);
    });
  });
}
