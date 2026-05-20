@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/orders/order_participant_tags.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _EncryptCall {
  final String plaintext;
  final String senderPrivateKey;
  final String recipientPubkey;

  const _EncryptCall({
    required this.plaintext,
    required this.senderPrivateKey,
    required this.recipientPubkey,
  });
}

void main() {
  group('buildOrderParticipantTagPlan', () {
    late List<OrderParticipantAuthorizationDraft> signCalls;
    late List<_EncryptCall> encryptCalls;

    Future<String> sign(OrderParticipantAuthorizationDraft draft) async {
      signCalls.add(draft);
      return 'signed:${draft.role}:${draft.identityPubkey}:${draft.participantPubkey}:${draft.tradeId}';
    }

    Future<String> encrypt({
      required String plaintext,
      required String senderPrivateKey,
      required String recipientPubkey,
    }) async {
      encryptCalls.add(
        _EncryptCall(
          plaintext: plaintext,
          senderPrivateKey: senderPrivateKey,
          recipientPubkey: recipientPubkey,
        ),
      );
      return 'encrypted:$recipientPubkey:$plaintext';
    }

    setUp(() {
      signCalls = [];
      encryptCalls = [];
    });

    test(
      'emits role-marked p tags and no proofs for real participants',
      () async {
        final plan = await buildOrderParticipantTagPlan(
          tradeId: 'trade-1',
          orderAuthorKey: MockKeys.guest,
          participants: [
            OrderParticipant.real(
              role: 'buyer',
              pubkey: MockKeys.guest.publicKey,
            ),
            OrderParticipant.real(
              role: 'seller',
              pubkey: MockKeys.hoster.publicKey,
            ),
          ],
          signAuthorization: sign,
          encryptAuthorization: encrypt,
        );

        expect(plan.pTags, [
          ['p', MockKeys.guest.publicKey, '', 'buyer'],
          ['p', MockKeys.hoster.publicKey, '', 'seller'],
        ]);
        expect(plan.proofTags, isEmpty);
        expect(plan.tags, plan.pTags);
        expect(signCalls, isEmpty);
        expect(encryptCalls, isEmpty);
      },
    );

    test('signs once for an aliased participant and encrypts to everyone', () async {
      final tempBuyer = mockKeys[20];
      final plan = await buildOrderParticipantTagPlan(
        tradeId: 'trade-2',
        orderAuthorKey: tempBuyer,
        participants: [
          OrderParticipant(
            role: 'buyer',
            participantPubkey: tempBuyer.publicKey,
            identityPubkey: MockKeys.guest.publicKey,
          ),
          OrderParticipant.real(
            role: 'seller',
            pubkey: MockKeys.hoster.publicKey,
          ),
          OrderParticipant.real(
            role: 'escrow',
            pubkey: MockKeys.escrow.publicKey,
          ),
        ],
        signAuthorization: sign,
        encryptAuthorization: encrypt,
      );

      expect(signCalls, hasLength(1));
      expect(signCalls.single.tradeId, 'trade-2');
      expect(signCalls.single.role, 'buyer');
      expect(signCalls.single.identityPubkey, MockKeys.guest.publicKey);
      expect(signCalls.single.participantPubkey, tempBuyer.publicKey);

      expect(encryptCalls, hasLength(3));
      expect(encryptCalls.map((call) => call.recipientPubkey).toSet(), {
        tempBuyer.publicKey,
        MockKeys.hoster.publicKey,
        MockKeys.escrow.publicKey,
      });
      expect(encryptCalls.map((call) => call.plaintext).toSet(), {
        'signed:buyer:${MockKeys.guest.publicKey}:${tempBuyer.publicKey}:trade-2',
      });
      expect(
        encryptCalls.every(
          (call) => call.senderPrivateKey == tempBuyer.privateKey,
        ),
        isTrue,
      );

      expect(plan.proofTags, hasLength(3));
      for (final proof in plan.proofTags) {
        expect(proof.role, 'buyer');
        expect(proof.participantPubkey, tempBuyer.publicKey);
        expect(proof.scheme, kOrderParticipantProofSchemeNip44);
        expect(
          proof.payloadHash,
          OrderParticipantProofTag.hashPayload(
            'signed:buyer:${MockKeys.guest.publicKey}:${tempBuyer.publicKey}:trade-2',
          ),
        );
        expect(
          proof.payload,
          'encrypted:${proof.recipientPubkey}:signed:buyer:${MockKeys.guest.publicKey}:${tempBuyer.publicKey}:trade-2',
        );
      }
    });

    test('does not emit a proof for a real pubkey participant', () async {
      final tempBuyer = mockKeys[21];
      final plan = await buildOrderParticipantTagPlan(
        tradeId: 'trade-3',
        orderAuthorKey: tempBuyer,
        participants: [
          OrderParticipant(
            role: 'buyer',
            participantPubkey: tempBuyer.publicKey,
            identityPubkey: MockKeys.guest.publicKey,
          ),
          OrderParticipant.real(
            role: 'seller',
            pubkey: MockKeys.hoster.publicKey,
          ),
        ],
        signAuthorization: sign,
        encryptAuthorization: encrypt,
      );

      expect(signCalls, hasLength(1));
      expect(plan.proofTags.map((proof) => proof.role).toSet(), {'buyer'});
      expect(
        plan.proofTags.any(
          (proof) => proof.participantPubkey == MockKeys.hoster.publicKey,
        ),
        isFalse,
      );
    });

    test('uses relay hints when building p tags', () async {
      final plan = await buildOrderParticipantTagPlan(
        tradeId: 'trade-4',
        orderAuthorKey: MockKeys.guest,
        participants: [
          OrderParticipant.real(
            role: 'buyer',
            pubkey: MockKeys.guest.publicKey,
          ),
        ],
        relayHintFor: (pubkey) async => 'wss://relay.example/$pubkey',
        signAuthorization: sign,
        encryptAuthorization: encrypt,
      );

      expect(plan.pTags, [
        [
          'p',
          MockKeys.guest.publicKey,
          'wss://relay.example/${MockKeys.guest.publicKey}',
          'buyer',
        ],
      ]);
    });

    test(
      'throws when an alias needs encryption but author has no private key',
      () {
        final publicOnlyAuthor = KeyPair(
          null,
          mockKeys[22].publicKey,
          null,
          null,
        );

        expect(
          () => buildOrderParticipantTagPlan(
            tradeId: 'trade-5',
            orderAuthorKey: publicOnlyAuthor,
            participants: [
              OrderParticipant(
                role: 'buyer',
                participantPubkey: publicOnlyAuthor.publicKey,
                identityPubkey: MockKeys.guest.publicKey,
              ),
            ],
            signAuthorization: sign,
            encryptAuthorization: encrypt,
          ),
          throwsStateError,
        );
      },
    );

    test('parses participant proof tags from order tags', () async {
      final tempBuyer = mockKeys[23];
      final plan = await buildOrderParticipantTagPlan(
        tradeId: 'trade-6',
        orderAuthorKey: tempBuyer,
        participants: [
          OrderParticipant(
            role: 'buyer',
            participantPubkey: tempBuyer.publicKey,
            identityPubkey: MockKeys.guest.publicKey,
          ),
          OrderParticipant.real(
            role: 'seller',
            pubkey: MockKeys.hoster.publicKey,
          ),
        ],
        signAuthorization: sign,
        encryptAuthorization: encrypt,
      );

      final order = Order.create(
        pubKey: tempBuyer.publicKey,
        dTag: 'trade-6',
        listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
        extraTags: plan.tags,
      );

      expect(order.parsedTags.participantProofs, hasLength(2));
      expect(
        order.parsedTags.participantProofs
            .map((proof) => proof.toTag())
            .toSet(),
        plan.proofTags.map((proof) => proof.toTag()).toSet(),
      );
      final proofMap = orderParticipantProofsByPubkey(order);
      expect(proofMap.keys, {tempBuyer.publicKey});
      expect(
        proofMap[tempBuyer.publicKey]!.map((proof) => proof.toTag()).toSet(),
        plan.proofTags.map((proof) => proof.toTag()).toSet(),
      );
    });

    test('maps participant proofs across order groups', () async {
      final tempBuyer = mockKeys[25];
      final buyerProof = OrderParticipantProofTag(
        role: 'buyer',
        participantPubkey: tempBuyer.publicKey,
        recipientPubkey: MockKeys.hoster.publicKey,
        scheme: kOrderParticipantProofSchemeNip44,
        payloadHash: OrderParticipantProofTag.hashPayload('buyer-proof'),
        payload: 'buyer-proof',
      );
      final escrowProof = OrderParticipantProofTag(
        role: 'escrow',
        participantPubkey: MockKeys.escrow.publicKey,
        recipientPubkey: MockKeys.hoster.publicKey,
        scheme: kOrderParticipantProofSchemeNip44,
        payloadHash: OrderParticipantProofTag.hashPayload('escrow-proof'),
        payload: 'escrow-proof',
      );
      final hostOrder = Order.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'trade-proof-map',
        listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
        extraTags: [
          ['p', tempBuyer.publicKey, '', 'buyer'],
          ['p', MockKeys.escrow.publicKey, '', 'escrow'],
          buyerProof.toTag(),
        ],
      );
      final escrowOrder = Order.create(
        pubKey: MockKeys.escrow.publicKey,
        dTag: 'trade-proof-map',
        listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
        extraTags: [
          ['p', tempBuyer.publicKey, '', 'buyer'],
          ['p', MockKeys.hoster.publicKey, '', 'seller'],
          escrowProof.toTag(),
        ],
      );

      final group = OrderGroup(orders: [hostOrder, escrowOrder]);

      final proofMap = orderGroupParticipantProofsByPubkey(group);
      expect(proofMap.keys, {tempBuyer.publicKey, MockKeys.escrow.publicKey});
      expect(proofMap[tempBuyer.publicKey]!.map((proof) => proof.toTag()), [
        buyerProof.toTag(),
      ]);
      expect(
        proofMap[MockKeys.escrow.publicKey]!.map((proof) => proof.toTag()),
        [escrowProof.toTag()],
      );
      expect(orderGroupHasParticipantProof(group, tempBuyer.publicKey), isTrue);
      expect(
        orderGroupHasParticipantProof(group, MockKeys.guest.publicKey),
        isFalse,
      );
    });

    test(
      'resolved hidden participants derive the same id as the unhidden thread',
      () async {
        final tempBuyer = mockKeys[24];
        const tradeId = 'trade-hidden-participant';
        final plan = await buildOrderParticipantTagPlan(
          tradeId: tradeId,
          orderAuthorKey: tempBuyer,
          participants: [
            OrderParticipant(
              role: 'buyer',
              participantPubkey: tempBuyer.publicKey,
              identityPubkey: MockKeys.guest.publicKey,
            ),
            OrderParticipant.real(
              role: 'seller',
              pubkey: MockKeys.hoster.publicKey,
            ),
            OrderParticipant.real(
              role: 'escrow',
              pubkey: MockKeys.escrow.publicKey,
            ),
          ],
          signAuthorization: sign,
          encryptAuthorization: encrypt,
        );

        final order = Order.create(
          pubKey: tempBuyer.publicKey,
          dTag: tradeId,
          listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
          extraTags: plan.tags,
        );

        final unhiddenParticipants = {
          MockKeys.guest.publicKey,
          MockKeys.hoster.publicKey,
          MockKeys.escrow.publicKey,
        };
        final rawGroupId = rawOrderGroupId(order);
        final unhiddenThreadId = Threads.conversationId(
          tradeId,
          unhiddenParticipants,
        );

        expect(rawOrderParticipantSet(order), {
          tempBuyer.publicKey,
          MockKeys.hoster.publicKey,
          MockKeys.escrow.publicKey,
        });
        expect(rawGroupId, isNot(unhiddenThreadId));

        final resolvedParticipants = resolvedOrderParticipantSet(
          order: order,
          resolvedProofs: [
            ResolvedOrderParticipantProof(
              participantPubkey: tempBuyer.publicKey,
              identityPubkey: MockKeys.guest.publicKey,
            ),
          ],
        );

        expect(resolvedParticipants, unhiddenParticipants);
        expect(
          resolvedOrderGroupId(
            order: order,
            resolvedProofs: [
              ResolvedOrderParticipantProof(
                participantPubkey: tempBuyer.publicKey,
                identityPubkey: MockKeys.guest.publicKey,
              ),
            ],
          ),
          unhiddenThreadId,
        );
      },
    );
  });
}
