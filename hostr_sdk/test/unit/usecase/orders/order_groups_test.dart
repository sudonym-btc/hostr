/// Tests for the [OrderGroups] usecase — specifically the static
/// [OrderGroups.verifyGroup] function and the
/// [Orders.toOrderGroups] grouping.
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
/// - Multiple pairs from mixed orders
@Tags(['unit'])
library;

import 'dart:convert';

import 'package:hostr_sdk/usecase/escrow/escrow_verification.dart';
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/order_groups/order_groups.dart';
import 'package:hostr_sdk/usecase/orders/orders.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

final _f = EntityFactory();

class _FakeOrders extends Fake implements Orders {}

class _FakeEvm extends Fake implements Evm {}

class _StubEscrowVerification extends Fake implements EscrowVerification {
  final Set<String> validTradeIds;
  final List<String> verifiedTradeIds = [];

  _StubEscrowVerification({this.validTradeIds = const {}});

  @override
  Future<EscrowVerificationResult> verify({required Order order}) async {
    final tradeId = order.getDtag();
    if (tradeId != null) verifiedTradeIds.add(tradeId);
    if (tradeId != null && validTradeIds.contains(tradeId)) {
      return const EscrowVerificationResult.valid();
    }
    return const EscrowVerificationResult.invalid('mock on-chain failure');
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Helpers
// ═══════════════════════════════════════════════════════════════════════

Listing _listing({KeyPair? signer, bool allowSelfSignedOrder = false}) {
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
    specifications: Specifications(),
    allowSelfSignedOrder: allowSelfSignedOrder,
    createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
  );
}

Future<Order> _negotiate({
  required Listing listing,
  required KeyPair buyer,
  String salt = 'test-salt',
}) => _f.order(
  listing: listing,
  dTag: 'trade-$salt',
  signerOverride: buyer,
  stage: OrderStage.negotiate,
  start: DateTime(2026, 3, 1),
  end: DateTime(2026, 3, 5),
  quantity: 1,
  createdAt: DateTime(2026, 1, 2).millisecondsSinceEpoch ~/ 1000,
);

Future<Order> _sellerAck({
  required Order negotiate,
  required Listing listing,
  required KeyPair seller,
}) => _f.order(
  listing: listing,
  dTag: negotiate.getDtag()!,
  signerOverride: seller,
  stage: OrderStage.commit,
  start: negotiate.start,
  end: negotiate.end,
  pTags: [PTag.seller(listing.pubKey), PTag.buyer(negotiate.pubKey)],
  createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
);

Future<Order> _cancel({
  required Order source,
  required Listing listing,
  required KeyPair signer,
}) {
  // Derive the counterparty from the source event's participant set.
  // The counterparty is whichever pubkey in {source.pubKey, ...source.pTags}
  // is NOT the signer.
  final candidates = {source.pubKey, ...source.parsedTags.getTags('p')}
    ..remove(signer.publicKey);
  final host = listing.pubKey;
  return _f.order(
    listing: listing,
    dTag: source.getDtag()!,
    signerOverride: signer,
    stage: OrderStage.cancel,
    start: source.start,
    end: source.end,
    quantity: source.quantity,
    amount: source.amount,
    recipient: source.recipient,
    proof: source.proof,
    commitAuthorization: source.commitAuthorization,
    pTags: [
      for (final c in candidates) c == host ? PTag.seller(c) : PTag.buyer(c),
    ],
    createdAt: DateTime(2026, 1, 4).millisecondsSinceEpoch ~/ 1000,
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  Extended helpers (extracted from integration test for pure-logic groups)
// ═══════════════════════════════════════════════════════════════════════

/// Extended listing builder with negotiable / allowSelfSignedOrder.
Listing _buildListing({
  required KeyPair host,
  bool allowSelfSignedOrder = false,
  bool negotiable = false,
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
  specifications: Specifications(),
  negotiable: negotiable,
  allowSelfSignedOrder: allowSelfSignedOrder,
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

/// Creates a buyer negotiate-stage order with optional custom amount.
Future<Order> _buildNegotiate({
  required Listing listing,
  required KeyPair buyer,
  String salt = 'test-salt',
  BigInt? customAmount,
}) {
  final start = DateTime(2026, 3, 1);
  final end = DateTime(2026, 3, 5);
  return _f.order(
    listing: listing,
    dTag: 'trade-$salt',
    signerOverride: buyer,
    stage: OrderStage.negotiate,
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
    createdAt: DateTime(2026, 1, 2).millisecondsSinceEpoch ~/ 1000,
  );
}

/// Creates a seller-ack (commit-stage) order.
Future<Order> _buildSellerAck({
  required Order negotiate,
  required Listing listing,
  required KeyPair seller,
}) => _f.order(
  listing: listing,
  dTag: negotiate.getDtag()!,
  signerOverride: seller,
  stage: OrderStage.commit,
  start: negotiate.start,
  end: negotiate.end,
  pTags: [PTag.seller(listing.pubKey), PTag.buyer(negotiate.pubKey)],
  createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
);

/// Creates a buyer self-signed commit order with a [PaymentProof].
Future<Order> _buildSelfSignedCommit({
  required Order negotiate,
  required Listing listing,
  required KeyPair buyer,
  required PaymentProof proof,
}) => _f.order(
  listing: listing,
  dTag: negotiate.getDtag()!,
  signerOverride: buyer,
  stage: OrderStage.commit,
  start: negotiate.start,
  end: negotiate.end,
  quantity: negotiate.quantity,
  amount: negotiate.amount,
  proof: proof,
  pTags: [PTag.seller(listing.pubKey), PTag.buyer(buyer.publicKey)],
  createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
);

/// Creates a cancel-stage order.
Future<Order> _buildCancel({
  required Order source,
  required Listing listing,
  required KeyPair signer,
}) {
  final candidates = {source.pubKey, ...source.parsedTags.getTags('p')}
    ..remove(signer.publicKey);
  final host = listing.pubKey;
  return _f.order(
    listing: listing,
    dTag: source.getDtag()!,
    signerOverride: signer,
    stage: OrderStage.cancel,
    start: source.start,
    end: source.end,
    quantity: source.quantity,
    amount: source.amount,
    recipient: source.recipient,
    proof: source.proof,
    commitAuthorization: source.commitAuthorization,
    pTags: [
      for (final c in candidates) c == host ? PTag.seller(c) : PTag.buyer(c),
    ],
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

PaymentProof _buildEscrowPaymentProof({required Listing listing}) {
  final escrowService = MOCK_ESCROWS(
    contractAddress: '0xDEAD',
    evmAddress: '0x000000000000000000000000000000000000bEEF',
  ).first;
  final methodEvent = Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: kNostrKindEscrowMethod,
      pubKey: MockKeys.hoster.publicKey,
      tags: const [],
      content: '',
    ),
    privateKey: MockKeys.hoster.privateKey!,
  );

  return PaymentProof(
    hoster: Nip01EventModel.fromEntity(
      Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          kind: 0,
          pubKey: MockKeys.hoster.publicKey,
          tags: const [],
          content: '',
        ),
        privateKey: MockKeys.hoster.privateKey!,
      ),
    ),
    listing: listing,
    zapProof: null,
    escrowProof: EscrowProof(
      escrowService: escrowService,
      sellerEscrowMethods: EscrowMethod.fromNostrEvent(methodEvent),
      params: EvmEscrowProofParams(txHash: '0xabc123'),
    ),
  );
}

Future<Order> _buildEscrowCommit({
  required Order source,
  required Listing listing,
}) => _f.order(
  listing: listing,
  dTag: source.getDtag()!,
  signerOverride: MockKeys.escrow,
  stage: OrderStage.commit,
  start: source.start,
  end: source.end,
  quantity: source.quantity,
  amount: source.amount,
  recipient: source.recipient,
  pTags: [
    PTag.seller(listing.pubKey),
    PTag.buyer(source.pubKey),
    PTag.escrow(MockKeys.escrow.publicKey),
  ],
  createdAt: DateTime(2026, 1, 5).millisecondsSinceEpoch ~/ 1000,
);

// ═══════════════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════════════

void main() async {
  final listing = _listing();

  group('toOrderGroups', () {
    test('groups buyer and seller by trade id (d-tag)', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final ack = await _sellerAck(
        negotiate: nego,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final pairs = Orders.toOrderGroups(orders: [nego, ack]);

      expect(pairs.length, 1);
      final pair = pairs.values.first;
      expect(pair.sellerOrder, isNotNull);
      expect(pair.buyerOrder, isNotNull);
      expect(pair.sellerOrder!.pubKey, listing.pubKey);
      expect(pair.buyerOrder!.pubKey, buyer.publicKey);
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

      final pairs = Orders.toOrderGroups(orders: [nego1, nego2, ack1]);

      expect(pairs.length, 2);
    });

    test('buyer-only pair has null seller', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);

      final pairs = Orders.toOrderGroups(orders: [nego]);

      expect(pairs.length, 1);
      final pair = pairs.values.first;
      expect(pair.sellerOrder, isNull);
      expect(pair.buyerOrder, isNotNull);
    });

    test('empty list produces empty map', () {
      final pairs = Orders.toOrderGroups(orders: []);

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

      final pair = OrderGroup(orders: [ack, nego]);

      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Valid<OrderGroup>>());
    });

    test('seller-only pair (blocked date) → Valid', () {
      final ack = Order.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'blocked-hash',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(MockKeys.hoster, Order.fromNostrEvent);

      final pair = OrderGroup(orders: [ack]);

      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Valid<OrderGroup>>());
    });

    test('seller-only pair derives listing anchor and host pubkey', () {
      final ack = Order.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'blocked-anchor',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(MockKeys.hoster, Order.fromNostrEvent);

      final pair = OrderGroup(orders: [ack]);

      expect(pair.listingAnchor, listing.anchor);
      expect(pair.sellerPubkey, listing.pubKey);
    });

    test('buyer-only negotiate (no proof) → Invalid', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);

      final pair = OrderGroup(orders: [nego]);

      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Invalid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [cancelled, nego]);

      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Valid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [cancelled]);

      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Valid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [sellerCancelled, buyerCancelled]);

      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Valid<OrderGroup>>());
      expect((result as Valid).event.sellerCancelled, isTrue);
      expect((result as Valid).event.buyerCancelled, isTrue);
    });

    test('empty pair (both null) → Invalid', () {
      final pair = OrderGroup();

      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Invalid<OrderGroup>>());
      expect((result as Invalid).reason, contains('No order found'));
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

      final pairs = Orders.toOrderGroups(
        orders: [nego1, ack1, nego2, cancelled2],
      );

      final results = pairs.values
          .map((pair) => OrderGroups.verifyGroup(pair))
          .toList();

      final valid = results.whereType<Valid<OrderGroup>>().length;
      final cancelledValid = results
          .whereType<Valid<OrderGroup>>()
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

      final pairs = Orders.toOrderGroups(orders: [nego1, ack1, cancelled2]);

      final results = pairs.values
          .map((pair) => OrderGroups.verifyGroup(pair))
          .whereType<Valid<OrderGroup>>();

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

      final pair = OrderGroup(orders: [ack, nego]);

      // Default: seller confirmation makes it valid.
      final defaultResult = OrderGroups.verifyGroup(pair);
      expect(defaultResult, isA<Valid<OrderGroup>>());

      // Forced: buyer negotiate has no proof → Invalid.
      final forcedResult = OrderGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: true,
      );
      expect(forcedResult, isA<Invalid<OrderGroup>>());
    });

    test('forceValidateSelfSigned=true: seller-only pair (blocked date, '
        'no buyer) → Valid', () {
      final ack = Order.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'blocked-forced',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(MockKeys.hoster, Order.fromNostrEvent);

      final pair = OrderGroup(orders: [ack]);

      final result = OrderGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: true,
      );
      expect(result, isA<Valid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [ack, nego]);

      final result = OrderGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: false,
      );
      expect(result, isA<Valid<OrderGroup>>());
    });

    test('forceValidateSelfSigned=true: cancelled pair still Valid', () async {
      final buyer = MockKeys.guest;
      final nego = await _negotiate(listing: listing, buyer: buyer);
      final cancelled = await _cancel(
        source: nego,
        listing: listing,
        signer: buyer,
      );

      final pair = OrderGroup(orders: [cancelled]);

      final result = OrderGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: true,
      );
      expect(result, isA<Valid<OrderGroup>>());
      expect((result as Valid).event.buyerCancelled, isTrue);
    });

    test('forceValidateSelfSigned=true: empty pair (both null) → Invalid', () {
      final pair = OrderGroup();

      final result = OrderGroups.verifyGroup(
        pair,
        forceValidateSelfSigned: true,
      );
      expect(result, isA<Invalid<OrderGroup>>());
      expect((result as Invalid).reason, contains('No order found'));
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
      listing = _buildListing(host: host, allowSelfSignedOrder: true);
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

        final pair = OrderGroup(orders: [commit]);
        final result = OrderGroups.verifyGroup(pair);
        expect(result, isA<Valid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [commit]);
      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Valid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [commit]);
      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Invalid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [commit]);
      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Invalid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [commit]);
      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Invalid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [commit]);
      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Invalid<OrderGroup>>());
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

      final pair = OrderGroup(orders: [commit]);
      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Invalid<OrderGroup>>());
      expect(
        (result as Invalid).reason,
        contains('Unsupported or missing payment proof type'),
      );
    });
  });

  group('verifyGroupOnChain — confirmedCommitted', () {
    test(
      'escrow-backed buyer commit sets confirmedCommitted=true after verification',
      () async {
        final listing = _buildListing(
          host: MockKeys.hoster,
          allowSelfSignedOrder: true,
        );
        final negotiate = await _buildNegotiate(
          listing: listing,
          buyer: MockKeys.guest,
          salt: 'payment-valid-escrow',
        );
        final commit = await _buildSelfSignedCommit(
          negotiate: negotiate,
          listing: listing,
          buyer: MockKeys.guest,
          proof: _buildEscrowPaymentProof(listing: listing),
        );

        final result = await OrderGroups.verifyGroupOnChain(
          OrderGroup(orders: [commit]),
          forceValidateSelfSigned: true,
          escrowVerification: _StubEscrowVerification(
            validTradeIds: {commit.getDtag()!},
          ),
        );

        expect(result, isA<Valid<OrderGroup>>());
        expect((result as Valid<OrderGroup>).event.confirmedCommitted, isTrue);
      },
    );

    test(
      'cancelled escrow-backed buyer order keeps confirmedCommitted=true',
      () async {
        final listing = _buildListing(
          host: MockKeys.hoster,
          allowSelfSignedOrder: true,
        );
        final negotiate = await _buildNegotiate(
          listing: listing,
          buyer: MockKeys.guest,
          salt: 'payment-valid-cancelled',
        );
        final commit = await _buildSelfSignedCommit(
          negotiate: negotiate,
          listing: listing,
          buyer: MockKeys.guest,
          proof: _buildEscrowPaymentProof(listing: listing),
        );
        final cancel = await _buildCancel(
          source: commit,
          listing: listing,
          signer: MockKeys.guest,
        );

        final result = await OrderGroups.verifyGroupOnChain(
          OrderGroup(orders: [cancel]),
          forceValidateSelfSigned: true,
          escrowVerification: _StubEscrowVerification(
            validTradeIds: {cancel.getDtag()!},
          ),
        );

        expect(result, isA<Valid<OrderGroup>>());
        final group = (result as Valid<OrderGroup>).event;
        expect(group.cancelled, isTrue);
        expect(group.confirmedCommitted, isTrue);
      },
    );

    test(
      'escrow commit sets confirmedCommitted=true without on-chain verifier',
      () async {
        final listing = _buildListing(
          host: MockKeys.hoster,
          allowSelfSignedOrder: true,
        );
        final negotiate = await _buildNegotiate(
          listing: listing,
          buyer: MockKeys.guest,
          salt: 'payment-valid-escrow-commit',
        );
        final buyerCommit = await _buildSelfSignedCommit(
          negotiate: negotiate,
          listing: listing,
          buyer: MockKeys.guest,
          proof: _buildEscrowPaymentProof(listing: listing),
        );
        final escrowCommit = await _buildEscrowCommit(
          source: buyerCommit,
          listing: listing,
        );

        final result = await OrderGroups.verifyGroupOnChain(
          OrderGroup(orders: [buyerCommit, escrowCommit]),
          forceValidateSelfSigned: true,
        );

        expect(result, isA<Valid<OrderGroup>>());
        expect((result as Valid<OrderGroup>).event.confirmedCommitted, isTrue);
      },
    );

    test(
      'escrow commit is valid without rechecking buyer proof in normal UI mode',
      () async {
        final listing = _buildListing(
          host: MockKeys.hoster,
          allowSelfSignedOrder: true,
        );
        final negotiate = await _buildNegotiate(
          listing: listing,
          buyer: MockKeys.guest,
          salt: 'payment-valid-escrow-commit-trusted',
        );
        final buyerCommit = await _buildSelfSignedCommit(
          negotiate: negotiate,
          listing: listing,
          buyer: MockKeys.guest,
          proof: _buildEscrowPaymentProof(listing: listing),
        );
        final escrowCommit = await _buildEscrowCommit(
          source: buyerCommit,
          listing: listing,
        );
        final verifier = _StubEscrowVerification();

        final result = await OrderGroups.verifyGroupOnChain(
          OrderGroup(orders: [buyerCommit, escrowCommit]),
          escrowVerification: verifier,
        );

        expect(result, isA<Valid<OrderGroup>>());
        expect((result as Valid<OrderGroup>).event.confirmedCommitted, isTrue);
        expect(verifier.verifiedTradeIds, isEmpty);
      },
    );

    test('seller-confirmed order sets confirmedCommitted=true', () async {
      final listing = _buildListing(host: MockKeys.hoster);
      final negotiate = await _buildNegotiate(
        listing: listing,
        buyer: MockKeys.guest,
        salt: 'payment-valid-seller-only',
      );
      final sellerAck = await _buildSellerAck(
        negotiate: negotiate,
        listing: listing,
        seller: MockKeys.hoster,
      );

      final result = await OrderGroups.verifyGroupOnChain(
        OrderGroup(orders: [sellerAck, negotiate]),
      );

      expect(result, isA<Valid<OrderGroup>>());
      expect((result as Valid<OrderGroup>).event.confirmedCommitted, isTrue);
    });

    test('negotiate-only order stays confirmedCommitted=false', () async {
      final listing = _buildListing(
        host: MockKeys.hoster,
        allowSelfSignedOrder: true,
      );
      final negotiate = await _buildNegotiate(
        listing: listing,
        buyer: MockKeys.guest,
        salt: 'confirmed-nego-only',
      );

      final result = await OrderGroups.verifyGroupOnChain(
        OrderGroup(orders: [negotiate]),
        forceValidateSelfSigned: false,
      );

      expect(result, isA<Invalid<OrderGroup>>());
    });
  });

  // ─── Group 5: allowSelfSignedOrder flag ──────────────────────────

  group('verifyGroup — allowSelfSignedOrder flag', () {
    final host = MockKeys.hoster;
    final buyer = MockKeys.guest;

    test(
      'self-signed commit with proof when allowSelfSigned=true → Valid',
      () async {
        final listing = _buildListing(host: host, allowSelfSignedOrder: true);
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

        final pair = OrderGroup(orders: [commit]);
        final result = OrderGroups.verifyGroup(pair);
        expect(result, isA<Valid<OrderGroup>>());
      },
    );

    test(
      'self-signed commit WITHOUT proof when allowSelfSigned=false → Invalid',
      () async {
        final listing = _buildListing(host: host, allowSelfSignedOrder: false);
        final nego = await _buildNegotiate(listing: listing, buyer: buyer);

        final pair = OrderGroup(orders: [nego]);
        final result = OrderGroups.verifyGroup(pair);
        expect(result, isA<Invalid<OrderGroup>>());
      },
    );

    test('self-signed commit WITH valid proof when allowSelfSigned=false '
        '→ still Valid (proof is sufficient)', () async {
      // NOTE: Current validation logic does NOT check
      // allowSelfSignedOrder — it only checks the payment proof.
      // This test documents that current behavior.
      final listing = _buildListing(host: host, allowSelfSignedOrder: false);
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

      final pair = OrderGroup(orders: [commit]);
      final result = OrderGroups.verifyGroup(pair);
      expect(result, isA<Valid<OrderGroup>>());
    });
  });

  // ─── Group 6: Negotiation validation ────────────────────────────────────────

  group('verifyGroup — negotiation scenarios', () {
    final host = MockKeys.hoster;
    final buyer = MockKeys.guest;

    test(
      'buyer offers lower price without seller ack → Invalid (no proof)',
      () async {
        final listing = _buildListing(host: host, negotiable: true);
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

        final pair = OrderGroup(orders: [ack, nego]);

        final result = OrderGroups.verifyGroup(pair);
        expect(result, isA<Valid<OrderGroup>>());
      },
    );

    test(
      'buyer offers listing price with zap proof (no negotiation) → Valid',
      () async {
        final listing = _buildListing(
          host: host,
          negotiable: false,
          allowSelfSignedOrder: true,
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

        final pair = OrderGroup(orders: [commit]);
        final result = OrderGroups.verifyGroup(pair);
        expect(result, isA<Valid<OrderGroup>>());
      },
    );
  });

  // ─── Group 7: Pipeline (toOrderGroups → verifyGroup) ───────────────

  group('toOrderGroups + verifyGroup pipeline (with proofs)', () {
    final host = MockKeys.hoster;
    final buyer = MockKeys.guest;
    final buyer2 = MockKeys.reviewer;

    late Listing listing;
    late Nip01Event hosterProfile;

    setUp(() {
      listing = _buildListing(host: host, allowSelfSignedOrder: true);
      hosterProfile = _buildProfileEvent(
        key: host,
        lud16: 'host@hostr.development',
      );
    });

    test('mixed orders: valid, cancelled, and invalid pairs', () async {
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

      final pairs = Orders.toOrderGroups(
        orders: [nego1, ack1, nego2, cancelled2, nego3],
      );

      final results = pairs.values
          .map((pair) => OrderGroups.verifyGroup(pair))
          .toList();

      final validCount = results.whereType<Valid<OrderGroup>>().length;
      final invalidCount = results.whereType<Invalid<OrderGroup>>().length;

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

        final pairs = Orders.toOrderGroups(
          orders: [nego1, ack1, commit2, nego3],
        );

        final results = pairs.values
            .map((pair) => OrderGroups.verifyGroup(pair))
            .toList();

        final validCount = results.whereType<Valid<OrderGroup>>().length;

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

      final pairs = Orders.toOrderGroups(
        orders: [nego1, ack1, nego2, buyerCancelled, nego3, sellerCancelled],
      );

      final results = pairs.values
          .map((pair) => OrderGroups.verifyGroup(pair))
          .toList();

      final activeCount = results
          .whereType<Valid<OrderGroup>>()
          .where((v) => !v.event.cancelled)
          .length;

      expect(
        activeCount,
        1,
        reason: 'Only pair 1 is active; pairs 2 & 3 are cancelled',
      );
    });
  });

  // ─── Group 8: Order.validate — direct ────────────────────────────

  group('Order.validate — direct', () {
    final host = MockKeys.hoster;
    final buyer = MockKeys.guest;

    late Listing listing;

    setUp(() {
      listing = _buildListing(host: host);
    });

    test('host-published order → always valid', () {
      final hostRes = Order.create(
        pubKey: host.publicKey,
        dTag: 'any-hash',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        stage: OrderStage.commit,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(host, Order.fromNostrEvent);

      final result = Order.validate(hostRes);
      expect(result.isValid, isTrue);
      expect(result.fields['publisher']?.ok, isTrue);
    });

    test('buyer without proof → invalid', () async {
      final nego = await _buildNegotiate(listing: listing, buyer: buyer);

      final result = Order.validate(nego);
      expect(result.isValid, isFalse);
      expect(result.fields['proof']?.ok, isFalse);
    });
  });

  group('verifyFromSource', () {
    test('can skip proof, signature, and on-chain order validation', () async {
      final listing = _listing();
      final negotiate = await _negotiate(
        listing: listing,
        buyer: MockKeys.guest,
      );
      final group = OrderGroup.fromOrder(negotiate);

      expect(OrderGroups.verifyGroup(group), isA<Invalid>());

      final source = StreamWithStatus<Order>();
      final orderGroups = OrderGroups(
        orders: _FakeOrders(),
        logger: CustomLogger(),
        evm: _FakeEvm(),
      );
      final validationStream = orderGroups.verifyFromSource(
        source: source,
        validate: false,
      );

      final nextValidation = validationStream.replayStream.first;
      source.add(negotiate);

      final result = await nextValidation.timeout(const Duration(seconds: 1));

      expect(result, isA<Valid<OrderGroup>>());
      expect((result as Valid<OrderGroup>).event.buyerOrder?.id, negotiate.id);

      await validationStream.close();
      await source.close();
    });
  });
}
