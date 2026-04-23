@Tags(['unit'])
library;

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
    test('encodes, decodes, and verifies a signed authorization event', () {
      final authorization = TradeKeyAuthorization.create(
        identityPubkey: MockKeys.guest.publicKey,
        listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
        tradeId: 'trade-123',
        participantPubkey: 'alias-pubkey',
        role: 'buyer',
      ).signAs(MockKeys.guest, TradeKeyAuthorization.fromNostrEvent);
      final payload = ReservationPubkeyProofPayload.fromAuthorizationEvent(
        authorization,
      );
      final decoded = ReservationPubkeyProofPayload.tryDecode(payload.encode());

      expect(decoded, isNotNull);
      expect(decoded!.pubkey, MockKeys.guest.publicKey);
      expect(
        decoded.verifiesForReservation(
          tradeId: 'trade-123',
          listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
          participantPubkey: 'alias-pubkey',
          role: 'buyer',
        ),
        isTrue,
      );
      expect(
        decoded.verifiesForReservation(
          tradeId: 'trade-456',
          listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
          participantPubkey: 'alias-pubkey',
          role: 'buyer',
        ),
        isFalse,
      );
    });

    test('rejects malformed payloads and wrong event kinds', () {
      expect(ReservationPubkeyProofPayload.tryDecode(''), isNull);
      expect(
        ReservationPubkeyProofPayload.tryDecode('{}'),
        isNull,
      );
      expect(
        ReservationPubkeyProofPayload.tryDecode(
          '{"kind":1,"pubkey":"${MockKeys.guest.publicKey}","tags":[],"content":"","id":"id","sig":"sig"}',
        ),
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
