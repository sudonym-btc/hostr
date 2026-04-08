/// Tests for the [ReservationGroups] usecase — specifically the static
/// [ReservationGroups.verifyGroup] function and the
/// [Reservations.toReservationGroups] grouping.
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

import 'dart:convert';

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/reservation_groups/reservation_groups.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

final _f = EntityFactory();

// ═══════════════════════════════════════════════════════════════════════
//  Helpers
// ═══════════════════════════════════════════════════════════════════════

Listing _listing({KeyPair? signer, bool allowSelfSignedReservation = false}) {
  final key = signer ?? MockKeys.hoster;
  return _f.listing(
    signer: key,
    dTag: 'listing-${key.publicKey.substring(0, 8)}',
    title: 'Test Cottage',
    description: 'A lovely place',
    images: const ['https://picsum.photos/seed/1/800/600'],
    priceSats: 100000,
    location: 'test-location',
    type: ListingType.house,
    amenities: Amenities(),
    allowSelfSignedReservation: allowSelfSignedReservation,
    createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
  );
}

Future<Reservation> _negotiate({
  required Listing listing,
  required KeyPair buyer,
  String salt = 'test-salt',
}) => _f.reservation(
  listing: listing,
  dTag: 'trade-$salt',
  signerOverride: buyer,
  stage: ReservationStage.negotiate,
  start: DateTime(2026, 3, 1),
  end: DateTime(2026, 3, 5),
  quantity: 1,
  tweakMaterial: ReservationTweakMaterial(salt: salt, parity: false),
  createdAt: DateTime(2026, 1, 2).millisecondsSinceEpoch ~/ 1000,
);

Future<Reservation> _sellerAck({
  required Reservation negotiate,
  required Listing listing,
  required KeyPair seller,
}) => _f.reservation(
  listing: listing,
  dTag: negotiate.getDtag()!,
  signerOverride: seller,
  stage: ReservationStage.commit,
  start: negotiate.start,
  end: negotiate.end,
  pTags: [negotiate.pubKey],
  createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
);

