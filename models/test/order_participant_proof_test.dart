@Tags(['unit'])
library;

import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

void main() {
  group('OrderParticipantProofTag', () {
    test('round-trips to raw Nostr tag shape with payload hash', () {
      final recipientPubkey = 'r' * 64;
      final payloadHash = OrderParticipantProofTag.hashPayload(
        'plaintext',
      );
      final proof = OrderParticipantProofTag(
        role: 'buyer',
        participantPubkey: MockKeys.reviewer.publicKey,
        recipientPubkey: recipientPubkey,
        scheme: kOrderParticipantProofSchemeNip44,
        payloadHash: payloadHash,
        payload: 'ciphertext',
      );

      expect(proof.toTag(), [
        kOrderParticipantProofTag,
        'buyer',
        MockKeys.reviewer.publicKey,
        recipientPubkey,
        kOrderParticipantProofSchemeNip44,
        payloadHash,
        'ciphertext',
      ]);
      final parsed = OrderParticipantProofTag.tryFromTag(proof.toTag());
      expect(parsed?.payload, 'ciphertext');
      expect(parsed?.payloadHash, payloadHash);
      expect(parsed?.matchesPayload('plaintext'), isTrue);
      expect(parsed?.matchesPayload('other'), isFalse);
    });

    test('ignores malformed or unrelated tags', () {
      expect(OrderParticipantProofTag.tryFromTag(const []), isNull);
      expect(
        OrderParticipantProofTag.tryFromTag(const [
          kOrderParticipantProofTag,
          'buyer',
          'participant',
        ]),
        isNull,
      );
      expect(
        OrderParticipantProofTag.tryFromTag(const ['p', 'pubkey']),
        isNull,
      );
    });
  });

  group('OrderParticipantAuthorizationPayload', () {
    test('encodes, decodes, and verifies a signed authorization event', () {
      final authorization = TradeKeyAuthorization.create(
        identityPubkey: MockKeys.guest.publicKey,
        listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
        tradeId: 'trade-123',
        participantPubkey: 'alias-pubkey',
        role: 'buyer',
      ).signAs(MockKeys.guest, TradeKeyAuthorization.fromNostrEvent);
      final payload =
          OrderParticipantAuthorizationPayload.fromAuthorizationEvent(
        authorization,
      );
      final decoded = OrderParticipantAuthorizationPayload.tryDecode(
        payload.encode(),
      );

      expect(decoded, isNotNull);
      expect(decoded!.pubkey, MockKeys.guest.publicKey);
      expect(
        decoded.verifiesForOrder(
          tradeId: 'trade-123',
          listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
          participantPubkey: 'alias-pubkey',
          role: 'buyer',
        ),
        isTrue,
      );
      expect(
        decoded.verifiesForOrder(
          tradeId: 'trade-456',
          listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
          participantPubkey: 'alias-pubkey',
          role: 'buyer',
        ),
        isFalse,
      );
    });

    test('rejects malformed payloads and wrong event kinds', () {
      expect(OrderParticipantAuthorizationPayload.tryDecode(''), isNull);
      expect(
        OrderParticipantAuthorizationPayload.tryDecode('{}'),
        isNull,
      );
      expect(
        OrderParticipantAuthorizationPayload.tryDecode(
          '{"kind":1,"pubkey":"${MockKeys.guest.publicKey}","tags":[],"content":"","id":"id","sig":"sig"}',
        ),
        isNull,
      );
    });
  });

  group('Order participant proof tags', () {
    test('Order.create preserves and parses participant proof tags', () {
      final proof = OrderParticipantProofTag(
        role: 'buyer',
        participantPubkey: MockKeys.reviewer.publicKey,
        recipientPubkey: MockKeys.hoster.publicKey,
        scheme: kOrderParticipantProofSchemeNip44,
        payloadHash: OrderParticipantProofTag.hashPayload('plaintext'),
        payload: 'ciphertext',
      );

      final order = Order.create(
        pubKey: MockKeys.guest.publicKey,
        dTag: 'trade-123',
        listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
        extraTags: [proof.toTag()],
      );

      expect(order.parsedTags.participantProofs, hasLength(1));
      expect(order.parsedTags.participantProofs.single.payload, 'ciphertext');
    });
  });
}
