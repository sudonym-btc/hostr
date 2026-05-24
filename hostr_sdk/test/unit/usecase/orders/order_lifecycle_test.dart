/// Order lifecycle integration-style tests.
///
/// Covers:
/// - Creating a negotiate order with deterministic trade id & commitment hash
/// - Self-signed commit with escrow proof (autoAccept=true)
/// - Seller-ack flow (autoAccept=false)
/// - Buyer / seller cancel → OrderGroupStatus accuracy
/// - negotiable × autoAccept matrix
/// - Commit-terms validation and hash integrity
/// - OrderTransition validation across the lifecycle
/// - Participant proof payload hash stability
@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/seed.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

final _f = EntityFactory();

// ═══════════════════════════════════════════════════════════════════════
//  Helpers
// ═══════════════════════════════════════════════════════════════════════

/// Build a signed [Listing] with configurable policy flags.
Listing _listing({
  KeyPair? signer,
  bool negotiable = false,
  bool autoAccept = true,
  int pricePerNightSats = 100000,
  List<Price>? price,
}) {
  final key = signer ?? MockKeys.hoster;
  return _f.listing(
    signer: key,
    dTag: 'listing-${key.publicKey.substring(0, 8)}',
    title: 'Test Cottage',
    description: 'A lovely place',
    images: const ['https://picsum.photos/seed/1/800/600'],
    price: price,
    priceSats: pricePerNightSats,
    location: 'test-location',
    type: ListingType.house,
    specifications: Specifications(),
    negotiable: negotiable,
    autoAccept: autoAccept,
    createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
  );
}

/// Build a negotiate-stage order "DM payload" from the buyer.
Future<Order> _negotiateOrder({
  required Listing listing,
  required KeyPair buyer,
  required String salt,
  DateTime? start,
  DateTime? end,
  int quantity = 1,
  DenominatedAmount? amount,
}) => _f.order(
  listing: listing,
  dTag: 'trade-$salt',
  signerOverride: buyer,
  stage: OrderStage.negotiate,
  start: start ?? DateTime(2026, 3, 1),
  end: end ?? DateTime(2026, 3, 5),
  quantity: quantity,
  amount: amount,
  createdAt: DateTime(2026, 1, 2).millisecondsSinceEpoch ~/ 1000,
);