Future<Reservation> _cancel({
  required Reservation source,
  required Listing listing,
  required KeyPair signer,
}) {
  // Derive the counterparty from the source event's participant set.
  // The counterparty is whichever pubkey in {source.pubKey, ...source.pTags}
  // is NOT the signer.
  final candidates = {source.pubKey, ...source.parsedTags.getTags('p')}
    ..remove(signer.publicKey);
  return _f.reservation(
    listing: listing,
    dTag: source.getDtag()!,
    signerOverride: signer,
    stage: ReservationStage.cancel,
    start: source.start,
    end: source.end,
    quantity: source.quantity,
    amount: source.amount,
    recipient: source.recipient,
    tweakMaterial: source.tweakMaterial,
    pTags: candidates.toList(),
    createdAt: DateTime(2026, 1, 4).millisecondsSinceEpoch ~/ 1000,
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  Extended helpers (extracted from integration test for pure-logic groups)
// ═══════════════════════════════════════════════════════════════════════

/// Extended listing builder with allowBarter / allowSelfSignedReservation.
Listing _buildListing({
  required KeyPair host,
  bool allowSelfSignedReservation = false,
  bool allowBarter = false,
  BigInt? pricePerNight,
}) => _f.listing(
  signer: host,
  dTag:
      'listing-${host.publicKey.substring(0, 8)}-${DateTime.now().microsecondsSinceEpoch}',
  title: 'Unit Test Cottage',
  description: 'A cosy place for unit testing.',
  images: const ['https://picsum.photos/seed/ut/800/600'],
  priceSats: (pricePerNight ?? BigInt.from(100000)).toInt(),
  location: 'test-location',
  type: ListingType.house,
  amenities: Amenities(),
  allowBarter: allowBarter,
  allowSelfSignedReservation: allowSelfSignedReservation,
  createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
);

/// Builds a signed profile event with optional `lud16`.
Nip01Event _buildProfileEvent({required KeyPair key, String? lud16}) {
  final meta = <String, dynamic>{
    'name': 'test-user-${key.publicKey.substring(0, 6)}',
    'lud16': ?lud16,
  };
  final unsigned = Nip01Event(
    pubKey: key.publicKey,
    kind: 0,
    tags: [],
    content: jsonEncode(meta),
    createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
  );
  return Nip01Utils.signWithPrivateKey(
    event: unsigned,
    privateKey: key.privateKey!,
  );
}

/// Creates a buyer negotiate-stage reservation with optional custom amount.
Future<Reservation> _buildNegotiate({
  required Listing listing,
  required KeyPair buyer,
  String salt = 'test-salt',
  BigInt? customAmount,
}) {
  final start = DateTime(2026, 3, 1);
  final end = DateTime(2026, 3, 5);
  return _f.reservation(
    listing: listing,
    dTag: 'trade-$salt',
    signerOverride: buyer,
    stage: ReservationStage.negotiate,
    start: start,
    end: end,
    quantity: 1,
    amount: customAmount != null
        ? DenominatedAmount(
            value: customAmount,
            denomination: 'BTC',
            decimals: 8,
          )
        : null,
    tweakMaterial: ReservationTweakMaterial(salt: salt, parity: false),
    createdAt: DateTime(2026, 1, 2).millisecondsSinceEpoch ~/ 1000,
  );
}

/// Creates a seller-ack (commit-stage) reservation.
Future<Reservation> _buildSellerAck({
  required Reservation negotiate,
  required Listing listing,
  required KeyPair seller,
}) => _f.reservation(
  listing: listing,
  dTag: negotiate.getDtag()!,
  signerOverride: seller,
  stage: ReservationStage.commit,
  start: negotiate.start,
  end: negotiate.end,
  pTags: [negotiate.pubKey],
  createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
);

/// Creates a buyer self-signed commit reservation with a [PaymentProof].
Future<Reservation> _buildSelfSignedCommit({
  required Reservation negotiate,
  required Listing listing,
  required KeyPair buyer,
  required PaymentProof proof,
}) => _f.reservation(
  listing: listing,
  dTag: negotiate.getDtag()!,
  signerOverride: buyer,
  stage: ReservationStage.commit,
  start: negotiate.start,
  end: negotiate.end,
  quantity: negotiate.quantity,
  amount: negotiate.amount,
  tweakMaterial: negotiate.tweakMaterial,
  proof: proof,
  pTags: [listing.pubKey],
  createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
);

/// Creates a cancel-stage reservation.
Future<Reservation> _buildCancel({
  required Reservation source,
  required Listing listing,
  required KeyPair signer,
}) {
  final candidates = {source.pubKey, ...source.parsedTags.getTags('p')}
    ..remove(signer.publicKey);
  return _f.reservation(
    listing: listing,
    dTag: source.getDtag()!,
    signerOverride: signer,
    stage: ReservationStage.cancel,
    start: source.start,
    end: source.end,
    quantity: source.quantity,
    amount: source.amount,
    recipient: source.recipient,
    tweakMaterial: source.tweakMaterial,
    pTags: candidates.toList(),
    createdAt: DateTime(2026, 1, 4).millisecondsSinceEpoch ~/ 1000,
  );
}

/// Builds a synthetic NIP-57 zap receipt event.
Nip01EventModel _buildZapReceiptEvent({
  required int amountSats,
  required String recipientPubKey,
  required String senderPubKey,
  required KeyPair signerKey,
  String? lnurl,
}) {
  final descriptionJson = jsonEncode({
    'pubkey': senderPubKey,
    'content': '',
    'kind': kNostrKindZapRequest,
    'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'tags': [
      ['p', recipientPubKey],
      ['amount', '${amountSats * 1000}'], // millisats
      if (lnurl != null) ['lnurl', lnurl],
    ],
  });

  final unsigned = Nip01Event(
    pubKey: senderPubKey,
    kind: kNostrKindZapReceipt,
    tags: [
      ['p', recipientPubKey],
      ['bolt11', 'lnbc${amountSats}n1fake'],
      ['description', descriptionJson],
    ],
    content: '',
    createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
  );
  final signed = Nip01Utils.signWithPrivateKey(
    event: unsigned,
    privateKey: signerKey.privateKey!,
  );
  return Nip01EventModel.fromEntity(signed);
}

/// Builds a [PaymentProof] containing a zap receipt.
PaymentProof _buildZapPaymentProof({
  required Listing listing,
  required Nip01Event hosterProfile,
  required int amountSats,
  required KeyPair signerKey,
  String? lnurl,
}) {
  final receipt = _buildZapReceiptEvent(
    amountSats: amountSats,
    recipientPubKey: listing.pubKey,
    senderPubKey: listing.pubKey,
    signerKey: signerKey,
    lnurl: lnurl,
  );

  return PaymentProof(
    hoster: hosterProfile,
    listing: listing,
    zapProof: ZapProof(receipt: receipt),
    escrowProof: null,
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════════════

void main() async {
  final listing = _listing();

  group('toReservationGroups', () {
    test('groups buyer and seller by trade id (d-tag)', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final ack = await _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pairs = Reservations.toReservationGroups(reservations: [nego, ack]);

      expect(pairs.length, 1);
      final pair = pairs.values.first;
      expect(pair.sellerReservation, isNotNull);
      expect(pair.buyerReservation, isNotNull);
      expect(pair.sellerReservation!.pubKey, listing.pubKey);
      expect(pair.buyerReservation!.pubKey, buyer.publicKey);
    });

    test('creates separate entries per trade id (d-tag)', () async {
      final buyer1 = MockKeys.guest;
      final buyer2 = MockKeys.reviewer;

      final nego1 = await _negotiate(
        listing: listing,
        buyer: buyer1,
        salt: 'a',
      );
      final nego2 = await _negotiate(
        listing: listing,
        buyer: buyer2,
        salt: 'b',
      );
      final ack1 = await _sellerAck(
        negotiate: nego1,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pairs = Reservations.toReservationGroups(
        reservations: [nego1, nego2, ack1],
      );

      expect(pairs.length, 2);
    });

    test('buyer-only pair has null seller', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);

      final pairs = Reservations.toReservationGroups(reservations: [nego]);

      expect(pairs.length, 1);
      final pair = pairs.values.first;
      expect(pair.sellerReservation, isNull);
      expect(pair.buyerReservation, isNotNull);
    });

    test('empty list produces empty map', () {
      final pairs = Reservations.toReservationGroups(reservations: []);

      expect(pairs, isEmpty);
    });
  });

  group('verifyGroup', () {
    test('seller-confirmed pair → Valid', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final ack = await _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pair = ReservationGroup(reservations: [ack, nego]);

      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Valid<ReservationGroup>>());
    });

    test('seller-only pair (blocked date) → Valid', () {
      final ack = Reservation.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'blocked-hash',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(MockKeys.hoster, Reservation.fromNostrEvent);

      final pair = ReservationGroup(reservations: [ack]);

      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Valid<ReservationGroup>>());
    });

    test('seller-only pair derives listing anchor and host pubkey', () {
      final ack = Reservation.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'blocked-anchor',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(MockKeys.hoster, Reservation.fromNostrEvent);

      final pair = ReservationGroup(reservations: [ack]);

      expect(pair.listingAnchor, listing.anchor);
      expect(pair.hostPubkey, listing.pubKey);
    });

    test('buyer-only negotiate (no proof) → Invalid', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);

      final pair = ReservationGroup(reservations: [nego]);

      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Invalid<ReservationGroup>>());
    });

    test('cancelled by seller → Valid with sellerCancelled flag', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final ack = await _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );
      final cancelled = await _cancel(
        source: ack,
        listing: listing,
        signer: MockKeys.hoster,
      );

      final pair = ReservationGroup(reservations: [cancelled, nego]);

      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Valid<ReservationGroup>>());
      expect((result as Valid).event.sellerCancelled, isTrue);
    });

    test('cancelled by buyer → Valid with buyerCancelled flag', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final cancelled = await _cancel(
        source: nego,
        listing: listing,
        signer: buyer,
      );

      final pair = ReservationGroup(reservations: [cancelled]);

      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Valid<ReservationGroup>>());
      expect((result as Valid).event.buyerCancelled, isTrue);
    });

    test('cancelled by both → Valid with both cancelled flags', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final sellerCancelled = await _cancel(
        source: nego,
        listing: listing,
        signer: MockKeys.hoster,
      );
      final buyerCancelled = await _cancel(
        source: nego,
        listing: listing,
        signer: buyer,
      );

      final pair = ReservationGroup(
        reservations: [sellerCancelled, buyerCancelled],
      );

      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Valid<ReservationGroup>>());
      expect((result as Valid).event.sellerCancelled, isTrue);
      expect((result as Valid).event.buyerCancelled, isTrue);
    });

    test('empty pair (both null) → Invalid', () {
      final pair = ReservationGroup();

      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Invalid<ReservationGroup>>());
      expect((result as Invalid).reason, contains('No reservation found'));
    });

    test('multiple pairs verify independently', () async {
      final buyer1 = MockKeys.guest;
      final buyer2 = MockKeys.reviewer;

      // Pair 1: seller-confirmed → Valid
      final nego1 = await _negotiate(
        listing: listing,
        buyer: buyer1,
        salt: 'a',
      );
      final ack1 = await _sellerAck(
        negotiate: nego1,
        listing: listing,
        seller: MockKeys.hoster,
      );

      // Pair 2: buyer cancelled → Valid but with cancelled flag
      final nego2 = await _negotiate(
        listing: listing,
        buyer: buyer2,
        salt: 'b',
      );
      final cancelled2 = await _cancel(
        source: nego2,
        listing: listing,
        signer: buyer2,
      );

      final pairs = Reservations.toReservationGroups(
        reservations: [nego1, ack1, nego2, cancelled2],
      );

      final results = pairs.values
          .map((pair) => ReservationGroups.verifyGroup(pair))
          .toList();

      final valid = results.whereType<Valid<ReservationGroup>>().length;
      final cancelledValid = results
          .whereType<Valid<ReservationGroup>>()
          .where((v) => v.event.cancelled)
          .length;

      expect(
        valid,
        2,
        reason: 'both pairs are Valid (cancelled is still Valid)',
      );
      expect(cancelledValid, 1, reason: 'one pair should carry cancelled flag');
    });

    test('valid count excludes cancelled pairs', () async {
      final buyer1 = MockKeys.guest;
      final buyer2 = MockKeys.reviewer;

      // Pair 1: seller-confirmed
      final nego1 = await _negotiate(
        listing: listing,
        buyer: buyer1,
        salt: 'a',
      );
      final ack1 = await _sellerAck(
        negotiate: nego1,
        listing: listing,
        seller: MockKeys.hoster,
      );

      // Pair 2: buyer cancelled
      final nego2 = await _negotiate(
        listing: listing,
        buyer: buyer2,
        salt: 'b',
      );
      final cancelled2 = await _cancel(
        source: nego2,
        listing: listing,
        signer: buyer2,
      );

      final pairs = Reservations.toReservationGroups(
        reservations: [nego1, ack1, cancelled2],
      );

      final results = pairs.values
          .map((pair) => ReservationGroups.verifyGroup(pair))
          .whereType<Valid<ReservationGroup>>();

      // All verified pairs are Valid; callers filter out cancelled ones.
      final activeCount = results.where((v) => !v.event.cancelled).length;
      expect(activeCount, 1);
    });

    // ── forceValidateSelfSigned ──────────────────────────────────────

    test('forceValidateSelfSigned=true: seller-confirmed pair with '
        'buyer without proof → Invalid', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final ack = await _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pair = ReservationGroup(reservations: [ack, nego]);

      // Default: seller confirmation makes it valid.
      final defaultResult = ReservationGroups.verifyGroup(pair);
      expect(defaultResult, isA<Valid<ReservationGroup>>());

      // Forced: buyer negotiate has no proof → Invalid.
      final forcedResult = ReservationGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: true,
      );
      expect(forcedResult, isA<Invalid<ReservationGroup>>());
    });

    test('forceValidateSelfSigned=true: seller-only pair (blocked date, '
        'no buyer) → Valid', () {
      final ack = Reservation.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'blocked-forced',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(MockKeys.hoster, Reservation.fromNostrEvent);

      final pair = ReservationGroup(reservations: [ack]);

      final result = ReservationGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: true,
      );
      expect(result, isA<Valid<ReservationGroup>>());
    });

    test('forceValidateSelfSigned=false: seller-confirmed pair with '
        'buyer without proof → Valid (default)', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final ack = await _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pair = ReservationGroup(reservations: [ack, nego]);

      final result = ReservationGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: false,
      );
      expect(result, isA<Valid<ReservationGroup>>());
    });

    test('forceValidateSelfSigned=true: cancelled pair still Valid', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final cancelled = await _cancel(
        source: nego,
        listing: listing,
        signer: buyer,
      );

      final pair = ReservationGroup(reservations: [cancelled]);

      final result = ReservationGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: true,
      );
      expect(result, isA<Valid<ReservationGroup>>());
      expect((result as Valid).event.buyerCancelled, isTrue);
    });

    test('forceValidateSelfSigned=true: empty pair (both null) → Invalid', () {
      final pair = ReservationGroup();

      final result = ReservationGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: true,
      );
      expect(result, isA<Invalid<ReservationGroup>>());
      expect((result as Invalid).reason, contains('No reservation found'));
    });
  });

  // ─── Group 4: Zap proof validation (extracted from integration test) ───

  group('verifyGroup — zap proof validation', () {
    final host = MockKeys.hoster;
    final buyer = MockKeys.guest;
    final lnurl = 'host@hostr.development';

    late Listing listing;
    late Nip01Event hosterProfile;

    setUp(() {
      listing = _buildListing(host: host, allowSelfSignedReservation: true);
      hosterProfile = _buildProfileEvent(key: host, lud16: lnurl);
    });

    test(
      'valid zap proof (sufficient amount, correct recipient) → Valid',
      () async {
        final nego = await _buildNegotiate(listing: listing, buyer: buyer);
        final expectedCost = listing
            .cost(start: nego.start, end: nego.end)
            .value
            .toInt();

        final proof = _buildZapPaymentProof(
          listing: listing,
          hosterProfile: hosterProfile,
          amountSats: expectedCost,
          signerKey: host,
          lnurl: lnurl,
        );

        final commit = await _buildSelfSignedCommit(
          negotiate: nego,
          listing: listing,
          buyer: buyer,
          proof: proof,
        );

        final pair = ReservationGroup(reservations: [commit]);
        final result = ReservationGroups.verifyGroup(pair);
        expect(result, isA<Valid<ReservationGroup>>());
      },
    );

    test('zap proof with overpayment → Valid', () async {
      final nego = await _buildNegotiate(listing: listing, buyer: buyer);
      final expectedCost = listing
          .cost(start: nego.start, end: nego.end)
          .value
          .toInt();

      final proof = _buildZapPaymentProof(
        listing: listing,
        hosterProfile: hosterProfile,
        amountSats: expectedCost * 2,
        signerKey: host,
        lnurl: lnurl,
      );

      final commit = await _buildSelfSignedCommit(
        negotiate: nego,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );

      final pair = ReservationGroup(reservations: [commit]);
      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Valid<ReservationGroup>>());
    });

    test('zap proof with insufficient amount → Invalid', () async {
      final nego = await _buildNegotiate(listing: listing, buyer: buyer);

      final proof = _buildZapPaymentProof(
        listing: listing,
        hosterProfile: hosterProfile,
        amountSats: 1,
        signerKey: host,
        lnurl: lnurl,
      );

      final commit = await _buildSelfSignedCommit(
        negotiate: nego,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );

      final pair = ReservationGroup(reservations: [commit]);
      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Invalid<ReservationGroup>>());
      expect((result as Invalid).reason, contains('Amount insufficient'));
    });

    test('zap proof with wrong recipient → Invalid', () async {
      final nego = await _buildNegotiate(listing: listing, buyer: buyer);
      final expectedCost = listing
          .cost(start: nego.start, end: nego.end)
          .value
          .toInt();

      final receipt = _buildZapReceiptEvent(
        amountSats: expectedCost,
        recipientPubKey: buyer.publicKey, // wrong — should be host
        senderPubKey: buyer.publicKey,
        signerKey: buyer,
        lnurl: lnurl,
      );

      final proof = PaymentProof(
        hoster: hosterProfile,
        listing: listing,
        zapProof: ZapProof(receipt: receipt),
        escrowProof: null,
      );

      final commit = await _buildSelfSignedCommit(
        negotiate: nego,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );

      final pair = ReservationGroup(reservations: [commit]);
      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Invalid<ReservationGroup>>());
      expect((result as Invalid).reason, contains('recipient does not match'));
    });

    test('zap proof with wrong hoster profile → Invalid', () async {
      final nego = await _buildNegotiate(listing: listing, buyer: buyer);
      final expectedCost = listing
          .cost(start: nego.start, end: nego.end)
          .value
          .toInt();

      final wrongHosterProfile = _buildProfileEvent(key: buyer, lud16: lnurl);

      final proof = _buildZapPaymentProof(
        listing: listing,
        hosterProfile: wrongHosterProfile,
        amountSats: expectedCost,
        signerKey: host,
        lnurl: lnurl,
      );

      final commit = await _buildSelfSignedCommit(
        negotiate: nego,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );

      final pair = ReservationGroup(reservations: [commit]);
      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Invalid<ReservationGroup>>());
      expect((result as Invalid).reason, contains('profile does not match'));
    });

    test('zap proof with wrong lnurl → Invalid', () async {
      final nego = await _buildNegotiate(listing: listing, buyer: buyer);
      final expectedCost = listing
          .cost(start: nego.start, end: nego.end)
          .value
          .toInt();

      final proof = _buildZapPaymentProof(
        listing: listing,
        hosterProfile: hosterProfile,
        amountSats: expectedCost,
        signerKey: host,
        lnurl: 'wrong@lnurl.example',
      );

      final commit = await _buildSelfSignedCommit(
        negotiate: nego,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );

      final pair = ReservationGroup(reservations: [commit]);
      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Invalid<ReservationGroup>>());
      expect((result as Invalid).reason, contains('LNURL does not match'));
    });

    test('no proof type (null zap + null escrow) → Invalid', () async {
      final nego = await _buildNegotiate(listing: listing, buyer: buyer);

      final proof = PaymentProof(
        hoster: hosterProfile,
        listing: listing,
        zapProof: null,
        escrowProof: null,
      );

      final commit = await _buildSelfSignedCommit(
        negotiate: nego,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );

      final pair = ReservationGroup(reservations: [commit]);
      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Invalid<ReservationGroup>>());
      expect(
        (result as Invalid).reason,
        contains('Unsupported or missing payment proof type'),
      );
    });
  });

  // ─── Group 5: allowSelfSignedReservation flag ──────────────────────────

  group('verifyGroup — allowSelfSignedReservation flag', () {
    final host = MockKeys.hoster;
    final buyer = MockKeys.guest;

    test(
      'self-signed commit with proof when allowSelfSigned=true → Valid',
      () async {
        final listing = _buildListing(
          host: host,
          allowSelfSignedReservation: true,
        );
        final hosterProfile = _buildProfileEvent(
          key: host,
          lud16: 'host@hostr.development',
        );
        final nego = await _buildNegotiate(listing: listing, buyer: buyer);
        final expectedCost = listing
            .cost(start: nego.start, end: nego.end)
            .value
            .toInt();

        final proof = _buildZapPaymentProof(
          listing: listing,
          hosterProfile: hosterProfile,
          amountSats: expectedCost,
          signerKey: host,
          lnurl: 'host@hostr.development',
        );

        final commit = await _buildSelfSignedCommit(
          negotiate: nego,
          listing: listing,
          buyer: buyer,
          proof: proof,
        );

        final pair = ReservationGroup(reservations: [commit]);
        final result = ReservationGroups.verifyGroup(pair);
        expect(result, isA<Valid<ReservationGroup>>());
      },
    );

    test(
      'self-signed commit WITHOUT proof when allowSelfSigned=false → Invalid',
      () async {
        final listing = _buildListing(
          host: host,
          allowSelfSignedReservation: false,
        );
        final nego = await _buildNegotiate(listing: listing, buyer: buyer);

        final pair = ReservationGroup(reservations: [nego]);
        final result = ReservationGroups.verifyGroup(pair);
        expect(result, isA<Invalid<ReservationGroup>>());
      },
    );

    test('self-signed commit WITH valid proof when allowSelfSigned=false '
        '→ still Valid (proof is sufficient)', () async {
      // NOTE: Current validation logic does NOT check
      // allowSelfSignedReservation — it only checks the payment proof.
      // This test documents that current behavior.
      final listing = _buildListing(
        host: host,
        allowSelfSignedReservation: false,
      );
      final hosterProfile = _buildProfileEvent(
        key: host,
        lud16: 'host@hostr.development',
      );
      final nego = await _buildNegotiate(listing: listing, buyer: buyer);
      final expectedCost = listing
          .cost(start: nego.start, end: nego.end)
          .value
          .toInt();

      final proof = _buildZapPaymentProof(
        listing: listing,
        hosterProfile: hosterProfile,
        amountSats: expectedCost,
        signerKey: host,
        lnurl: 'host@hostr.development',
      );

      final commit = await _buildSelfSignedCommit(
        negotiate: nego,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );

      final pair = ReservationGroup(reservations: [commit]);
      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Valid<ReservationGroup>>());
    });
  });

  // ─── Group 6: Barter validation ────────────────────────────────────────

  group('verifyGroup — barter scenarios', () {
    final host = MockKeys.hoster;
    final buyer = MockKeys.guest;

    test(
      'buyer offers lower price without seller ack → Invalid (no proof)',
      () async {
        final listing = _buildListing(host: host, allowBarter: true);
        final nego = await _buildNegotiate(
          listing: listing,
          buyer: buyer,
          customAmount: BigInt.from(50000),
        );

        final pair = ReservationGroup(reservations: [nego]);
        final result = ReservationGroups.verifyGroup(pair);
        expect(result, isA<Invalid<ReservationGroup>>());
      },
    );

    test('buyer offers lower price WITH seller ack → Valid', () async {
      final listing = _buildListing(host: host, allowBarter: true);
      final nego = await _buildNegotiate(
        listing: listing,
        buyer: buyer,
        customAmount: BigInt.from(50000),
      );

      final ack = await _buildSellerAck(
        negotiate: nego,
        listing: listing,
        seller: host,
      );

      final pair = ReservationGroup(reservations: [ack, nego]);

      final result = ReservationGroups.verifyGroup(pair);
      expect(result, isA<Valid<ReservationGroup>>());
    });

    test(
      'buyer offers listing price with zap proof (no barter) → Valid',
      () async {
        final listing = _buildListing(
          host: host,
          allowBarter: false,
          allowSelfSignedReservation: true,
        );
        final hosterProfile = _buildProfileEvent(
          key: host,
          lud16: 'host@hostr.development',
        );

        final nego = await _buildNegotiate(listing: listing, buyer: buyer);
        final expectedCost = listing
            .cost(start: nego.start, end: nego.end)
            .value
            .toInt();

        final proof = _buildZapPaymentProof(
          listing: listing,
          hosterProfile: hosterProfile,
          amountSats: expectedCost,
          signerKey: host,
          lnurl: 'host@hostr.development',
        );

        final commit = await _buildSelfSignedCommit(
          negotiate: nego,
          listing: listing,
          buyer: buyer,
          proof: proof,
        );

        final pair = ReservationGroup(reservations: [commit]);
        final result = ReservationGroups.verifyGroup(pair);
        expect(result, isA<Valid<ReservationGroup>>());
      },
    );
  });

  // ─── Group 7: Pipeline (toReservationGroups → verifyGroup) ───────────────

  group('toReservationGroups + verifyGroup pipeline (with proofs)', () {
    final host = MockKeys.hoster;
    final buyer = MockKeys.guest;
    final buyer2 = MockKeys.reviewer;

    late Listing listing;
    late Nip01Event hosterProfile;

    setUp(() {
      listing = _buildListing(host: host, allowSelfSignedReservation: true);
      hosterProfile = _buildProfileEvent(
        key: host,
        lud16: 'host@hostr.development',
      );
    });

    test('mixed reservations: valid, cancelled, and invalid pairs', () async {
      final nego1 = await _buildNegotiate(
        listing: listing,
        buyer: buyer,
        salt: 'pair-1',
      );
      final ack1 = await _buildSellerAck(
        negotiate: nego1,
        listing: listing,
        seller: host,
      );

      final nego2 = await _buildNegotiate(
        listing: listing,
        buyer: buyer2,
        salt: 'pair-2',
      );
      final cancelled2 = await _buildCancel(
        source: nego2,
        listing: listing,
        signer: buyer2,
      );

      final nego3 = await _buildNegotiate(
        listing: listing,
        buyer: buyer,
        salt: 'pair-3',
      );

      final pairs = Reservations.toReservationGroups(
        reservations: [nego1, ack1, nego2, cancelled2, nego3],
      );

      final results = pairs.values
          .map((pair) => ReservationGroups.verifyGroup(pair))
          .toList();

      final validCount = results.whereType<Valid<ReservationGroup>>().length;
      final invalidCount = results
          .whereType<Invalid<ReservationGroup>>()
          .length;

      expect(validCount, 2, reason: 'Seller-confirmed + cancelled are valid');
      expect(invalidCount, 1, reason: 'Only no-proof pair is invalid');
    });

    test(
      'valid zap-proof self-signed among mixed pairs → exactly 2 valid',
      () async {
        final nego1 = await _buildNegotiate(
          listing: listing,
          buyer: buyer,
          salt: 'mixed-1',
        );
        final ack1 = await _buildSellerAck(
          negotiate: nego1,
          listing: listing,
          seller: host,
        );

        final nego2 = await _buildNegotiate(
          listing: listing,
          buyer: buyer2,
          salt: 'mixed-2',
        );
        final expectedCost = listing
            .cost(start: nego2.start, end: nego2.end)
            .value
            .toInt();
        final proof = _buildZapPaymentProof(
          listing: listing,
          hosterProfile: hosterProfile,
          amountSats: expectedCost,
          signerKey: host,
          lnurl: 'host@hostr.development',
        );
        final commit2 = await _buildSelfSignedCommit(
          negotiate: nego2,
          listing: listing,
          buyer: buyer2,
          proof: proof,
        );

        final nego3 = await _buildNegotiate(
          listing: listing,
          buyer: buyer,
          salt: 'mixed-3',
        );

        final pairs = Reservations.toReservationGroups(
          reservations: [nego1, ack1, commit2, nego3],
        );

        final results = pairs.values
            .map((pair) => ReservationGroups.verifyGroup(pair))
            .toList();

        final validCount = results.whereType<Valid<ReservationGroup>>().length;

        expect(validCount, 2);
      },
    );

    test('cancelled pairs are excluded from active count', () async {
      final nego1 = await _buildNegotiate(
        listing: listing,
        buyer: buyer,
        salt: 'canc-1',
      );
      final ack1 = await _buildSellerAck(
        negotiate: nego1,
        listing: listing,
        seller: host,
      );

      final nego2 = await _buildNegotiate(
        listing: listing,
        buyer: buyer2,
        salt: 'canc-2',
      );
      final buyerCancelled = await _buildCancel(
        source: nego2,
        listing: listing,
        signer: buyer2,
      );

      final nego3 = await _buildNegotiate(
        listing: listing,
        buyer: buyer,
        salt: 'canc-3',
      );
      final ack3 = await _buildSellerAck(
        negotiate: nego3,
        listing: listing,
        seller: host,
      );
      final sellerCancelled = await _buildCancel(
        source: ack3,
        listing: listing,
        signer: host,
      );

      final pairs = Reservations.toReservationGroups(
        reservations: [
          nego1,
          ack1,
          nego2,
          buyerCancelled,
          nego3,
          sellerCancelled,
        ],
      );

      final results = pairs.values
          .map((pair) => ReservationGroups.verifyGroup(pair))
          .toList();

      final activeCount = results
          .whereType<Valid<ReservationGroup>>()
          .where((v) => !v.event.cancelled)
          .length;

      expect(
        activeCount,
        1,
        reason: 'Only pair 1 is active; pairs 2 & 3 are cancelled',
      );
    });
  });

  // ─── Group 8: Reservation.validate — direct ────────────────────────────

  group('Reservation.validate — direct', () {
    final host = MockKeys.hoster;
    final buyer = MockKeys.guest;

    late Listing listing;

    setUp(() {
      listing = _buildListing(host: host);
    });

    test('host-published reservation → always valid', () {
      final hostRes = Reservation.create(
        pubKey: host.publicKey,
        dTag: 'any-hash',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        stage: ReservationStage.commit,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(host, Reservation.fromNostrEvent);

      final result = Reservation.validate(hostRes);
      expect(result.isValid, isTrue);
      expect(result.fields['publisher']?.ok, isTrue);
    });

    test('buyer without proof → invalid', () async {
      final nego = await _buildNegotiate(listing: listing, buyer: buyer);

      final result = Reservation.validate(nego);
      expect(result.isValid, isFalse);
      expect(result.fields['proof']?.ok, isFalse);
    });
  });
}
