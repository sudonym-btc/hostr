@Tags(['unit'])
library;

import 'package:crypto/crypto.dart' show sha256;
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

void main() {
  group('ReservationPubkeyProofTag', () {
    test('round-trips to raw Nostr tag shape', () {
      final recipientPubkey = 'r' * 64;
      final proof = ReservationPubkeyProofTag(
        role: 'buyer',
        recipientPubkey: recipientPubkey,
        scheme: kReservationPubkeyProofSchemeNip44V1,
        ciphertext: 'ciphertext',
      );

      expect(proof.toTag(), [
        kReservationPubkeyProofTag,
        'buyer',
        recipientPubkey,
        kReservationPubkeyProofSchemeNip44V1,
        'ciphertext',
      ]);
      expect(
        ReservationPubkeyProofTag.tryFromTag(proof.toTag())!.ciphertext,
        'ciphertext',
      );
    });

    test('ignores malformed or unrelated tags', () {
      expect(ReservationPubkeyProofTag.tryFromTag(const []), isNull);
      expect(
        ReservationPubkeyProofTag.tryFromTag(const [
          kReservationPubkeyProofTag,
          'buyer',
          'recipient',
        ]),
        isNull,
      );
      expect(
        ReservationPubkeyProofTag.tryFromTag(const ['p', 'pubkey']),
        isNull,
      );
    });
  });

  group('ReservationPubkeyProofPayload', () {
    test('uses bytes32 trade ids directly', () {
      final tradeId = 'A' * 64;

      expect(
        ReservationPubkeyProofPayload.messageForTradeId(tradeId),
        'a' * 64,
      );
    });

    test('hashes non-bytes32 trade ids', () {
      expect(
        ReservationPubkeyProofPayload.messageForTradeId('trade-123'),
        sha256.convert('trade-123'.codeUnits).toString(),
      );
    });

    test('signs, encodes, decodes, and verifies for the trade id', () {
      final proof = ReservationPubkeyProofPayload.sign(
        tradeId: 'trade-123',
        keyPair: MockKeys.guest,
      );
      final decoded = ReservationPubkeyProofPayload.tryDecode(proof.encode());

      expect(decoded, isNotNull);
      expect(decoded!.pubkey, MockKeys.guest.publicKey);
      expect(decoded.verifiesForTradeId('trade-123'), isTrue);
      expect(decoded.verifiesForTradeId('trade-456'), isFalse);
    });

    test('rejects unknown payload versions and malformed payloads', () {
      expect(ReservationPubkeyProofPayload.tryDecode(''), isNull);
      expect(
        ReservationPubkeyProofPayload.tryDecode(
          'v2:${MockKeys.guest.publicKey}:sig',
        ),
        isNull,
      );
      expect(
        ReservationPubkeyProofPayload.tryDecode('v1:only-two-parts'),
        isNull,
      );
    });
  });

  group('Reservation pubkey proof tags', () {
    test('Reservation.create preserves and parses pubkey proof tags', () {
      final recipientPubkey = 'r' * 64;
      final proof = ReservationPubkeyProofTag(
        role: 'buyer',
        recipientPubkey: recipientPubkey,
        scheme: kReservationPubkeyProofSchemeNip44V1,
        ciphertext: 'ciphertext',
      );

      final reservation = Reservation.create(
        pubKey: MockKeys.guest.publicKey,
        dTag: 'trade-123',
        listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
        pubkeyProofs: [proof],
      );

      expect(reservation.parsedTags.pubkeyProofs, hasLength(1));
      expect(
        reservation.parsedTags
            .pubkeyProofsFor(role: 'buyer', recipientPubkey: recipientPubkey)
            .single
            .ciphertext,
        'ciphertext',
      );
    });

    test('copy can clear stale signature while adding tags', () {
      final signed = Reservation.create(
        pubKey: MockKeys.guest.publicKey,
        dTag: 'trade-123',
        listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
      ).signAs(MockKeys.guest, Reservation.fromNostrEvent);

      final copied = signed.copy(
        id: null,
        sig: null,
        tags: ReservationTags([
          ...signed.parsedTags.tags,
          const ReservationPubkeyProofTag(
            role: 'buyer',
            recipientPubkey: 'r',
            scheme: kReservationPubkeyProofSchemeNip44V1,
            ciphertext: 'ciphertext',
          ).toTag(),
        ]),
      );

      expect(copied.sig, isNull);
      expect(copied.parsedTags.pubkeyProofs, hasLength(1));
    });
  });
}
