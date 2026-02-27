/// Tests for the [ReservationPairs] usecase — specifically the static
/// [ReservationPairs.verifyPair] function and the
/// [Reservations.toReservationPairs] grouping.
///
/// Covers:
/// - Seller-confirmed pair → Valid
/// - Buyer-only pair without proof → Invalid
/// - Cancelled by seller → Invalid
/// - Cancelled by buyer → Invalid
/// - Cancelled by both → Invalid
/// - Self-signed buyer with valid proof → Valid (deferred — proof validation
///   requires escrow proof setup not covered here)
/// - Empty pair → Invalid
/// - Multiple pairs from mixed reservations
@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/reservation_pairs/reservation_pairs.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/util/validation_stream.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

// ═══════════════════════════════════════════════════════════════════════
//  Helpers
// ═══════════════════════════════════════════════════════════════════════

Listing _listing({KeyPair? signer, bool allowSelfSignedReservation = false}) {
  final key = signer ?? MockKeys.hoster;
  return Listing(
    pubKey: key.publicKey,
    createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
    tags: EventTags([
      ['d', 'listing-${key.publicKey.substring(0, 8)}'],
    ]),
    content: ListingContent(
      title: 'Test Cottage',
      description: 'A lovely place',
      price: [
        Price(
          amount: Amount(currency: Currency.BTC, value: BigInt.from(100000)),
          frequency: Frequency.daily,
        ),
      ],
      allowBarter: false,
      allowSelfSignedReservation: allowSelfSignedReservation,
      minStay: const Duration(days: 1),
      checkIn: TimeOfDay(hour: 15, minute: 0),
      checkOut: TimeOfDay(hour: 11, minute: 0),
      location: 'test-location',
      quantity: 1,
      type: ListingType.house,
      images: ['https://picsum.photos/seed/1/800/600'],
      amenities: Amenities(),
      requiresEscrow: false,
    ),
  ).signAs(key, Listing.fromNostrEvent);
}

Reservation _negotiate({
  required Listing listing,
  required KeyPair buyer,
  String salt = 'test-salt',
}) {
  final s = DateTime(2026, 3, 1);
  final e = DateTime(2026, 3, 5);
  final nonce = 'trade-$salt';

  return Reservation(
    pubKey: buyer.publicKey,
    createdAt: DateTime(2026, 1, 2).millisecondsSinceEpoch ~/ 1000,
    tags: ReservationTags([
      [kListingRefTag, listing.anchor!],
      ['d', nonce],
    ]),
    content: ReservationContent(
      start: s,
      end: e,
      stage: ReservationStage.negotiate,
      quantity: 1,
      salt: salt,
    ),
  ).signAs(buyer, Reservation.fromNostrEvent);
}

Reservation _sellerAck({
  required Reservation negotiate,
  required Listing listing,
  required KeyPair seller,
}) {
  return Reservation(
    pubKey: seller.publicKey,
    createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
    tags: ReservationTags([
      [kListingRefTag, listing.anchor!],
      ['d', negotiate.getDtag()!],
    ]),
    content: ReservationContent(
      start: negotiate.parsedContent.start,
      end: negotiate.parsedContent.end,
      stage: ReservationStage.commit,
    ),
  ).signAs(seller, Reservation.fromNostrEvent);
}

Reservation _cancel({
  required Reservation source,
  required Listing listing,
  required KeyPair signer,
}) {
  return Reservation(
    pubKey: signer.publicKey,
    createdAt: DateTime(2026, 1, 4).millisecondsSinceEpoch ~/ 1000,
    tags: ReservationTags([
      [kListingRefTag, listing.anchor!],
      ['d', source.getDtag()!],
    ]),
    content: source.parsedContent.copyWith(
      stage: ReservationStage.cancel,
      cancelled: true,
    ),
  ).signAs(signer, Reservation.fromNostrEvent);
}

// ═══════════════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════════════

