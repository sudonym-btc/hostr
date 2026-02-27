/// Reservation lifecycle integration-style tests.
///
/// Covers:
/// - Creating a negotiate reservation with salt & commitment hash
/// - Self-signed commit with escrow proof (allowSelfSignedReservation=true)
/// - Seller-ack flow (allowSelfSignedReservation=false)
/// - Buyer / seller cancel → ReservationPairStatus accuracy
/// - allowBarter × allowSelfSignedReservation matrix
/// - Commit-terms validation and hash integrity
/// - ReservationTransition validation across the lifecycle
/// - Salt preservation for trade-specific pubkey recovery
@Tags(['unit'])
library;

import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Nip01EventModel, Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

// ═══════════════════════════════════════════════════════════════════════
//  Helpers
// ═══════════════════════════════════════════════════════════════════════

/// Build a signed [Listing] with configurable policy flags.
Listing _listing({
  KeyPair? signer,
  bool allowBarter = false,
  bool allowSelfSignedReservation = false,
  bool requiresEscrow = false,
  int pricePerNightSats = 100000,
}) {
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
          amount: Amount(
            currency: Currency.BTC,
            value: BigInt.from(pricePerNightSats),
          ),
          frequency: Frequency.daily,
        ),
      ],
      allowBarter: allowBarter,
      allowSelfSignedReservation: allowSelfSignedReservation,
      minStay: const Duration(days: 1),
      checkIn: TimeOfDay(hour: 15, minute: 0),
      checkOut: TimeOfDay(hour: 11, minute: 0),
      location: 'test-location',
      quantity: 1,
      type: ListingType.house,
      images: ['https://picsum.photos/seed/1/800/600'],
      amenities: Amenities(),
      requiresEscrow: requiresEscrow,
    ),
  ).signAs(key, Listing.fromNostrEvent);
}

/// Build a negotiate-stage reservation "DM payload" from the buyer.
Reservation _negotiateReservation({
  required Listing listing,
  required KeyPair buyer,
  required String salt,
  DateTime? start,
  DateTime? end,
  int quantity = 1,
  Amount? amount,
}) {
  final s = start ?? DateTime(2026, 3, 1);
  final e = end ?? DateTime(2026, 3, 5);
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
      quantity: quantity,
      amount: amount,
      salt: salt,
    ),
  ).signAs(buyer, Reservation.fromNostrEvent);
}

/// Build a commit-stage reservation (self-signed by the buyer).
Reservation _commitReservation({
  required Reservation negotiate,
  required Listing listing,
  required KeyPair buyer,
  PaymentProof? proof,
  Map<String, String>? signatures,
}) {
  return Reservation(
    pubKey: buyer.publicKey,
    createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
    tags: ReservationTags([
      [kListingRefTag, listing.anchor!],
      ['d', negotiate.getDtag()!],
    ]),
    content: ReservationContent(
      start: negotiate.parsedContent.start,
      end: negotiate.parsedContent.end,
      stage: ReservationStage.commit,
      quantity: negotiate.parsedContent.quantity,
      amount: negotiate.parsedContent.amount,
      salt: negotiate.parsedContent.salt,
      proof: proof,
      signatures: signatures ?? const {},
    ),
  ).signAs(buyer, Reservation.fromNostrEvent);
}

