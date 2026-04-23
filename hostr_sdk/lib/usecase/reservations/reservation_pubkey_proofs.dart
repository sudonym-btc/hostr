import 'dart:convert' show utf8;

import 'package:convert/convert.dart' as convert;
import 'package:crypto/crypto.dart' as crypto;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../util/coinlib_gift_wrap.dart';

typedef ReservationPubkeyProofEncryptor =
    Future<String> Function(
      String plaintext,
      String senderPrivateKey,
      String recipientPubkey,
    );

typedef ReservationPubkeyProofDecryptor =
    Future<String> Function(
      String ciphertext,
      String recipientPrivateKey,
      String senderPubkey,
    );

typedef ReservationPubkeyProofEventSigner =
    Future<Nip01Event> Function(TradeKeyAuthorization unsignedEvent);

String _reviewRevealScope({
  required Reservation reservation,
  required String role,
}) {
  final tradeId = reservation.getDtag();
  if (tradeId == null || tradeId.isEmpty) {
    throw StateError('Cannot derive review reveal key without trade id');
  }
  return 'review-reveal/v1/$role/${reservation.parsedTags.listingAnchor}/$tradeId';
}

KeyPair deriveReviewRevealKeyPair({
  required Reservation reservation,
  required KeyPair reservationAuthorKeyPair,
  required String role,
}) {
  final authorPrivateKey = reservationAuthorKeyPair.privateKey;
  if (authorPrivateKey == null || authorPrivateKey.isEmpty) {
    throw StateError('Private key is required to derive review reveal key');
  }
  final digest = crypto.sha256.convert(
    <int>[
      ...utf8.encode(_reviewRevealScope(reservation: reservation, role: role)),
      ...convert.hex.decode(authorPrivateKey),
    ],
  );
  return Bip340.fromPrivateKey(convert.hex.encode(digest.bytes));
}

extension ReservationPubkeyProofAttachment on Reservation {
  String pubkeyForRole(String role) {
    switch (role) {
      case 'buyer':
        return parsedTags.getTagValueByMarker('p', 'buyer') ??
            recipient ??
            pubKey;
      case 'seller':
        return parsedTags.getTagValueByMarker('p', 'seller') ??
            getPubKeyFromAnchor(parsedTags.listingAnchor);
      default:
        throw UnsupportedError('No participant pubkey mapping for role: $role');
    }
  }

  /// Attaches encrypted proof that [proofKeyPair.publicKey] controls this
  /// reservation's trade id for [role].
  ///
  /// The encryption sender key must be the reservation author key because
  /// NIP-44 recipients decrypt with the event author pubkey as sender context.
  /// For buyer reservations that hide the real identity, [proofKeyPair] is the
  /// real buyer key and [encryptionKeyPair] is the disposable reservation key.
  Future<Reservation> attachPubkeyProof({
    required String role,
    required KeyPair proofKeyPair,
    required KeyPair encryptionKeyPair,
    Iterable<String>? recipientPubkeys,
    ReservationPubkeyProofEncryptor? encrypt,
    ReservationPubkeyProofEventSigner? signAuthorization,
  }) async {
    if (encryptionKeyPair.publicKey != pubKey) {
      throw StateError(
        'Pubkey proof encryption key must match reservation author pubkey',
      );
    }

    final senderPrivateKey = encryptionKeyPair.privateKey;
    if (senderPrivateKey == null || senderPrivateKey.isEmpty) {
      throw StateError('Private key is required to encrypt pubkey proof');
    }

    final tradeId = getDtag();
    if (tradeId == null || tradeId.isEmpty) {
      throw StateError('Cannot attach pubkey proof without trade id');
    }
    final participantPubkey = pubkeyForRole(role);

    final recipients = (recipientPubkeys ?? pubkeyProofRecipientsFor(role))
        .where((pubkey) => pubkey.isNotEmpty)
        .toSet();
    recipients.add(
      deriveReviewRevealKeyPair(
        reservation: this,
        reservationAuthorKeyPair: encryptionKeyPair,
        role: role,
      ).publicKey,
    );
    if (recipients.isEmpty) {
      throw StateError('No recipients available for $role pubkey proof');
    }

    final unsignedAuthorization = TradeKeyAuthorization.create(
      identityPubkey: proofKeyPair.publicKey,
      listingAnchor: parsedTags.listingAnchor,
      tradeId: tradeId,
      participantPubkey: participantPubkey,
      role: role,
    );
    final signedAuthorization = signAuthorization != null
        ? TradeKeyAuthorization.fromNostrEvent(
            await signAuthorization(unsignedAuthorization),
          )
        : unsignedAuthorization.signAs(
            proofKeyPair,
            TradeKeyAuthorization.fromNostrEvent,
          );
    final payload = ReservationPubkeyProofPayload.fromAuthorizationEvent(
      signedAuthorization,
    ).encode();
    final encryptFn = encrypt ?? coinlibEncryptNip44;
    final proofTags = <ReservationPubkeyProofTag>[];

    for (final recipient in recipients) {
      proofTags.add(
        ReservationPubkeyProofTag(
          role: role,
          recipientPubkey: recipient,
          scheme: kReservationPubkeyProofSchemeNip44V1,
          ciphertext: await encryptFn(payload, senderPrivateKey, recipient),
        ),
      );
    }

    return copy(
      id: null,
      sig: null,
      tags: ReservationTags([
        ...parsedTags.tags.where((tag) {
          final existing = ReservationPubkeyProofTag.tryFromTag(tag);
          if (existing == null) return true;
          return existing.role != role ||
              !recipients.contains(existing.recipientPubkey);
        }),
        for (final proof in proofTags) proof.toTag(),
      ]),
    );
  }

