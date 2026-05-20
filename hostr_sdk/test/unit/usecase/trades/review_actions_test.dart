@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/trades/actions/review.dart';
import 'package:hostr_sdk/usecase/trades/actions/trade_action_resolver.dart';
import 'package:hostr_sdk/usecase/trades/trade.dart';
import 'package:hostr_sdk/util/stream_status.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

final _f = EntityFactory();

Future<Order> _order({
  required Listing listing,
  required String tradeId,
  required DateTime start,
  required DateTime end,
  required OrderStage stage,
  required bool seller,
}) {
  final signer = seller ? MockKeys.hoster : MockKeys.guest;
  return _f.order(
    listing: listing,
    dTag: tradeId,
    signerOverride: signer,
    stage: stage,
    start: start,
    end: end,
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(MockKeys.guest.publicKey),
    ],
    createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
  );
}

void main() {
  final listing = _f.listing(
    signer: MockKeys.hoster,
    dTag: 'review-action-listing',
    title: 'Review Action Listing',
    description: 'Fixture',
    images: const [],
    priceSats: 100000,
    location: 'Test',
    type: ListingType.house,
    specifications: Specifications(),
  );

  group('ReviewActions.resolve', () {
    test(
      'shows review when group is confirmedCommitted and stay ended',
      () async {
        final sellerCommit = await _order(
          listing: listing,
          tradeId: 'trade-review-ended',
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 2),
          stage: OrderStage.commit,
          seller: true,
        );
        final buyerCancel = await _order(
          listing: listing,
          tradeId: 'trade-review-ended',
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 2),
          stage: OrderStage.cancel,
          seller: false,
        );

        final actions = ReviewActions.resolve(
          orderGroup: OrderGroup(
            orders: [sellerCommit, buyerCancel],
            confirmedCommitted: true,
          ),
          orderStreamStatus: StreamStatusLive(),
          payments: const [],
          role: TradeRole.guest,
        );

        expect(actions, contains(TradeAction.review));
      },
    );

    test(
      'does not show review when group was never confirmed committed',
      () async {
        final buyerNegotiate = await _order(
          listing: listing,
          tradeId: 'trade-review-unconfirmed',
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 2),
          stage: OrderStage.negotiate,
          seller: false,
        );

        final actions = ReviewActions.resolve(
          orderGroup: OrderGroup(
            orders: [buyerNegotiate],
            confirmedCommitted: false,
          ),
          orderStreamStatus: StreamStatusLive(),
          payments: const [],
          role: TradeRole.guest,
        );

        expect(actions, isNot(contains(TradeAction.review)));
      },
    );

    test('shows review when terminal payment exists before end date', () async {
      final sellerCommit = await _order(
        listing: listing,
        tradeId: 'trade-review-terminal',
        start: DateTime(2026, 12, 1),
        end: DateTime(2026, 12, 5),
        stage: OrderStage.commit,
        seller: true,
      );

      final actions = ReviewActions.resolve(
        orderGroup: OrderGroup(
          orders: [sellerCommit],
          confirmedCommitted: true,
        ),
        orderStreamStatus: StreamStatusLive(),
        payments: [PaymentReleasedEvent(tradeId: 'trade-review-terminal')],
        role: TradeRole.guest,
      );

      expect(actions, contains(TradeAction.review));
    });
  });
}