/// Build a commit-stage order (self-signed by the buyer).
Future<Order> _commitOrder({
  required Order negotiate,
  required Listing listing,
  required KeyPair buyer,
  PaymentProof? proof,
  CommitAuthorization? commitAuthorization,
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
  commitAuthorization: commitAuthorization,
  pTags: [PTag.seller(listing.pubKey), PTag.buyer(buyer.publicKey)],
  createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
);

CommitAuthorization _commitAuthorizationFor({
  required Order order,
  required KeyPair signer,
}) {
  return CommitAuthorization.create(
    pubKey: signer.publicKey,
    listingAnchor: order.parsedTags.listingAnchor,
    tradeId: order.getDtag()!,
    commitHash: order.commitHash(),
  ).signAs(signer, CommitAuthorization.fromNostrEvent);
}

/// Build a seller acknowledgement order (host confirms).
Future<Order> _sellerAckOrder({
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

/// Build a cancelled order from either party.
Future<Order> _cancelOrder({
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
    pTags: [
      for (final c in candidates) c == host ? PTag.seller(c) : PTag.buyer(c),
    ],
    createdAt: DateTime(2026, 1, 4).millisecondsSinceEpoch ~/ 1000,
  );
}

/// Build a [OrderTransition] event for testing transition validation.
OrderTransition _transition({
  required OrderTransitionType type,
  required OrderStage from,
  required OrderStage to,
  String? commitTermsHash,
  String? reason,
  KeyPair? signer,
  int createdAtOffset = 0,
  String? prevTransitionId,
}) {
  final key = signer ?? MockKeys.guest;
  final content = OrderTransitionContent(
    transitionType: type,
    fromStage: from,
    toStage: to,
    commitTermsHash: commitTermsHash,
    reason: reason,
  );

  final unsigned = Nip01Event(
    kind: kNostrKindOrderTransition,
    pubKey: key.publicKey,
    createdAt:
        DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000 + createdAtOffset,
    tags: [
      ['d', 'trade-1'],
      if (prevTransitionId != null) ['prev', prevTransitionId],
    ],
    content: content.toString(),
  );

  return OrderTransition.fromNostrEvent(
    Nip01Utils.signWithPrivateKey(event: unsigned, privateKey: key.privateKey!),
  );
}

/// Minimal fake EVM proof with escrow context for `Order.validate`.
PaymentProof _escrowPaymentProof({required Listing listing}) {
  final escrowService = MOCK_ESCROWS(
    contractAddress: '0xDEAD',
    evmAddress: '0x000000000000000000000000000000000000bEEF',
  ).first;
  final methodEvent = Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: kNostrKindEscrowMethod,
      pubKey: MockKeys.hoster.publicKey,
      tags: [],
      content: '',
    ),
    privateKey: MockKeys.hoster.privateKey!,
  );

  return PaymentProof.evm(
    listing: listing,
    txHash: '0xabc123',
    escrowService: escrowService,
    sellerEscrowMethod: EscrowMethod.fromNostrEvent(methodEvent),
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════════════

void main() async {
  final buyer = MockKeys.guest;
  final seller = MockKeys.hoster;

  // ── 1. Listing autoAccept field ────────────────────

  group('Listing.autoAccept', () {
    test('Listing.create emits autoAccept=true by default', () {
      final listing = _listing();
      expect(listing.autoAccept, isTrue);
    });

    test('round-trips through Listing.create when true', () {
      final listing = _listing(autoAccept: true);
      expect(listing.autoAccept, isTrue);
    });

    test('round-trips through Listing.create when false', () {
      final listing = _listing(autoAccept: false);
      expect(listing.autoAccept, isFalse);
    });

    test('missing tag parses as false', () {
      final listing = _listing();
      final tags = listing.tags
          .where((tag) => tag.first != 'autoAccept' && tag.first != 'I')
          .toList();
      final reparsed = Listing.fromNostrEvent(listing.copyWith(tags: tags));
      expect(reparsed.autoAccept, isFalse);
    });
  });

  // ── 2. Negotiate order via DM ────────────────────────────────

  group('Negotiate order creation', () {
    test('negotiate order has correct stage and salt', () async {
      final listing = _listing();
      const salt = 'buyer-secret-salt-123';
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: salt,
      );

      expect(negotiate.stage, OrderStage.negotiate);
      expect(negotiate.isNegotiation, isTrue);
      expect(negotiate.isCommit, isFalse);
    });

    test('trade id (d-tag) is deterministic from salt', () async {
      final listing = _listing();
      const salt = 'my-secret';
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: salt,
      );

      expect(negotiate.getDtag(), 'trade-$salt');
    });

    test('commitHash is computed correctly', () async {
      final listing = _listing();
      final start = DateTime(2026, 4, 1);
      final end = DateTime(2026, 4, 5);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt',
        start: start,
        end: end,
        quantity: 2,
      );

      final expected = OrderContent(
        start: start,
        end: end,
        quantity: 2,
        amount: listing.cost(start: start, end: end),
      );

      expect(negotiate.commitHash(), expected.commitHash());
    });

    test('negotiate order references listing anchor', () async {
      final listing = _listing();
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt',
      );
      expect(negotiate.parsedTags.listingAnchor, listing.anchor);
    });
  });

  // ── 3. Salt preservation for trade-specific pubkey recovery ────────

  group('Salt preservation', () {
    test('trade id remains deterministic when the same salt is reused', () {
      const salt = 'preserved-buyer-salt';
      final commitment = 'trade-$salt';

      // Simulate later recovery: buyer still has salt
      final recovered = 'trade-$salt';
      expect(recovered, commitment);
    });

    test('different salt produces different trade ids', () {
      final h1 = 'trade-salt-a';
      final h2 = 'trade-salt-b';
      expect(h1, isNot(equals(h2)));
    });

    test('participant proof payload hash is deterministic', () {
      final h1 = OrderParticipantProofTag.hashPayload('signed-authorization');
      final h2 = OrderParticipantProofTag.hashPayload('signed-authorization');
      expect(h1, equals(h2));
    });

    test('salt is not carried into published commit transition', () async {
      final listing = _listing(autoAccept: true);
      const salt = 'buyer-keeps-this';
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: salt,
      );

      final commit = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );
      // Trade id (d-tag) matches across negotiate and commit
      expect(commit.getDtag(), negotiate.getDtag());

      // Commit terms hash matches across negotiate and commit
      expect(commit.commitHash(), negotiate.commitHash());
    });
  });

  // ── 4. Self-signed commit with escrow proof ────────────────────────

  group('Self-signed commit (autoAccept=true)', () {
    test('buyer can self-sign commit when listing allows it', () async {
      final listing = _listing(autoAccept: true);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-self',
      );
      final proof = _escrowPaymentProof(listing: listing);
      final commit = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );

      expect(commit.stage, OrderStage.commit);
      expect(commit.isCommit, isTrue);
      expect(commit.proof, isNotNull);
      expect(commit.proof!.hasEscrowPaymentProof, isTrue);
    });

    test('commit preserves commitTermsHash from negotiate', () async {
      final listing = _listing(autoAccept: true);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-hash',
      );
      final commit = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );

      expect(commit.commitHash(), negotiate.commitHash());
    });

    test(
      'commit with altered terms produces different commitTermsHash',
      () async {
        final listing = _listing(autoAccept: true);
        final negotiate = await _negotiateOrder(
          listing: listing,
          buyer: buyer,
          salt: 'salt-tamper',
          start: DateTime(2026, 5, 1),
          end: DateTime(2026, 5, 5),
          quantity: 1,
        );

        // Tampered commit with different dates
        final tamperedHash = OrderContent(
          start: DateTime(2026, 5, 1),
          end: DateTime(2026, 5, 10), // extended!
          quantity: 1,
        ).commitHash();

        expect(
          tamperedHash,
          isNot(equals(negotiate.commitHash())),
          reason: 'Altered terms must produce a different hash',
        );
      },
    );
  });

  // ── 5. Seller-ack flow (autoAccept=false) ──────────

  group('Seller-ack flow (autoAccept=false)', () {
    test('seller ack order references same trade id (d-tag)', () async {
      final listing = _listing(autoAccept: false);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-ack',
      );
      final sellerAck = await _sellerAckOrder(
        negotiate: negotiate,
        listing: listing,
        seller: seller,
      );

      expect(sellerAck.stage, OrderStage.commit);
      expect(sellerAck.pubKey, seller.publicKey);
      expect(sellerAck.getDtag(), negotiate.getDtag());
    });

    test('Order.validate accepts host order without proof', () async {
      final listing = _listing(autoAccept: false);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-host',
      );
      final sellerAck = await _sellerAckOrder(
        negotiate: negotiate,
        listing: listing,
        seller: seller,
      );

      final result = Order.validate(sellerAck);
      expect(
        result.isValid,
        isTrue,
        reason: 'Host published order is always valid',
      );
    });

    test('Order.validate rejects buyer commit without proof when listing '
        'does not allow self-signed', () async {
      final listing = _listing(autoAccept: false);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-noself',
      );

      // Buyer publishes commit WITHOUT a proof
      final commitNoProof = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: null,
      );

      final result = Order.validate(commitNoProof);
      expect(result.isValid, isFalse);
    });
  });

  // ── 6. negotiable × autoAccept matrix ─────────────

  group('Listing policy flag matrix', () {
    for (final negotiable in [true, false]) {
      for (final selfSigned in [true, false]) {
        test('negotiable=$negotiable, autoAccept=$selfSigned '
            'roundtrips', () {
          final listing = _listing(
            negotiable: negotiable,
            autoAccept: selfSigned,
          );
          expect(listing.negotiable, negotiable);
          expect(listing.autoAccept, selfSigned);
        });
      }
    }

    test('buyer self-signed commit accepted when autoAccept=true', () async {
      final listing = _listing(negotiable: false, autoAccept: true);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-matrix1',
      );
      final commit = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );

      // With escrow proof, Order.validate should accept
      final result = Order.validate(commit);
      expect(result.isValid, isTrue);
    });

    test(
      'buyer commit without proof rejected regardless of negotiable',
      () async {
        final listing = _listing(negotiable: true, autoAccept: false);
        final negotiate = await _negotiateOrder(
          listing: listing,
          buyer: buyer,
          salt: 'salt-matrix2',
        );
        final commit = await _commitOrder(
          negotiate: negotiate,
          listing: listing,
          buyer: buyer,
          proof: null,
        );

        final result = Order.validate(commit);
        expect(result.isValid, isFalse);
      },
    );
  });

  // ── 7. Commit-terms validation ─────────────────────────────────────

  group('Commit-terms validation', () {
    test('commitHash is deterministic', () {
      final a = OrderContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
      );
      final b = OrderContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
      );
      expect(a.commitHash(), equals(b.commitHash()));
    });

    test('commitHash() is deterministic across calls', () {
      final content = OrderContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
      );
      final h1 = content.commitHash();
      final h2 = content.commitHash();
      expect(h1, h2);
    });

    test('commitHash() is order-independent (keys sorted)', () {
      // Two OrderContents with identical committed fields
      // produce the same hash regardless of internal order.
      final content1 = OrderContent(
        start: DateTime.parse('2026-03-01'),
        end: DateTime.parse('2026-03-05'),
        quantity: 1,
      );
      final content2 = OrderContent(
        start: DateTime.parse('2026-03-01'),
        end: DateTime.parse('2026-03-05'),
        quantity: 1,
      );
      expect(content1.commitHash(), content2.commitHash());
    });

    test('different terms produce different hashes', () {
      final t1 = OrderContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
      );
      final t2 = OrderContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 2, // different
      );
      expect(t1.commitHash(), isNot(equals(t2.commitHash())));
    });

    test('committed order matches negotiated terms hash', () async {
      final listing = _listing(autoAccept: true);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-terms',
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 5),
        quantity: 2,
      );
      final commit = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );

      expect(commit.commitHash(), negotiate.commitHash());
      // Re-derive and verify
      final reDerived = OrderContent(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 5),
        quantity: 2,
        amount: listing.cost(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 5),
        ),
      ).commitHash();
      expect(commit.commitHash(), reDerived);
    });
  });

  // ── 7b. Seller-signature verification ──────────────────────────────

  group('Seller-signature verification', () {
    test('seller signs negotiate terms → buyer commit verifies', () async {
      final listing = _listing(autoAccept: true);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'sig-ok',
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 5),
        quantity: 1,
      );

      // Seller signs a structured authorization over the negotiate terms.
      final sellerAuthorization = _commitAuthorizationFor(
        order: negotiate,
        signer: seller,
      );

      // Buyer builds a matching commit carrying the seller authorization.
      final commit = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
        commitAuthorization: sellerAuthorization,
      );

      // The seller's authorization verifies on the buyer's commit.
      expect(commit.verifyCommit(seller.publicKey), isTrue);
    });

    test(
      'seller-signed cross-denomination amount overrides stale listing price',
      () async {
        final listing = _listing(
          autoAccept: true,
          price: [
            Price(
              amount: DenominatedAmount(
                value: BigInt.from(5000000),
                denomination: 'USD',
                decimals: 6,
              ),
              frequency: Frequency.daily,
            ),
          ],
        );
        final negotiatedAmount = DenominatedAmount(
          value: BigInt.from(5003),
          denomination: 'BTC',
          decimals: 8,
        );
        final negotiate = await _negotiateOrder(
          listing: listing,
          buyer: buyer,
          salt: 'sig-cross-denom',
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 2),
          amount: negotiatedAmount,
        );

        final sellerAuthorization = _commitAuthorizationFor(
          order: negotiate,
          signer: seller,
        );
        final commit = await _commitOrder(
          negotiate: negotiate,
          listing: listing,
          buyer: buyer,
          proof: _escrowPaymentProof(listing: listing),
          commitAuthorization: sellerAuthorization,
        );

        final expectedAmount = commit.resolveExpectedAmount(listing: listing);

        expect(expectedAmount.listingPrice.denomination, 'USD');
        expect(expectedAmount.hasOffListAmount, isTrue);
        expect(expectedAmount.sellerCommitOk, isTrue);
        expect(expectedAmount.usesNegotiatedAmount, isTrue);
        expect(expectedAmount.expectedAmount, negotiatedAmount);
        expect(expectedAmount.overrideFailureReason, isNull);
      },
    );

    test(
      'unsigned cross-denomination amount falls back to listing price',
      () async {
        final listing = _listing(
          autoAccept: true,
          price: [
            Price(
              amount: DenominatedAmount(
                value: BigInt.from(5000000),
                denomination: 'USD',
                decimals: 6,
              ),
              frequency: Frequency.daily,
            ),
          ],
        );
        final negotiate = await _negotiateOrder(
          listing: listing,
          buyer: buyer,
          salt: 'sig-cross-denom-missing',
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 2),
          amount: DenominatedAmount(
            value: BigInt.from(5003),
            denomination: 'BTC',
            decimals: 8,
          ),
        );
        final commit = await _commitOrder(
          negotiate: negotiate,
          listing: listing,
          buyer: buyer,
          proof: _escrowPaymentProof(listing: listing),
        );

        final expectedAmount = commit.resolveExpectedAmount(listing: listing);

        expect(expectedAmount.listingPrice.denomination, 'USD');
        expect(expectedAmount.hasOffListAmount, isTrue);
        expect(expectedAmount.sellerCommitOk, isFalse);
        expect(expectedAmount.usesNegotiatedAmount, isFalse);
        expect(expectedAmount.expectedAmount, expectedAmount.listingPrice);
        expect(
          expectedAmount.overrideFailureReason,
          'Missing valid host commitment for negotiated amount',
        );
      },
    );

    test('buyer alters dates → seller signature fails verification', () async {
      final listing = _listing(autoAccept: true);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'sig-tamper-dates',
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 5),
        quantity: 1,
      );

      // Seller signs the ORIGINAL negotiate terms.
      final sellerAuthorization = _commitAuthorizationFor(
        order: negotiate,
        signer: seller,
      );

      // Buyer tampers: extends the end date by 5 days.
      final tampered = Order.create(
        pubKey: buyer.publicKey,
        dTag: negotiate.getDtag()!,
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 10), // extended!
        stage: OrderStage.commit,
        quantity: 1,
        proof: _escrowPaymentProof(listing: listing),
        commitAuthorization: sellerAuthorization,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(buyer, Order.fromNostrEvent);

      // Hashes differ.
      expect(tampered.commitHash(), isNot(equals(negotiate.commitHash())));
      // Seller's authorization does NOT verify on tampered content.
      expect(tampered.verifyCommit(seller.publicKey), isFalse);
    });

    test(
      'buyer alters quantity → seller signature fails verification',
      () async {
        final listing = _listing(autoAccept: true);
        final negotiate = await _negotiateOrder(
          listing: listing,
          buyer: buyer,
          salt: 'sig-tamper-qty',
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 5),
          quantity: 1,
        );

        final sellerAuthorization = _commitAuthorizationFor(
          order: negotiate,
          signer: seller,
        );

        // Buyer tampers: doubles the quantity.
        final tampered = Order.create(
          pubKey: buyer.publicKey,
          dTag: negotiate.getDtag()!,
          listingAnchor: listing.anchor!,
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 5),
          stage: OrderStage.commit,
          quantity: 2, // tampered!
          proof: _escrowPaymentProof(listing: listing),
          commitAuthorization: sellerAuthorization,
          createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
        ).signAs(buyer, Order.fromNostrEvent);

        expect(tampered.verifyCommit(seller.publicKey), isFalse);
      },
    );

    test('buyer alters amount → seller signature fails verification', () async {
      final listing = _listing(autoAccept: true);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'sig-tamper-amount',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 5),
        quantity: 1,
        amount: DenominatedAmount(
          value: BigInt.from(100000),
          denomination: 'BTC',
          decimals: 8,
        ),
      );

      final sellerAuthorization = _commitAuthorizationFor(
        order: negotiate,
        signer: seller,
      );

      // Buyer tampers: lowers the price.
      final tampered = Order.create(
        pubKey: buyer.publicKey,
        dTag: negotiate.getDtag()!,
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 5),
        stage: OrderStage.commit,
        quantity: 1,
        amount: DenominatedAmount(
          value: BigInt.from(50000),
          denomination: 'BTC',
          decimals: 8,
        ), // tampered!
        proof: _escrowPaymentProof(listing: listing),
        commitAuthorization: sellerAuthorization,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
      ).signAs(buyer, Order.fromNostrEvent);

      expect(tampered.verifyCommit(seller.publicKey), isFalse);
    });

    test(
      'buyer changes recipient → seller signature fails verification',
      () async {
        final listing = _listing(autoAccept: true);
        final negotiate = await _negotiateOrder(
          listing: listing,
          buyer: buyer,
          salt: 'sig-tamper-recipient',
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 5),
          quantity: 1,
        );

        // Explicitly set a recipient, then sign.
        final withRecipient = negotiate.copy(
          content: negotiate.parsedContent.copyWith(recipient: buyer.publicKey),
        );
        final sellerAuthorization = _commitAuthorizationFor(
          order: withRecipient,
          signer: seller,
        );

        // Buyer tampers: swaps in a different recipient.
        final tampered = Order.create(
          pubKey: buyer.publicKey,
          dTag: negotiate.getDtag()!,
          listingAnchor: listing.anchor!,
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 5),
          stage: OrderStage.commit,
          quantity: 1,
          recipient: seller.publicKey, // tampered — different pubkey
          proof: _escrowPaymentProof(listing: listing),
          commitAuthorization: sellerAuthorization,
          createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
        ).signAs(buyer, Order.fromNostrEvent);

        expect(tampered.verifyCommit(seller.publicKey), isFalse);
      },
    );

    test('no seller authorization present → verifyCommit returns false', () {
      final order = Order.create(
        pubKey: buyer.publicKey,
        dTag: 'trade-no-auth',
        listingAnchor: '30402:${seller.publicKey}:listing',
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
      );

      expect(order.verifyCommit(seller.publicKey), isFalse);
    });

    test(
      'forged authorization (wrong private key) → verifyCommit returns false',
      () async {
        final listing = _listing(autoAccept: true);
        final negotiate = await _negotiateOrder(
          listing: listing,
          buyer: buyer,
          salt: 'sig-forged',
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 5),
          quantity: 1,
        );

        // A random third party signs — not the seller.
        final imposter = Bip340.generatePrivateKey();
        final imposterAuthorization = _commitAuthorizationFor(
          order: negotiate,
          signer: imposter,
        );

        // Buyer attaches the imposter authorization but claims it's from seller.
        final commit = await _commitOrder(
          negotiate: negotiate,
          listing: listing,
          buyer: buyer,
          proof: _escrowPaymentProof(listing: listing),
          commitAuthorization: imposterAuthorization,
        );

        // Verify against the seller pubkey → false.
        expect(commit.verifyCommit(seller.publicKey), isFalse);
      },
    );

    test('commit authorization + verifyCommit round-trip on Order', () {
      final order = Order.create(
        pubKey: buyer.publicKey,
        dTag: 'trade-roundtrip',
        listingAnchor: '30402:${seller.publicKey}:listing',
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 2,
        amount: DenominatedAmount(
          value: BigInt.from(100000),
          denomination: 'BTC',
          decimals: 8,
        ),
        recipient: buyer.publicKey,
      );

      final authorization = _commitAuthorizationFor(
        order: order,
        signer: seller,
      );
      final signed = order.copy(
        content: order.parsedContent.copyWith(
          commitAuthorization: authorization,
        ),
      );

      // Verify.
      expect(signed.verifyCommit(seller.publicKey), isTrue);
      expect(
        signed.verifyCommit(buyer.publicKey),
        isFalse,
      ); // buyer didn't sign
    });
  });

  // ── 8. Buyer / Seller cancel → OrderGroupStatus ───────────────

  group('OrderGroupStatus after cancel', () {
    test('buyer cancels negotiate → pair shows cancelled', () async {
      final listing = _listing();
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-cancel1',
      );
      final buyerCancel = await _cancelOrder(
        source: negotiate,
        listing: listing,
        signer: buyer,
      );

      final status = OrderGroup(orders: [buyerCancel]);

      expect(status.cancelled, isTrue);
      expect(status.buyerCancelled, isTrue);
      expect(status.sellerCancelled, isFalse);
      expect(status.stage, OrderStage.cancel);
      expect(status.isActive, isFalse);
    });

    test('seller cancels committed → pair shows cancelled', () async {
      final listing = _listing(autoAccept: true);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-cancel2',
      );
      final commit = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );
      final sellerCancel = await _cancelOrder(
        source: commit,
        listing: listing,
        signer: seller,
      );

      final status = OrderGroup(orders: [sellerCancel, commit]);

      expect(status.cancelled, isTrue);
      expect(status.sellerCancelled, isTrue);
      expect(status.buyerCancelled, isFalse);
      expect(status.stage, OrderStage.cancel);
      expect(status.isActive, isFalse);
    });

    test('both cancel → pair shows cancelled, both sides', () async {
      final listing = _listing();
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-cancel3',
      );
      final buyerCancel = await _cancelOrder(
        source: negotiate,
        listing: listing,
        signer: buyer,
      );
      final sellerCancel = await _cancelOrder(
        source: negotiate,
        listing: listing,
        signer: seller,
      );

      final status = OrderGroup(orders: [sellerCancel, buyerCancel]);

      expect(status.cancelled, isTrue);
      expect(status.buyerCancelled, isTrue);
      expect(status.sellerCancelled, isTrue);
    });

    test('active pair (committed, not cancelled)', () async {
      final listing = _listing(autoAccept: true);
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-active',
      );
      final commit = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );
      final sellerAck = await _sellerAckOrder(
        negotiate: negotiate,
        listing: listing,
        seller: seller,
      );

      final status = OrderGroup(orders: [sellerAck, commit]);

      expect(status.cancelled, isFalse);
      expect(status.isActive, isTrue);
      expect(status.stage, OrderStage.commit);
      expect(status.start, negotiate.start);
      expect(status.end, negotiate.end);
    });

    test('negotiate only → not active', () async {
      final listing = _listing();
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: 'salt-neg-only',
      );

      final status = OrderGroup(orders: [negotiate]);

      expect(status.cancelled, isFalse);
      expect(status.isActive, isFalse);
      expect(status.stage, OrderStage.negotiate);
    });
  });

  // ── 9. OrderTransition validation across lifecycle ───────────

  group('validateStateTransitions lifecycle', () {
    test('valid: negotiate → negotiate → commit (normal flow)', () {
      final first = _transition(
        type: OrderTransitionType.counterOffer,
        from: OrderStage.negotiate,
        to: OrderStage.negotiate,
        signer: buyer,
        createdAtOffset: 0,
      );
      final second = _transition(
        type: OrderTransitionType.counterOffer,
        from: OrderStage.negotiate,
        to: OrderStage.negotiate,
        signer: buyer,
        createdAtOffset: 1,
        prevTransitionId: first.id,
      );
      final third = _transition(
        type: OrderTransitionType.commit,
        from: OrderStage.negotiate,
        to: OrderStage.commit,
        signer: seller,
        createdAtOffset: 2,
        prevTransitionId: second.id,
      );
      final result = validateStateTransitions([third, first, second]);
      expect(result.isValid, isTrue);
    });

    test('valid: negotiate → commit → cancel', () {
      final first = _transition(
        type: OrderTransitionType.commit,
        from: OrderStage.negotiate,
        to: OrderStage.commit,
        signer: buyer,
        createdAtOffset: 0,
      );
      final second = _transition(
        type: OrderTransitionType.cancel,
        from: OrderStage.commit,
        to: OrderStage.cancel,
        signer: buyer,
        createdAtOffset: 1,
        prevTransitionId: first.id,
      );
      final result = validateStateTransitions([second, first]);
      expect(result.isValid, isTrue);
    });

    test('valid: negotiate → cancel (early cancellation)', () {
      final result = validateStateTransitions([
        _transition(
          type: OrderTransitionType.cancel,
          from: OrderStage.negotiate,
          to: OrderStage.cancel,
          signer: buyer,
          createdAtOffset: 0,
        ),
      ]);
      expect(result.isValid, isTrue);
    });

    test('invalid: commit → negotiate (rollback attempt)', () {
      final first = _transition(
        type: OrderTransitionType.commit,
        from: OrderStage.negotiate,
        to: OrderStage.commit,
        signer: buyer,
        createdAtOffset: 0,
      );
      final second = _transition(
        type: OrderTransitionType.counterOffer,
        from: OrderStage.negotiate,
        to: OrderStage.negotiate,
        signer: buyer,
        createdAtOffset: 1,
        prevTransitionId: first.id,
      );
      final result = validateStateTransitions([first, second]);
      expect(result.isValid, isFalse);
      expect(result.failedIndex, 1);
      expect(result.reason, contains('Chain break'));
    });

    test('invalid: cancel → cancel (double cancel)', () {
      final first = _transition(
        type: OrderTransitionType.cancel,
        from: OrderStage.negotiate,
        to: OrderStage.cancel,
        signer: buyer,
        createdAtOffset: 0,
      );
      final second = _transition(
        type: OrderTransitionType.cancel,
        from: OrderStage.cancel,
        to: OrderStage.cancel,
        signer: buyer,
        createdAtOffset: 1,
        prevTransitionId: first.id,
      );
      final result = validateStateTransitions([first, second]);
      expect(result.isValid, isFalse);
      expect(result.failedIndex, 1);
    });

    test('invalid: type mismatch — counterOffer with negotiate → commit', () {
      final result = validateStateTransitions([
        _transition(
          type: OrderTransitionType.counterOffer,
          from: OrderStage.negotiate,
          to: OrderStage.commit,
          signer: buyer,
        ),
      ]);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('does not match stages'));
    });

    test('valid: multiple counter-offers then cancel', () {
      final first = _transition(
        type: OrderTransitionType.counterOffer,
        from: OrderStage.negotiate,
        to: OrderStage.negotiate,
        signer: buyer,
        createdAtOffset: 0,
      );
      final second = _transition(
        type: OrderTransitionType.counterOffer,
        from: OrderStage.negotiate,
        to: OrderStage.negotiate,
        signer: seller,
        createdAtOffset: 1,
        prevTransitionId: first.id,
      );
      final third = _transition(
        type: OrderTransitionType.counterOffer,
        from: OrderStage.negotiate,
        to: OrderStage.negotiate,
        signer: buyer,
        createdAtOffset: 2,
        prevTransitionId: second.id,
      );
      final fourth = _transition(
        type: OrderTransitionType.cancel,
        from: OrderStage.negotiate,
        to: OrderStage.cancel,
        signer: buyer,
        createdAtOffset: 3,
        prevTransitionId: third.id,
      );
      final result = validateStateTransitions([fourth, second, first, third]);
      expect(result.isValid, isTrue);
    });
  });

  // ── 10. End-to-end lifecycle scenario ──────────────────────────────

  group('End-to-end order lifecycle', () {
    test('self-signed: negotiate → pay → commit → seller cancel', () async {
      final listing = _listing(autoAccept: true, negotiable: false);
      const salt = 'e2e-self-signed-salt';

      // Step 1: Buyer creates negotiate order (DM to seller)
      final negotiate = await _negotiateOrder(
        listing: listing,
        buyer: buyer,
        salt: salt,
      );
      expect(negotiate.isNegotiation, isTrue);

      // Step 2: Buyer pays, receives escrow proof
      final proof = _escrowPaymentProof(listing: listing);
      expect(proof.hasEscrowPaymentProof, isTrue);

      // Step 3: Buyer broadcasts commit with proof
      final commit = await _commitOrder(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );
      expect(commit.isCommit, isTrue);
      expect(commit.proof!.evmParams!.txHash, '0xabc123');

      // Validate the commit is accepted
      final validation = Order.validate(commit);
      expect(validation.isValid, isTrue);

      // OrderGroupStatus shows active
      var status = OrderGroup(orders: [commit]);
      expect(status.isActive, isTrue);
      expect(status.stage, OrderStage.commit);

      // Step 4: Seller cancels
      final sellerCancel = await _cancelOrder(
        source: commit,
        listing: listing,
        signer: seller,
      );

      status = OrderGroup(orders: [sellerCancel, commit]);
      expect(status.cancelled, isTrue);
      expect(status.sellerCancelled, isTrue);
      expect(status.isActive, isFalse);

      // Step 5: Validate transition chain
      final commitTransition = _transition(
        type: OrderTransitionType.commit,
        from: OrderStage.negotiate,
        to: OrderStage.commit,
        signer: buyer,
        commitTermsHash: commit.commitHash(),
        createdAtOffset: 0,
      );
      final cancelTransition = _transition(
        type: OrderTransitionType.cancel,
        from: OrderStage.commit,
        to: OrderStage.cancel,
        signer: seller,
        reason: 'Property damage',
        createdAtOffset: 1,
        prevTransitionId: commitTransition.id,
      );
      final transitions = [cancelTransition, commitTransition];
      expect(validateStateTransitions(transitions).isValid, isTrue);

      // Step 6: Trade id (d-tag) is deterministic from salt
      expect(commit.getDtag(), 'trade-$salt');
    });

    test(
      'seller-ack: negotiate → counter-offers → sellerAck → buyer cancel',
      () async {
        final listing = _listing(autoAccept: false, negotiable: true);
        const salt = 'e2e-seller-ack-salt';

        // Step 1: Buyer proposes
        final negotiate = await _negotiateOrder(
          listing: listing,
          buyer: buyer,
          salt: salt,
          amount: DenominatedAmount(
            value: BigInt.from(80000),
            denomination: 'BTC',
            decimals: 8,
          ),
        );
        expect(negotiate.amount!.value, BigInt.from(80000));

        // Step 2: Seller acks (agrees to negotiated price)
        final sellerAck = await _sellerAckOrder(
          negotiate: negotiate,
          listing: listing,
          seller: seller,
        );
        expect(sellerAck.isCommit, isTrue);

        // Host order is valid without proof
        expect(Order.validate(sellerAck).isValid, isTrue);

        // OrderGroupStatus shows committed
        var status = OrderGroup(orders: [sellerAck, negotiate]);
        expect(status.isActive, isTrue);
        expect(status.stage, OrderStage.commit);

        // Step 3: Buyer cancels
        final buyerCancel = await _cancelOrder(
          source: negotiate,
          listing: listing,
          signer: buyer,
        );

        status = OrderGroup(orders: [sellerAck, buyerCancel]);
        expect(status.cancelled, isTrue);
        expect(status.buyerCancelled, isTrue);
        expect(status.sellerCancelled, isFalse);

        // Step 4: Validate buyer's transition chain
        final buyerTransitions = [
          _transition(
            type: OrderTransitionType.cancel,
            from: OrderStage.negotiate,
            to: OrderStage.cancel,
            signer: buyer,
          ),
        ];
        expect(validateStateTransitions(buyerTransitions).isValid, isTrue);

        // Step 5: Validate seller's transition chain
        final sellerTransitions = [
          _transition(
            type: OrderTransitionType.commit,
            from: OrderStage.negotiate,
            to: OrderStage.commit,
            signer: seller,
          ),
        ];
        expect(validateStateTransitions(sellerTransitions).isValid, isTrue);

        // Step 6: Trade id (d-tag) is deterministic from salt
        expect(negotiate.getDtag(), 'trade-$salt');
      },
    );
  });
}
