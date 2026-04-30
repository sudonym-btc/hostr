@Tags(['unit'])
library;

import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

void main() {
  group('ReservationParticipantProofTag', () {
    test('round-trips to raw Nostr tag shape with payload hash', () {
      final recipientPubkey = 'r' * 64;
      final payloadHash = ReservationParticipantProofTag.hashPayload(
        'plaintext',
      );
      final proof = ReservationParticipantProofTag(
        role: 'buyer',
        participantPubkey: MockKeys.reviewer.publicKey,
        recipientPubkey: recipientPubkey,
        scheme: kReservationParticipantProofSchemeNip44,
        payloadHash: payloadHash,
        payload: 'ciphertext',
      );

      expect(proof.toTag(), [
        kReservationParticipantProofTag,
        'buyer',
        MockKeys.reviewer.publicKey,
        recipientPubkey,
        kReservationParticipantProofSchemeNip44,
        payloadHash,
        'ciphertext',
      ]);
      final parsed = ReservationParticipantProofTag.tryFromTag(proof.toTag());
      expect(parsed?.payload, 'ciphertext');
      expect(parsed?.payloadHash, payloadHash);
      expect(parsed?.matchesPayload('plaintext'), isTrue);
      expect(parsed?.matchesPayload('other'), isFalse);
    });

    test('ignores malformed or unrelated tags', () {
      expect(ReservationParticipantProofTag.tryFromTag(const []), isNull);
      expect(
        ReservationParticipantProofTag.tryFromTag(const [
          kReservationParticipantProofTag,
          'buyer',
          'participant',
        ]),
        isNull,
      );
      expect(
        ReservationParticipantProofTag.tryFromTag(const ['p', 'pubkey']),
        isNull,
      );
    });
  });

  group('ReservationParticipantAuthorizationPayload', () {
    test('encodes, decodes, and verifies a signed authorization event', () {
      final authorization = TradeKeyAuthorization.create(
        identityPubkey: MockKeys.guest.publicKey,
        listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
        tradeId: 'trade-123',
        participantPubkey: 'alias-pubkey',
        role: 'buyer',
      ).signAs(MockKeys.guest, TradeKeyAuthorization.fromNostrEvent);
      final payload =
          ReservationParticipantAuthorizationPayload.fromAuthorizationEvent(
        authorization,
      );
      final decoded = ReservationParticipantAuthorizationPayload.tryDecode(
        payload.encode(),
      );

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
      expect(ReservationParticipantAuthorizationPayload.tryDecode(''), isNull);
      expect(
        ReservationParticipantAuthorizationPayload.tryDecode('{}'),
        isNull,
      );
      expect(
        ReservationParticipantAuthorizationPayload.tryDecode(
          '{"kind":1,"pubkey":"${MockKeys.guest.publicKey}","tags":[],"content":"","id":"id","sig":"sig"}',
        ),
        isNull,
      );
    });
  });

  group('Reservation participant proof tags', () {
    test('Reservation.create preserves and parses participant proof tags', () {
      final proof = ReservationParticipantProofTag(
        role: 'buyer',
        participantPubkey: MockKeys.reviewer.publicKey,
        recipientPubkey: MockKeys.hoster.publicKey,
        scheme: kReservationParticipantProofSchemeNip44,
        payloadHash: ReservationParticipantProofTag.hashPayload('plaintext'),
        payload: 'ciphertext',
      );

      final reservation = Reservation.create(
        pubKey: MockKeys.guest.publicKey,
        dTag: 'trade-123',
        listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
        extraTags: [proof.toTag()],
      );

      expect(reservation.parsedTags.participantProofs, hasLength(1));
      expect(reservation.parsedTags.participantProofs.single.payload,
          'ciphertext');
    });
  });
}