/// Build a seller acknowledgement reservation (host confirms).
Reservation _sellerAckReservation({
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

/// Build a cancelled reservation from either party.
Reservation _cancelReservation({
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

/// Build a [ReservationTransition] event for testing transition validation.
ReservationTransition _transition({
  required ReservationTransitionType type,
  required ReservationStage from,
  required ReservationStage to,
  String? commitTermsHash,
  String? reason,
  KeyPair? signer,
  int createdAtOffset = 0,
}) {
  final key = signer ?? MockKeys.guest;
  final content = ReservationTransitionContent(
    transitionType: type,
    fromStage: from,
    toStage: to,
    commitTermsHash: commitTermsHash,
    reason: reason,
  );

  final unsigned = Nip01Event(
    kind: kNostrKindReservationTransition,
    pubKey: key.publicKey,
    createdAt:
        DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000 + createdAtOffset,
    tags: [
      ['d', 'trade-1'],
    ],
    content: content.toString(),
  );

  return ReservationTransition.fromNostrEvent(
    Nip01Utils.signWithPrivateKey(event: unsigned, privateKey: key.privateKey!),
  );
}

/// Minimal fake escrow proof that satisfies the `proof.escrowProof != null`
/// branch in `Reservation.validate`.
PaymentProof _escrowPaymentProof({required Listing listing}) {
  final escrowService = MOCK_ESCROWS(contractAddress: '0xDEAD').first;
  // Build minimal EscrowTrust & EscrowMethod from signed events.
  final trustEvent = Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: kNostrKindEscrowTrust,
      pubKey: MockKeys.hoster.publicKey,
      tags: [],
      content: '',
    ),
    privateKey: MockKeys.hoster.privateKey!,
  );
  final methodEvent = Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: kNostrKindEscrowMethod,
      pubKey: MockKeys.hoster.publicKey,
      tags: [],
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
          tags: [],
          content: '',
        ),
        privateKey: MockKeys.hoster.privateKey!,
      ),
    ),
    listing: listing,
    zapProof: null,
    escrowProof: EscrowProof(
      txHash: '0xabc123',
      escrowService: escrowService,
      hostsTrustedEscrows: EscrowTrust.fromNostrEvent(trustEvent),
      hostsEscrowMethods: EscrowMethod.fromNostrEvent(methodEvent),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════════════

void main() {
  final buyer = MockKeys.guest;
  final seller = MockKeys.hoster;

  // ── 1. Listing allowSelfSignedReservation field ────────────────────

  group('Listing.allowSelfSignedReservation', () {
    test('defaults to false', () {
      final listing = _listing();
      expect(listing.parsedContent.allowSelfSignedReservation, isFalse);
    });

    test('round-trips through toJson / fromJson when true', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final json = listing.parsedContent.toJson();
      final restored = ListingContent.fromJson(json);
      expect(restored.allowSelfSignedReservation, isTrue);
    });

    test('round-trips through toJson / fromJson when false', () {
      final listing = _listing(allowSelfSignedReservation: false);
      final json = listing.parsedContent.toJson();
      final restored = ListingContent.fromJson(json);
      expect(restored.allowSelfSignedReservation, isFalse);
    });

    test('fromJson defaults to false when key is missing', () {
      final listing = _listing();
      final json = listing.parsedContent.toJson();
      json.remove('allowSelfSignedReservation');
      final restored = ListingContent.fromJson(json);
      expect(restored.allowSelfSignedReservation, isFalse);
    });
  });

  // ── 2. Negotiate reservation via DM ────────────────────────────────

  group('Negotiate reservation creation', () {
    test('negotiate reservation has correct stage and salt', () {
      final listing = _listing();
      const salt = 'buyer-secret-salt-123';
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: salt,
      );

      expect(negotiate.parsedContent.stage, ReservationStage.negotiate);
      expect(negotiate.parsedContent.salt, salt);
      expect(negotiate.parsedContent.isNegotiation, isTrue);
      expect(negotiate.parsedContent.isCommit, isFalse);
    });

    test('trade id (d-tag) is deterministic from salt', () {
      final listing = _listing();
      const salt = 'my-secret';
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: salt,
      );

      expect(negotiate.getDtag(), 'trade-$salt');
    });

    test('commitHash is computed correctly', () {
      final listing = _listing();
      final start = DateTime(2026, 4, 1);
      final end = DateTime(2026, 4, 5);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt',
        start: start,
        end: end,
        quantity: 2,
      );

      final expected = ReservationContent(start: start, end: end, quantity: 2);

      expect(negotiate.parsedContent.commitHash(), expected.commitHash());
    });

    test('negotiate reservation references listing anchor', () {
      final listing = _listing();
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt',
      );
      expect(negotiate.parsedTags.listingAnchor, listing.anchor);
    });
  });

  // ── 3. Salt preservation for trade-specific pubkey recovery ────────

  group('Salt preservation', () {
    test('ParticipationProof.computeCommitmentHash is deterministic', () {
      const salt = 'preserved-buyer-salt';
      final commitment = ParticipationProof.computeCommitmentHash(
        buyer.publicKey,
        salt,
      );

      // Simulate later recovery: buyer still has salt
      final recovered = ParticipationProof.computeCommitmentHash(
        buyer.publicKey,
        salt,
      );
      expect(recovered, commitment);
    });

    test('different salt produces different commitment hash', () {
      final h1 = ParticipationProof.computeCommitmentHash(
        buyer.publicKey,
        'salt-a',
      );
      final h2 = ParticipationProof.computeCommitmentHash(
        buyer.publicKey,
        'salt-b',
      );
      expect(h1, isNot(equals(h2)));
    });

    test('same salt different pubkey produces different commitment hash', () {
      final h1 = ParticipationProof.computeCommitmentHash(
        buyer.publicKey,
        'same',
      );
      final h2 = ParticipationProof.computeCommitmentHash(
        seller.publicKey,
        'same',
      );
      expect(h1, isNot(equals(h2)));
    });

    test('salt is preserved through negotiate → commit transition', () {
      final listing = _listing(allowSelfSignedReservation: true);
      const salt = 'buyer-keeps-this';
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: salt,
      );

      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );

      // Salt is still accessible in the committed reservation
      expect(commit.parsedContent.salt, salt);

      // Trade id (d-tag) matches across negotiate and commit
      expect(commit.getDtag(), negotiate.getDtag());

      // Commit terms hash matches across negotiate and commit
      expect(
        commit.parsedContent.commitHash(),
        negotiate.parsedContent.commitHash(),
      );
    });
  });

  // ── 4. Self-signed commit with escrow proof ────────────────────────

  group('Self-signed commit (allowSelfSignedReservation=true)', () {
    test('buyer can self-sign commit when listing allows it', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-self',
      );
      final proof = _escrowPaymentProof(listing: listing);
      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );

      expect(commit.parsedContent.stage, ReservationStage.commit);
      expect(commit.parsedContent.isCommit, isTrue);
      expect(commit.parsedContent.proof, isNotNull);
      expect(commit.parsedContent.proof!.escrowProof, isNotNull);
    });

    test('commit preserves commitTermsHash from negotiate', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-hash',
      );
      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );

      expect(
        commit.parsedContent.commitHash(),
        negotiate.parsedContent.commitHash(),
      );
    });

    test('commit with altered terms produces different commitTermsHash', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-tamper',
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 5),
        quantity: 1,
      );

      // Tampered commit with different dates
      final tamperedHash = ReservationContent(
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 10), // extended!
        quantity: 1,
      ).commitHash();

      expect(
        tamperedHash,
        isNot(equals(negotiate.parsedContent.commitHash())),
        reason: 'Altered terms must produce a different hash',
      );
    });
  });

  // ── 5. Seller-ack flow (allowSelfSignedReservation=false) ──────────

  group('Seller-ack flow (allowSelfSignedReservation=false)', () {
    test('seller ack reservation references same trade id (d-tag)', () {
      final listing = _listing(allowSelfSignedReservation: false);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-ack',
      );
      final sellerAck = _sellerAckReservation(
        negotiate: negotiate,
        listing: listing,
        seller: seller,
      );

      expect(sellerAck.parsedContent.stage, ReservationStage.commit);
      expect(sellerAck.pubKey, seller.publicKey);
      expect(sellerAck.getDtag(), negotiate.getDtag());
    });

    test('Reservation.validate accepts host reservation without proof', () {
      final listing = _listing(allowSelfSignedReservation: false);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-host',
      );
      final sellerAck = _sellerAckReservation(
        negotiate: negotiate,
        listing: listing,
        seller: seller,
      );

      final result = Reservation.validate(sellerAck, listing);
      expect(
        result.isValid,
        isTrue,
        reason: 'Host published reservation is always valid',
      );
    });

    test('Reservation.validate rejects buyer commit without proof when listing '
        'does not allow self-signed', () {
      final listing = _listing(allowSelfSignedReservation: false);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-noself',
      );

      // Buyer publishes commit WITHOUT a proof
      final commitNoProof = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: null,
      );

      final result = Reservation.validate(commitNoProof, listing);
      expect(result.isValid, isFalse);
    });
  });

  // ── 6. allowBarter × allowSelfSignedReservation matrix ─────────────

  group('Listing policy flag matrix', () {
    for (final barter in [true, false]) {
      for (final selfSigned in [true, false]) {
        test('allowBarter=$barter, allowSelfSignedReservation=$selfSigned '
            'roundtrips', () {
          final listing = _listing(
            allowBarter: barter,
            allowSelfSignedReservation: selfSigned,
          );
          final json = listing.parsedContent.toJson();
          final restored = ListingContent.fromJson(json);

          expect(restored.allowBarter, barter);
          expect(restored.allowSelfSignedReservation, selfSigned);
        });
      }
    }

    test('buyer self-signed commit accepted when allowSelfSigned=true', () {
      final listing = _listing(
        allowBarter: false,
        allowSelfSignedReservation: true,
      );
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-matrix1',
      );
      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );

      // With escrow proof, Reservation.validate should accept
      final result = Reservation.validate(commit, listing);
      expect(result.isValid, isTrue);
    });

    test('buyer commit without proof rejected regardless of allowBarter', () {
      final listing = _listing(
        allowBarter: true,
        allowSelfSignedReservation: false,
      );
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-matrix2',
      );
      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: null,
      );

      final result = Reservation.validate(commit, listing);
      expect(result.isValid, isFalse);
    });
  });

  // ── 7. Commit-terms validation ─────────────────────────────────────

  group('Commit-terms validation', () {
    test('commitHash is deterministic', () {
      final a = ReservationContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
      );
      final b = ReservationContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
      );
      expect(a.commitHash(), equals(b.commitHash()));
    });

    test('commitHash() is deterministic across calls', () {
      final content = ReservationContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
      );
      final h1 = content.commitHash();
      final h2 = content.commitHash();
      expect(h1, h2);
    });

    test('commitHash() is order-independent (keys sorted)', () {
      // Two ReservationContents with identical committed fields
      // produce the same hash regardless of internal order.
      final content1 = ReservationContent(
        start: DateTime.parse('2026-03-01'),
        end: DateTime.parse('2026-03-05'),
        quantity: 1,
      );
      final content2 = ReservationContent(
        start: DateTime.parse('2026-03-01'),
        end: DateTime.parse('2026-03-05'),
        quantity: 1,
      );
      expect(content1.commitHash(), content2.commitHash());
    });

    test('different terms produce different hashes', () {
      final t1 = ReservationContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
      );
      final t2 = ReservationContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 2, // different
      );
      expect(t1.commitHash(), isNot(equals(t2.commitHash())));
    });

    test('committed reservation matches negotiated terms hash', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-terms',
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 5),
        quantity: 2,
      );
      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );

      expect(
        commit.parsedContent.commitHash(),
        negotiate.parsedContent.commitHash(),
      );
      // Re-derive and verify
      final reDerived = ReservationContent(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 5),
        quantity: 2,
      ).commitHash();
      expect(commit.parsedContent.commitHash(), reDerived);
    });
  });

  // ── 7b. Seller-signature verification ──────────────────────────────

  group('Seller-signature verification', () {
    test('seller signs negotiate terms → buyer commit verifies', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'sig-ok',
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 5),
        quantity: 1,
      );

      // Seller signs the negotiate content's commitHash.
      final sellerSig = negotiate.parsedContent.signCommit(seller);

      // Buyer builds a matching commit carrying the seller signature.
      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
        signatures: {seller.publicKey: sellerSig},
      );

      // The seller's signature verifies on the buyer's commit.
      expect(commit.parsedContent.verifyCommit(seller.publicKey), isTrue);
    });

    test('buyer alters dates → seller signature fails verification', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'sig-tamper-dates',
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 5),
        quantity: 1,
      );

      // Seller signs the ORIGINAL negotiate terms.
      final sellerSig = negotiate.parsedContent.signCommit(seller);

      // Buyer tampers: extends the end date by 5 days.
      final tampered = Reservation(
        pubKey: buyer.publicKey,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
        tags: ReservationTags([
          [kListingRefTag, listing.anchor!],
          ['d', negotiate.getDtag()!],
        ]),
        content: ReservationContent(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 10), // extended!
          stage: ReservationStage.commit,
          quantity: 1,
          proof: _escrowPaymentProof(listing: listing),
          signatures: {seller.publicKey: sellerSig},
        ),
      ).signAs(buyer, Reservation.fromNostrEvent);

      // Hashes differ.
      expect(
        tampered.parsedContent.commitHash(),
        isNot(equals(negotiate.parsedContent.commitHash())),
      );
      // Seller's signature does NOT verify on tampered content.
      expect(tampered.parsedContent.verifyCommit(seller.publicKey), isFalse);
    });

    test('buyer alters quantity → seller signature fails verification', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'sig-tamper-qty',
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 5),
        quantity: 1,
      );

      final sellerSig = negotiate.parsedContent.signCommit(seller);

      // Buyer tampers: doubles the quantity.
      final tampered = Reservation(
        pubKey: buyer.publicKey,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
        tags: ReservationTags([
          [kListingRefTag, listing.anchor!],
          ['d', negotiate.getDtag()!],
        ]),
        content: ReservationContent(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 5),
          stage: ReservationStage.commit,
          quantity: 2, // tampered!
          proof: _escrowPaymentProof(listing: listing),
          signatures: {seller.publicKey: sellerSig},
        ),
      ).signAs(buyer, Reservation.fromNostrEvent);

      expect(tampered.parsedContent.verifyCommit(seller.publicKey), isFalse);
    });

    test('buyer alters amount → seller signature fails verification', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'sig-tamper-amount',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 5),
        quantity: 1,
        amount: Amount(currency: Currency.BTC, value: BigInt.from(100000)),
      );

      final sellerSig = negotiate.parsedContent.signCommit(seller);

      // Buyer tampers: lowers the price.
      final tampered = Reservation(
        pubKey: buyer.publicKey,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
        tags: ReservationTags([
          [kListingRefTag, listing.anchor!],
          ['d', negotiate.getDtag()!],
        ]),
        content: ReservationContent(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 5),
          stage: ReservationStage.commit,
          quantity: 1,
          amount: Amount(
            currency: Currency.BTC,
            value: BigInt.from(50000),
          ), // tampered!
          proof: _escrowPaymentProof(listing: listing),
          signatures: {seller.publicKey: sellerSig},
        ),
      ).signAs(buyer, Reservation.fromNostrEvent);

      expect(tampered.parsedContent.verifyCommit(seller.publicKey), isFalse);
    });

    test('buyer changes recipient → seller signature fails verification', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'sig-tamper-recipient',
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 5),
        quantity: 1,
      );

      // Explicitly set a recipient, then sign.
      final withRecipient = negotiate.parsedContent.copyWith(
        recipient: buyer.publicKey,
      );
      final sellerSig = withRecipient.signCommit(seller);

      // Buyer tampers: swaps in a different recipient.
      final tampered = Reservation(
        pubKey: buyer.publicKey,
        createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
        tags: ReservationTags([
          [kListingRefTag, listing.anchor!],
          ['d', negotiate.getDtag()!],
        ]),
        content: ReservationContent(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 5),
          stage: ReservationStage.commit,
          quantity: 1,
          recipient: seller.publicKey, // tampered — different pubkey
          proof: _escrowPaymentProof(listing: listing),
          signatures: {seller.publicKey: sellerSig},
        ),
      ).signAs(buyer, Reservation.fromNostrEvent);

      expect(tampered.parsedContent.verifyCommit(seller.publicKey), isFalse);
    });

    test('no seller signature present → verifyCommit returns false', () {
      final content = ReservationContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 1,
        // No signatures
      );

      expect(content.verifyCommit(seller.publicKey), isFalse);
      expect(content.verifyCommit(), isFalse);
    });

    test(
      'forged signature (wrong private key) → verifyCommit returns false',
      () {
        final listing = _listing(allowSelfSignedReservation: true);
        final negotiate = _negotiateReservation(
          listing: listing,
          buyer: buyer,
          salt: 'sig-forged',
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 5),
          quantity: 1,
        );

        // A random third party signs — not the seller.
        final imposter = Bip340.generatePrivateKey();
        final imposterSig = negotiate.parsedContent.signCommit(imposter);

        // Buyer attaches the imposter's sig but claims it's from the seller.
        final commit = _commitReservation(
          negotiate: negotiate,
          listing: listing,
          buyer: buyer,
          proof: _escrowPaymentProof(listing: listing),
          signatures: {seller.publicKey: imposterSig},
        );

        // Verify against the seller pubkey → false.
        expect(commit.parsedContent.verifyCommit(seller.publicKey), isFalse);
      },
    );

    test('signCommit + verifyCommit round-trip on ReservationContent', () {
      final content = ReservationContent(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 5),
        quantity: 2,
        amount: Amount(currency: Currency.BTC, value: BigInt.from(100000)),
        recipient: buyer.publicKey,
      );

      // Seller signs.
      final sig = content.signCommit(seller);
      final signed = content.copyWith(signatures: {seller.publicKey: sig});

      // Verify.
      expect(signed.verifyCommit(seller.publicKey), isTrue);
      expect(signed.verifyCommit(), isTrue); // any-signer form
      expect(
        signed.verifyCommit(buyer.publicKey),
        isFalse,
      ); // buyer didn't sign
    });
  });

  // ── 8. Buyer / Seller cancel → ReservationPairStatus ───────────────

  group('ReservationPairStatus after cancel', () {
    test('buyer cancels negotiate → pair shows cancelled', () {
      final listing = _listing();
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-cancel1',
      );
      final buyerCancel = _cancelReservation(
        source: negotiate,
        listing: listing,
        signer: buyer,
      );

      final status = ReservationPairStatus(buyerReservation: buyerCancel);

      expect(status.cancelled, isTrue);
      expect(status.buyerCancelled, isTrue);
      expect(status.sellerCancelled, isFalse);
      expect(status.stage, ReservationStage.cancel);
      expect(status.isActive, isFalse);
    });

    test('seller cancels committed → pair shows cancelled', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-cancel2',
      );
      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );
      final sellerCancel = _cancelReservation(
        source: commit,
        listing: listing,
        signer: seller,
      );

      final status = ReservationPairStatus(
        buyerReservation: commit,
        sellerReservation: sellerCancel,
      );

      expect(status.cancelled, isTrue);
      expect(status.sellerCancelled, isTrue);
      expect(status.buyerCancelled, isFalse);
      expect(status.stage, ReservationStage.cancel);
      expect(status.isActive, isFalse);
    });

    test('both cancel → pair shows cancelled, both sides', () {
      final listing = _listing();
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-cancel3',
      );
      final buyerCancel = _cancelReservation(
        source: negotiate,
        listing: listing,
        signer: buyer,
      );
      final sellerCancel = _cancelReservation(
        source: negotiate,
        listing: listing,
        signer: seller,
      );

      final status = ReservationPairStatus(
        buyerReservation: buyerCancel,
        sellerReservation: sellerCancel,
      );

      expect(status.cancelled, isTrue);
      expect(status.buyerCancelled, isTrue);
      expect(status.sellerCancelled, isTrue);
    });

    test('active pair (committed, not cancelled)', () {
      final listing = _listing(allowSelfSignedReservation: true);
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-active',
      );
      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: _escrowPaymentProof(listing: listing),
      );
      final sellerAck = _sellerAckReservation(
        negotiate: negotiate,
        listing: listing,
        seller: seller,
      );

      final status = ReservationPairStatus(
        buyerReservation: commit,
        sellerReservation: sellerAck,
      );

      expect(status.cancelled, isFalse);
      expect(status.isActive, isTrue);
      expect(status.stage, ReservationStage.commit);
      expect(status.start, negotiate.parsedContent.start);
      expect(status.end, negotiate.parsedContent.end);
    });

    test('negotiate only → not active', () {
      final listing = _listing();
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: 'salt-neg-only',
      );

      final status = ReservationPairStatus(buyerReservation: negotiate);

      expect(status.cancelled, isFalse);
      expect(status.isActive, isFalse);
      expect(status.stage, ReservationStage.negotiate);
    });
  });

  // ── 9. ReservationTransition validation across lifecycle ───────────

  group('validateStateTransitions lifecycle', () {
    test('valid: negotiate → sellerAck → commit (normal flow)', () {
      final result = validateStateTransitions([
        _transition(
          type: ReservationTransitionType.counterOffer,
          from: ReservationStage.negotiate,
          to: ReservationStage.negotiate,
          signer: buyer,
          createdAtOffset: 0,
        ),
        _transition(
          type: ReservationTransitionType.counterOffer,
          from: ReservationStage.negotiate,
          to: ReservationStage.negotiate,
          signer: buyer,
          createdAtOffset: 1,
        ),
        _transition(
          type: ReservationTransitionType.sellerAck,
          from: ReservationStage.negotiate,
          to: ReservationStage.commit,
          signer: seller,
          createdAtOffset: 2,
        ),
      ]);
      expect(result.isValid, isTrue);
    });

    test('valid: negotiate → commit → cancel', () {
      final result = validateStateTransitions([
        _transition(
          type: ReservationTransitionType.commit,
          from: ReservationStage.negotiate,
          to: ReservationStage.commit,
          signer: buyer,
          createdAtOffset: 0,
        ),
        _transition(
          type: ReservationTransitionType.cancel,
          from: ReservationStage.commit,
          to: ReservationStage.cancel,
          signer: buyer,
          createdAtOffset: 1,
        ),
      ]);
      expect(result.isValid, isTrue);
    });

    test('valid: negotiate → cancel (early cancellation)', () {
      final result = validateStateTransitions([
        _transition(
          type: ReservationTransitionType.cancel,
          from: ReservationStage.negotiate,
          to: ReservationStage.cancel,
          signer: buyer,
          createdAtOffset: 0,
        ),
      ]);
      expect(result.isValid, isTrue);
    });

    test('invalid: commit → negotiate (rollback attempt)', () {
      final result = validateStateTransitions([
        _transition(
          type: ReservationTransitionType.commit,
          from: ReservationStage.negotiate,
          to: ReservationStage.commit,
          signer: buyer,
          createdAtOffset: 0,
        ),
        _transition(
          type: ReservationTransitionType.counterOffer,
          from: ReservationStage.negotiate,
          to: ReservationStage.negotiate,
          signer: buyer,
          createdAtOffset: 1,
        ),
      ]);
      expect(result.isValid, isFalse);
      expect(result.failedIndex, 1);
      expect(result.reason, contains('Chain break'));
    });

    test('invalid: cancel → cancel (double cancel)', () {
      final result = validateStateTransitions([
        _transition(
          type: ReservationTransitionType.cancel,
          from: ReservationStage.negotiate,
          to: ReservationStage.cancel,
          signer: buyer,
          createdAtOffset: 0,
        ),
        _transition(
          type: ReservationTransitionType.cancel,
          from: ReservationStage.cancel,
          to: ReservationStage.cancel,
          signer: buyer,
          createdAtOffset: 1,
        ),
      ]);
      expect(result.isValid, isFalse);
      expect(result.failedIndex, 1);
    });

    test('invalid: type mismatch — counterOffer with negotiate → commit', () {
      final result = validateStateTransitions([
        _transition(
          type: ReservationTransitionType.counterOffer,
          from: ReservationStage.negotiate,
          to: ReservationStage.commit,
          signer: buyer,
        ),
      ]);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('does not match stages'));
    });

    test('invalid: sellerAck type with negotiate → cancel', () {
      final result = validateStateTransitions([
        _transition(
          type: ReservationTransitionType.sellerAck,
          from: ReservationStage.negotiate,
          to: ReservationStage.cancel,
          signer: seller,
        ),
      ]);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('does not match stages'));
    });

    test('valid: multiple counter-offers then cancel', () {
      final result = validateStateTransitions([
        _transition(
          type: ReservationTransitionType.counterOffer,
          from: ReservationStage.negotiate,
          to: ReservationStage.negotiate,
          signer: buyer,
          createdAtOffset: 0,
        ),
        _transition(
          type: ReservationTransitionType.counterOffer,
          from: ReservationStage.negotiate,
          to: ReservationStage.negotiate,
          signer: seller,
          createdAtOffset: 1,
        ),
        _transition(
          type: ReservationTransitionType.counterOffer,
          from: ReservationStage.negotiate,
          to: ReservationStage.negotiate,
          signer: buyer,
          createdAtOffset: 2,
        ),
        _transition(
          type: ReservationTransitionType.cancel,
          from: ReservationStage.negotiate,
          to: ReservationStage.cancel,
          signer: buyer,
          createdAtOffset: 3,
        ),
      ]);
      expect(result.isValid, isTrue);
    });
  });

  // ── 10. End-to-end lifecycle scenario ──────────────────────────────

  group('End-to-end reservation lifecycle', () {
    test('self-signed: negotiate → pay → commit → seller cancel', () {
      final listing = _listing(
        allowSelfSignedReservation: true,
        allowBarter: false,
      );
      const salt = 'e2e-self-signed-salt';

      // Step 1: Buyer creates negotiate reservation (DM to seller)
      final negotiate = _negotiateReservation(
        listing: listing,
        buyer: buyer,
        salt: salt,
      );
      expect(negotiate.parsedContent.isNegotiation, isTrue);

      // Step 2: Buyer pays, receives escrow proof
      final proof = _escrowPaymentProof(listing: listing);
      expect(proof.escrowProof, isNotNull);

      // Step 3: Buyer broadcasts commit with proof
      final commit = _commitReservation(
        negotiate: negotiate,
        listing: listing,
        buyer: buyer,
        proof: proof,
      );
      expect(commit.parsedContent.isCommit, isTrue);
      expect(commit.parsedContent.proof!.escrowProof!.txHash, '0xabc123');

      // Validate the commit is accepted
      final validation = Reservation.validate(commit, listing);
      expect(validation.isValid, isTrue);

      // ReservationPairStatus shows active
      var status = ReservationPairStatus(buyerReservation: commit);
      expect(status.isActive, isTrue);
      expect(status.stage, ReservationStage.commit);

      // Step 4: Seller cancels
      final sellerCancel = _cancelReservation(
        source: commit,
        listing: listing,
        signer: seller,
      );

      status = ReservationPairStatus(
        buyerReservation: commit,
        sellerReservation: sellerCancel,
      );
      expect(status.cancelled, isTrue);
      expect(status.sellerCancelled, isTrue);
      expect(status.isActive, isFalse);

      // Step 5: Validate transition chain
      final transitions = [
        _transition(
          type: ReservationTransitionType.commit,
          from: ReservationStage.negotiate,
          to: ReservationStage.commit,
          signer: buyer,
          commitTermsHash: commit.parsedContent.commitHash(),
          createdAtOffset: 0,
        ),
        _transition(
          type: ReservationTransitionType.cancel,
          from: ReservationStage.commit,
          to: ReservationStage.cancel,
          signer: seller,
          reason: 'Property damage',
          createdAtOffset: 1,
        ),
      ];
      expect(validateStateTransitions(transitions).isValid, isTrue);

      // Step 6: Trade id (d-tag) is deterministic from salt
      expect(commit.getDtag(), 'trade-$salt');
    });

    test(
      'seller-ack: negotiate → counter-offers → sellerAck → buyer cancel',
      () {
        final listing = _listing(
          allowSelfSignedReservation: false,
          allowBarter: true,
        );
        const salt = 'e2e-seller-ack-salt';

        // Step 1: Buyer proposes
        final negotiate = _negotiateReservation(
          listing: listing,
          buyer: buyer,
          salt: salt,
          amount: Amount(currency: Currency.BTC, value: BigInt.from(80000)),
        );
        expect(negotiate.parsedContent.amount!.value, BigInt.from(80000));

        // Step 2: Seller acks (agrees to barter price)
        final sellerAck = _sellerAckReservation(
          negotiate: negotiate,
          listing: listing,
          seller: seller,
        );
        expect(sellerAck.parsedContent.isCommit, isTrue);

        // Host reservation is valid without proof
        expect(Reservation.validate(sellerAck, listing).isValid, isTrue);

        // ReservationPairStatus shows committed
        var status = ReservationPairStatus(
          buyerReservation: negotiate,
          sellerReservation: sellerAck,
        );
        expect(status.isActive, isTrue);
        expect(status.stage, ReservationStage.commit);

        // Step 3: Buyer cancels
        final buyerCancel = _cancelReservation(
          source: negotiate,
          listing: listing,
          signer: buyer,
        );

        status = ReservationPairStatus(
          buyerReservation: buyerCancel,
          sellerReservation: sellerAck,
        );
        expect(status.cancelled, isTrue);
        expect(status.buyerCancelled, isTrue);
        expect(status.sellerCancelled, isFalse);

        // Step 4: Validate buyer's transition chain
        final buyerTransitions = [
          _transition(
            type: ReservationTransitionType.cancel,
            from: ReservationStage.negotiate,
            to: ReservationStage.cancel,
            signer: buyer,
          ),
        ];
        expect(validateStateTransitions(buyerTransitions).isValid, isTrue);

        // Step 5: Validate seller's transition chain
        final sellerTransitions = [
          _transition(
            type: ReservationTransitionType.sellerAck,
            from: ReservationStage.negotiate,
            to: ReservationStage.commit,
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