void main() {
  final listing = _listing();

  group('toReservationPairs', () {
    test('groups buyer and seller by trade id (d-tag)', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);
      final ack = _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pairs = Reservations.toReservationPairs(
        reservations: [nego, ack],
        listing: listing,
      );

      expect(pairs.length, 1);
      final pair = pairs.values.first;
      expect(pair.sellerReservation, isNotNull);
      expect(pair.buyerReservation, isNotNull);
      expect(pair.sellerReservation!.pubKey, listing.pubKey);
      expect(pair.buyerReservation!.pubKey, buyer.publicKey);
    });

    test('creates separate entries per trade id (d-tag)', () {
      final buyer1 = MockKeys.guest;
      final buyer2 = MockKeys.reviewer;

      final nego1 = _negotiate(listing: listing, buyer: buyer1, salt: 'a');
      final nego2 = _negotiate(listing: listing, buyer: buyer2, salt: 'b');
      final ack1 = _sellerAck(
        negotiate: nego1,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pairs = Reservations.toReservationPairs(
        reservations: [nego1, nego2, ack1],
        listing: listing,
      );

      expect(pairs.length, 2);
    });

    test('buyer-only pair has null seller', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);

      final pairs = Reservations.toReservationPairs(
        reservations: [nego],
        listing: listing,
      );

      expect(pairs.length, 1);
      final pair = pairs.values.first;
      expect(pair.sellerReservation, isNull);
      expect(pair.buyerReservation, isNotNull);
    });

    test('empty list produces empty map', () {
      final pairs = Reservations.toReservationPairs(
        reservations: [],
        listing: listing,
      );

      expect(pairs, isEmpty);
    });
  });

  group('verifyPair', () {
    test('seller-confirmed pair → Valid', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);
      final ack = _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pair = ReservationPairStatus(
        sellerReservation: ack,
        buyerReservation: nego,
      );

      final result = ReservationPairs.verifyPair(pair, listing);
      expect(result, isA<Valid<ReservationPairStatus>>());
    });

    test('seller-only pair (blocked date) → Valid', () {
      final ack = Reservation(
        pubKey: MockKeys.hoster.publicKey,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
        tags: ReservationTags([
          [kListingRefTag, listing.anchor!],
          ['d', 'blocked-hash'],
        ]),
        content: ReservationContent(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 5),
        ),
      ).signAs(MockKeys.hoster, Reservation.fromNostrEvent);

      final pair = ReservationPairStatus(sellerReservation: ack);

      final result = ReservationPairs.verifyPair(pair, listing);
      expect(result, isA<Valid<ReservationPairStatus>>());
    });

    test('buyer-only negotiate (no proof) → Invalid', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);

      final pair = ReservationPairStatus(buyerReservation: nego);

      final result = ReservationPairs.verifyPair(pair, listing);
      expect(result, isA<Invalid<ReservationPairStatus>>());
    });

    test('cancelled by seller → Invalid', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);
      final ack = _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );
      final cancelled = _cancel(
        source: ack,
        listing: listing,
        signer: MockKeys.hoster,
      );

      final pair = ReservationPairStatus(
        sellerReservation: cancelled,
        buyerReservation: nego,
      );

      final result = ReservationPairs.verifyPair(pair, listing);
      expect(result, isA<Invalid<ReservationPairStatus>>());
      expect((result as Invalid).reason, contains('seller'));
    });

    test('cancelled by buyer → Invalid', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);
      final cancelled = _cancel(source: nego, listing: listing, signer: buyer);

      final pair = ReservationPairStatus(buyerReservation: cancelled);

      final result = ReservationPairs.verifyPair(pair, listing);
      expect(result, isA<Invalid<ReservationPairStatus>>());
      expect((result as Invalid).reason, contains('buyer'));
    });

    test('cancelled by both → Invalid with "both parties"', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);
      final sellerCancelled = _cancel(
        source: nego,
        listing: listing,
        signer: MockKeys.hoster,
      );
      final buyerCancelled = _cancel(
        source: nego,
        listing: listing,
        signer: buyer,
      );

      final pair = ReservationPairStatus(
        sellerReservation: sellerCancelled,
        buyerReservation: buyerCancelled,
      );

      final result = ReservationPairs.verifyPair(pair, listing);
      expect(result, isA<Invalid<ReservationPairStatus>>());
      expect((result as Invalid).reason, contains('both parties'));
    });

    test('empty pair (both null) → Invalid', () {
      final pair = ReservationPairStatus();

      final result = ReservationPairs.verifyPair(pair, listing);
      expect(result, isA<Invalid<ReservationPairStatus>>());
      expect((result as Invalid).reason, contains('No reservation found'));
    });

    test('multiple pairs verify independently', () {
      final buyer1 = MockKeys.guest;
      final buyer2 = MockKeys.reviewer;

      // Pair 1: seller-confirmed → Valid
      final nego1 = _negotiate(listing: listing, buyer: buyer1, salt: 'a');
      final ack1 = _sellerAck(
        negotiate: nego1,
        listing: listing,
        seller: MockKeys.hoster,
      );

      // Pair 2: buyer cancelled → Invalid
      final nego2 = _negotiate(listing: listing, buyer: buyer2, salt: 'b');
      final cancelled2 = _cancel(
        source: nego2,
        listing: listing,
        signer: buyer2,
      );

      final pairs = Reservations.toReservationPairs(
        reservations: [nego1, ack1, nego2, cancelled2],
        listing: listing,
      );

      final results = pairs.values
          .map((pair) => ReservationPairs.verifyPair(pair, listing))
          .toList();

      final valid = results.whereType<Valid<ReservationPairStatus>>().length;
      final invalid = results
          .whereType<Invalid<ReservationPairStatus>>()
          .length;

      expect(valid, 1, reason: 'seller-confirmed pair should be valid');
      expect(invalid, 1, reason: 'cancelled pair should be invalid');
    });

    test('valid count excludes cancelled pairs', () {
      final buyer1 = MockKeys.guest;
      final buyer2 = MockKeys.reviewer;

      // Pair 1: seller-confirmed
      final nego1 = _negotiate(listing: listing, buyer: buyer1, salt: 'a');
      final ack1 = _sellerAck(
        negotiate: nego1,
        listing: listing,
        seller: MockKeys.hoster,
      );

      // Pair 2: buyer cancelled
      final nego2 = _negotiate(listing: listing, buyer: buyer2, salt: 'b');
      final cancelled2 = _cancel(
        source: nego2,
        listing: listing,
        signer: buyer2,
      );

      final pairs = Reservations.toReservationPairs(
        reservations: [nego1, ack1, cancelled2],
        listing: listing,
      );

      final validCount = pairs.values
          .map((pair) => ReservationPairs.verifyPair(pair, listing))
          .whereType<Valid<ReservationPairStatus>>()
          .length;

      expect(validCount, 1);
    });

    // ── forceValidateSelfSigned ──────────────────────────────────────

    test('forceValidateSelfSigned=true: seller-confirmed pair with '
        'buyer without proof → Invalid', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);
      final ack = _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pair = ReservationPairStatus(
        sellerReservation: ack,
        buyerReservation: nego,
      );

      // Default: seller confirmation makes it valid.
      final defaultResult = ReservationPairs.verifyPair(pair, listing);
      expect(defaultResult, isA<Valid<ReservationPairStatus>>());

      // Forced: buyer negotiate has no proof → Invalid.
      final forcedResult = ReservationPairs.verifyPair(
        pair,
        listing,
        forceValidateSelfSigned: true,
      );
      expect(forcedResult, isA<Invalid<ReservationPairStatus>>());
    });

    test('forceValidateSelfSigned=true: seller-only pair (blocked date, '
        'no buyer) → Valid', () {
      final ack = Reservation(
        pubKey: MockKeys.hoster.publicKey,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
        tags: ReservationTags([
          [kListingRefTag, listing.anchor!],
          ['d', 'blocked-forced'],
        ]),
        content: ReservationContent(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 5),
        ),
      ).signAs(MockKeys.hoster, Reservation.fromNostrEvent);

      final pair = ReservationPairStatus(sellerReservation: ack);

      final result = ReservationPairs.verifyPair(
        pair,
        listing,
        forceValidateSelfSigned: true,
      );
      expect(result, isA<Valid<ReservationPairStatus>>());
    });

    test('forceValidateSelfSigned=false: seller-confirmed pair with '
        'buyer without proof → Valid (default)', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);
      final ack = _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pair = ReservationPairStatus(
        sellerReservation: ack,
        buyerReservation: nego,
      );

      final result = ReservationPairs.verifyPair(
        pair,
        listing,
        forceValidateSelfSigned: false,
      );
      expect(result, isA<Valid<ReservationPairStatus>>());
    });

    test('forceValidateSelfSigned=true: cancelled pair still Invalid', () {
      final buyer = MockKeys.guest;
      final nego = _negotiate(listing: listing, buyer: buyer);
      final cancelled = _cancel(source: nego, listing: listing, signer: buyer);

      final pair = ReservationPairStatus(buyerReservation: cancelled);

      final result = ReservationPairs.verifyPair(
        pair,
        listing,
        forceValidateSelfSigned: true,
      );
      expect(result, isA<Invalid<ReservationPairStatus>>());
      expect((result as Invalid).reason, contains('buyer'));
    });

    test('forceValidateSelfSigned=true: empty pair (both null) → Invalid', () {
      final pair = ReservationPairStatus();

      final result = ReservationPairs.verifyPair(
        pair,
        listing,
        forceValidateSelfSigned: true,
      );
      expect(result, isA<Invalid<ReservationPairStatus>>());
      expect((result as Invalid).reason, contains('No reservation found'));
    });
  });
}
