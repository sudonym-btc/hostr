@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/order_groups/order_group_participant_resolver.dart';
import 'package:hostr_sdk/usecase/orders/order_participant_keyring.dart';
import 'package:hostr_sdk/usecase/orders/order_participant_tags.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

class _FakeParticipantKeyring implements OrderParticipantKeyring {
  final Map<String, ResolvedOrderParticipantProof> resolvedByPayload;
  int decryptCalls = 0;

  _FakeParticipantKeyring({this.resolvedByPayload = const {}});

  @override
  Future<bool> controlsPubkey({
    required String pubkey,
    required String tradeId,
  }) async {
    return resolvedByPayload.isNotEmpty;
  }

  @override
  Future<ResolvedOrderParticipantProof?> tryDecryptParticipantProof({
    required Order order,
    required OrderParticipantProofTag proof,
  }) async {
    decryptCalls += 1;
    return resolvedByPayload[proof.payload];
  }
}

Order _order({
  required String tradeId,
  required String authorPubkey,
  required List<List<String>> extraTags,
}) {
  return Order.create(
    pubKey: authorPubkey,
    dTag: tradeId,
    listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-resolver',
    extraTags: extraTags,
  );
}

void main() {
  const tradeId = 'trade-resolved-participants';
  final tempBuyer = mockKeys[40];
  final escrow = MockKeys.escrow.publicKey;

  group('OrderGroupParticipantResolver', () {
    test('returns raw participants unchanged when no proofs resolve', () async {
      final keyring = _FakeParticipantKeyring();
      final resolver = OrderGroupParticipantResolver(keyring: keyring);
      final order = _order(
        tradeId: tradeId,
        authorPubkey: MockKeys.guest.publicKey,
        extraTags: [
          ['p', MockKeys.hoster.publicKey, '', 'seller'],
        ],
      );
      final group = OrderGroup(orders: [order]);

      final resolved = await resolver.resolve(group);

      expect(resolved.group, same(group));
      expect(resolved.rawParticipantSet, {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
      expect(resolved.resolvedParticipantSet, resolved.rawParticipantSet);
      expect(resolved.rawGroupId, group.groupId);
      expect(resolved.resolvedGroupId, group.groupId);
      expect(resolved.resolvedProofs, isEmpty);
      expect(resolved.hasResolvedParticipants, isFalse);
      expect(keyring.decryptCalls, 0);
    });

    test(
      'replaces hidden participant pubkeys and derives the unhidden thread id',
      () async {
        final proof = ResolvedOrderParticipantProof(
          participantPubkey: tempBuyer.publicKey,
          identityPubkey: MockKeys.guest.publicKey,
        );
        final keyring = _FakeParticipantKeyring(
          resolvedByPayload: {'buyer-proof': proof},
        );
        final resolver = OrderGroupParticipantResolver(keyring: keyring);
        final order = _order(
          tradeId: tradeId,
          authorPubkey: tempBuyer.publicKey,
          extraTags: [
            ['p', MockKeys.hoster.publicKey, '', 'seller'],
            ['p', escrow, '', 'escrow'],
            OrderParticipantProofTag(
              role: 'buyer',
              participantPubkey: tempBuyer.publicKey,
              recipientPubkey: MockKeys.hoster.publicKey,
              scheme: kOrderParticipantProofSchemeNip44,
              payloadHash: OrderParticipantProofTag.hashPayload('buyer-proof'),
              payload: 'buyer-proof',
            ).toTag(),
          ],
        );
        final group = OrderGroup(orders: [order]);

        final resolved = await resolver.resolve(group);

        final unhiddenParticipants = {
          MockKeys.guest.publicKey,
          MockKeys.hoster.publicKey,
          escrow,
        };
        expect(resolved.rawParticipantSet, {
          tempBuyer.publicKey,
          MockKeys.hoster.publicKey,
          escrow,
        });
        expect(resolved.resolvedParticipantSet, unhiddenParticipants);
        expect(resolved.resolvedParticipantSetWithoutEscrow, {
          MockKeys.guest.publicKey,
          MockKeys.hoster.publicKey,
        });
        expect(resolved.rawGroupId, isNot(resolved.resolvedGroupId));
        expect(
          resolved.resolvedGroupId,
          Threads.conversationId(tradeId, unhiddenParticipants),
        );
        expect(resolved.identityByParticipantPubkey, {
          tempBuyer.publicKey: MockKeys.guest.publicKey,
        });
        expect(
          resolved.rawParticipantPubkeyForRole('buyer'),
          tempBuyer.publicKey,
        );
        expect(
          resolved.resolvedParticipantPubkeyForRole('buyer'),
          MockKeys.guest.publicKey,
        );
        expect(
          resolved.resolvedParticipantPubkeyForRole('seller'),
          MockKeys.hoster.publicKey,
        );
        expect(resolved.hasParticipantProofFor(tempBuyer.publicKey), isTrue);
        expect(resolved.hasResolvedProofFor(tempBuyer.publicKey), isTrue);
        expect(resolved.hasResolvedParticipants, isTrue);
        expect(keyring.decryptCalls, 1);
      },
    );

    test('resolves buyer proofs from a host-only order group', () async {
      final proof = ResolvedOrderParticipantProof(
        participantPubkey: tempBuyer.publicKey,
        identityPubkey: MockKeys.guest.publicKey,
      );
      final keyring = _FakeParticipantKeyring(
        resolvedByPayload: {'buyer-proof': proof},
      );
      final resolver = OrderGroupParticipantResolver(keyring: keyring);
      final order = _order(
        tradeId: tradeId,
        authorPubkey: MockKeys.hoster.publicKey,
        extraTags: [
          ['p', tempBuyer.publicKey, '', 'buyer'],
          ['p', escrow, '', 'escrow'],
          OrderParticipantProofTag(
            role: 'buyer',
            participantPubkey: tempBuyer.publicKey,
            recipientPubkey: MockKeys.hoster.publicKey,
            scheme: kOrderParticipantProofSchemeNip44,
            payloadHash: OrderParticipantProofTag.hashPayload('buyer-proof'),
            payload: 'buyer-proof',
          ).toTag(),
        ],
      );
      final group = OrderGroup(orders: [order]);

      final resolved = await resolver.resolve(group);

      expect(group.buyerOrder, isNull);
      expect(
        resolved.rawParticipantPubkeyForRole('buyer'),
        tempBuyer.publicKey,
      );
      expect(
        resolved.resolvedParticipantPubkeyForRole('buyer'),
        MockKeys.guest.publicKey,
      );
      expect(
        resolved.hasResolvedParticipantForRole(
          'buyer',
          requireResolvedProof: true,
        ),
        isTrue,
      );
      expect(resolved.rawParticipantSet, {
        MockKeys.hoster.publicKey,
        tempBuyer.publicKey,
        escrow,
      });
      expect(resolved.resolvedParticipantSet, {
        MockKeys.hoster.publicKey,
        MockKeys.guest.publicKey,
        escrow,
      });
    });

    test('deduplicates repeated resolved proofs for the same alias', () async {
      final proof = ResolvedOrderParticipantProof(
        participantPubkey: tempBuyer.publicKey,
        identityPubkey: MockKeys.guest.publicKey,
      );
      final keyring = _FakeParticipantKeyring(
        resolvedByPayload: {'buyer-proof-a': proof, 'buyer-proof-b': proof},
      );
      final resolver = OrderGroupParticipantResolver(keyring: keyring);
      final order = _order(
        tradeId: tradeId,
        authorPubkey: tempBuyer.publicKey,
        extraTags: [
          ['p', MockKeys.hoster.publicKey, '', 'seller'],
          OrderParticipantProofTag(
            role: 'buyer',
            participantPubkey: tempBuyer.publicKey,
            recipientPubkey: MockKeys.hoster.publicKey,
            scheme: kOrderParticipantProofSchemeNip44,
            payloadHash: OrderParticipantProofTag.hashPayload('buyer-proof-a'),
            payload: 'buyer-proof-a',
          ).toTag(),
          OrderParticipantProofTag(
            role: 'buyer',
            participantPubkey: tempBuyer.publicKey,
            recipientPubkey: escrow,
            scheme: kOrderParticipantProofSchemeNip44,
            payloadHash: OrderParticipantProofTag.hashPayload('buyer-proof-b'),
            payload: 'buyer-proof-b',
          ).toTag(),
        ],
      );

      final resolved = await resolver.resolve(OrderGroup(orders: [order]));

      expect(resolved.resolvedProofs, hasLength(1));
      expect(resolved.resolvedParticipantSet, {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
      expect(keyring.decryptCalls, 2);
    });

    test('maps order group streams into resolved participants', () async {
      final proof = ResolvedOrderParticipantProof(
        participantPubkey: tempBuyer.publicKey,
        identityPubkey: MockKeys.guest.publicKey,
      );
      final resolver = OrderGroupParticipantResolver(
        keyring: _FakeParticipantKeyring(
          resolvedByPayload: {'buyer-proof': proof},
        ),
      );
      final source = StreamWithStatus<OrderGroup>();
      final mapped = source.resolveParticipantSets(resolver: resolver);
      final next = mapped.replayStream.first;

      source.add(
        OrderGroup(
          orders: [
            _order(
              tradeId: tradeId,
              authorPubkey: tempBuyer.publicKey,
              extraTags: [
                ['p', MockKeys.hoster.publicKey, '', 'seller'],
                OrderParticipantProofTag(
                  role: 'buyer',
                  participantPubkey: tempBuyer.publicKey,
                  recipientPubkey: MockKeys.hoster.publicKey,
                  scheme: kOrderParticipantProofSchemeNip44,
                  payloadHash: OrderParticipantProofTag.hashPayload(
                    'buyer-proof',
                  ),
                  payload: 'buyer-proof',
                ).toTag(),
              ],
            ),
          ],
        ),
      );

      final resolved = await next;
      expect(resolved.resolvedParticipantSet, {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
    });

    test('maps validated group streams while preserving validation', () async {
      final resolver = OrderGroupParticipantResolver(
        keyring: _FakeParticipantKeyring(),
      );
      final source = StreamWithStatus<Validation<OrderGroup>>();
      final mapped = source.resolveParticipantSets(resolver: resolver);
      final next = mapped.replayStream.first;
      final group = OrderGroup(
        orders: [
          _order(
            tradeId: tradeId,
            authorPubkey: MockKeys.guest.publicKey,
            extraTags: [
              ['p', MockKeys.hoster.publicKey, '', 'seller'],
            ],
          ),
        ],
      );

      source.add(Invalid(group, 'nope'));

      final resolved = await next;
      expect(resolved.validation, isA<Invalid<OrderGroup>>());
      expect((resolved.validation as Invalid<OrderGroup>).reason, 'nope');
      expect(resolved.participants.group, same(group));
    });
  });
}
