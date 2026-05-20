@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/escrow_daemon/escrow_daemon.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

Order _order() => Order.create(
  pubKey: MockKeys.guest.publicKey,
  dTag: 'trade-startup-replay',
  listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
  pTags: [
    PTag.seller(MockKeys.hoster.publicKey),
    PTag.buyer(MockKeys.guest.publicKey),
    PTag.escrow(MockKeys.escrow.publicKey),
  ],
  stage: OrderStage.commit,
  start: DateTime.utc(2026, 5, 1),
  end: DateTime.utc(2026, 5, 2),
);

void main() {
  test(
    'order listener events replay orders collected before listener attaches',
    () async {
      final source = StreamWithStatus<Order>();
      final order = _order();

      source.add(order);

      await expectLater(
        EscrowDaemon.orderListenerEvents(source).take(1),
        emits(predicate<Order>((event) => event.id == order.id)),
      );
    },
  );

  test('missing funded-event verification failures are retried', () {
    expect(
      EscrowDaemon.isRetryableOrderVerificationFailure(
        'Escrow logs do not contain a funding event for trade trade-1 in 0xabc',
      ),
      isTrue,
    );
    expect(
      EscrowDaemon.isRetryableOrderVerificationFailure(
        'Failed to query escrow logs for trade trade-1: timeout',
      ),
      isTrue,
    );
    expect(
      EscrowDaemon.isRetryableOrderVerificationFailure(
        'Onchain escrowed amount (1) is less than expected listing amount (2)',
      ),
      isFalse,
    );
  });

  test('order trade id is extracted from d tag', () {
    expect(EscrowDaemon.orderTradeId(_order()), 'trade-startup-replay');
  });

  test('order group involvement is based on escrow participant tags', () {
    final withEscrow = OrderGroup.fromOrder(_order());
    final withoutEscrow = OrderGroup.fromOrder(
      Order.create(
        pubKey: MockKeys.guest.publicKey,
        dTag: 'trade-no-escrow',
        listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-1',
        pTags: [
          PTag.seller(MockKeys.hoster.publicKey),
          PTag.buyer(MockKeys.guest.publicKey),
        ],
        stage: OrderStage.commit,
      ),
    );

    expect(
      EscrowDaemon.orderGroupInvolvesEscrow(
        withEscrow,
        MockKeys.escrow.publicKey,
      ),
      isTrue,
    );
    expect(
      EscrowDaemon.orderGroupInvolvesEscrow(
        withoutEscrow,
        MockKeys.escrow.publicKey,
      ),
      isFalse,
    );
  });
}
