@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/order_groups/order_group_participant_resolver.dart';
import 'package:hostr_sdk/usecase/orders/order_participant_keyring.dart';
import 'package:hostr_sdk/usecase/orders/orders.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';

void main() {
  group('seed order participant proofs', () {
    test(
      'pending trade requests resolve hidden buyers to the real thread id',
      () async {
        final helper = TestSeedHelper(seed: 1201);
        addTearDown(helper.dispose);

        final trade = await helper.freshTrade();
        final request = trade.negotiateOrder;

        expect(request.parsedTags.participantProofs, isNotEmpty);
        expect(
          request.parsedTags.participantProofs.every(
            (proof) => proof.payloadHash.isNotEmpty,
          ),
          isTrue,
        );
        expect(
          request.parsedTags.getTagValueByMarker('p', 'buyer'),
          request.pubKey,
        );

        final resolved = await OrderGroupParticipantResolver(
          keyring: KeyPairOrderParticipantKeyring(
            keyPairs: [trade.host.keyPair],
          ),
        ).resolve(OrderGroup(orders: [request]));

        expect(resolved.rawParticipantPubkeyForRole('buyer'), request.pubKey);
        expect(
          resolved.resolvedParticipantPubkeyForRole('buyer'),
          trade.guest.publicKey,
        );
        expect(
          resolved.resolvedGroupId,
          Threads.conversationId(request.getDtag()!, [
            trade.host.publicKey,
            trade.guest.publicKey,
          ]),
        );
      },
    );

    test(
      'host commit fixtures stay in the request group after resolution',
      () async {
        final helper = TestSeedHelper(seed: 1202);
        addTearDown(helper.dispose);

        final trade = await helper.freshTrade();
        final request = trade.negotiateOrder;
        final hostCommit = await helper.entities.order(
          guestKeyPair: trade.guest.keyPair,
          dTag: request.getDtag()!,
          listing: trade.listing,
          start: request.start,
          end: request.end,
          stage: OrderStage.commit,
          quantity: request.quantity,
          amount: request.amount,
          recipient: request.recipient,
          signerOverride: trade.host.keyPair,
        );

        expect(hostCommit.parsedTags.participantProofs, isNotEmpty);
        expect(
          hostCommit.parsedTags.participantProofs.every(
            (proof) => proof.payloadHash.isNotEmpty,
          ),
          isTrue,
        );
        expect(
          hostCommit.parsedTags.getTagValueByMarker('p', 'buyer'),
          request.pubKey,
        );

        final groups = Orders.toOrderGroups(orders: [request, hostCommit]);
        expect(groups, hasLength(1));

        final resolved = await OrderGroupParticipantResolver(
          keyring: KeyPairOrderParticipantKeyring(
            keyPairs: [trade.host.keyPair],
          ),
        ).resolve(groups.values.single);

        expect(
          resolved.resolvedParticipantPubkeyForRole('buyer'),
          trade.guest.publicKey,
        );
        expect(resolved.rawGroupId, groups.keys.single);
        expect(
          resolved.resolvedGroupId,
          Threads.conversationId(request.getDtag()!, [
            trade.host.publicKey,
            trade.guest.publicKey,
          ]),
        );
      },
    );

    test('mock completed orders use participant proofs only', () async {
      final helper = TestSeedHelper(seed: 1203);
      addTearDown(helper.dispose);

      final trade = await helper.freshTrade();
      final order = await helper.factory.buildMockOrder(
        trade.thread,
        hostProfile: trade.host.profile,
      );

      expect(order.parsedTags.participantProofs, isNotEmpty);
      expect(
        order.parsedTags.participantProofs.every(
          (proof) => proof.payloadHash.isNotEmpty,
        ),
        isTrue,
      );

      final resolved = await OrderGroupParticipantResolver(
        keyring: KeyPairOrderParticipantKeyring(keyPairs: [trade.host.keyPair]),
      ).resolve(OrderGroup(orders: [order]));

      expect(
        resolved.resolvedParticipantPubkeyForRole('buyer'),
        trade.guest.publicKey,
      );
    });
  });
}