  /// Infers the default proof recipients for a participant [role].
  ///
  /// Buyer proofs are encrypted to the seller and escrow. Seller proofs are
  /// prepared for the buyer alias and escrow so the same mechanism can expand
  /// later without changing the tag format.
  Set<String> pubkeyProofRecipientsFor(String role) {
    final recipients = <String>{};
    final sellerPubkey = getPubKeyFromAnchor(parsedTags.listingAnchor);
    final escrowPubkey =
        proof?.escrowProof?.escrowService.escrowPubkey ??
        parsedTags.getTagValueByMarker('p', 'escrow');

    switch (role) {
      case 'buyer':
        recipients.add(sellerPubkey);
        if (escrowPubkey != null) recipients.add(escrowPubkey);
        break;
      case 'seller':
        final buyerPubkey = parsedTags.getTagValueByMarker('p', 'buyer');
        if (buyerPubkey != null) recipients.add(buyerPubkey);
        if (escrowPubkey != null) recipients.add(escrowPubkey);
        break;
      default:
        throw UnsupportedError(
          'No default pubkey proof recipients for role: $role',
        );
    }

    return recipients..removeWhere((pubkey) => pubkey.isEmpty);
  }
}

extension ReservationPubkeyProofResolution on Reservation {
  /// Decrypts and verifies the first valid pubkey proof for [role] addressed
  /// to [recipientKeyPair].
  Future<ReservationPubkeyProofPayload?> resolvePubkeyProof({
    required String role,
    required KeyPair recipientKeyPair,
    ReservationPubkeyProofDecryptor? decrypt,
  }) async {
    final recipientPrivateKey = recipientKeyPair.privateKey;
    if (recipientPrivateKey == null || recipientPrivateKey.isEmpty) {
      throw StateError('Private key is required to decrypt pubkey proof');
    }

    final tradeId = getDtag();
    if (tradeId == null || tradeId.isEmpty) return null;

    final decryptFn = decrypt ?? coinlibDecryptNip44;
    final participantPubkey = pubkeyForRole(role);
    final proofTags = parsedTags.pubkeyProofsFor(
      role: role,
      recipientPubkey: recipientKeyPair.publicKey,
    );

    for (final tag in proofTags) {
      if (tag.scheme != kReservationPubkeyProofSchemeNip44V1) continue;

      try {
        final plaintext = await decryptFn(
          tag.ciphertext,
          recipientPrivateKey,
          pubKey,
        );
        final proof = ReservationPubkeyProofPayload.tryDecode(plaintext);
        if (proof != null &&
            proof.verifiesForReservation(
              tradeId: tradeId,
              listingAnchor: parsedTags.listingAnchor,
              participantPubkey: participantPubkey,
              role: role,
            )) {
          return proof;
        }
      } catch (_) {
        // Try the next capsule; relays can contain stale or malformed tags.
      }
    }

    return null;
  }
}
