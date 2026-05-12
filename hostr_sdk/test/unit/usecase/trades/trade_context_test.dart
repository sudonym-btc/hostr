@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/trades/trade.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';

void main() {
  group('TradeContext participant matching', () {
    test(
      'matches raw reservation participants with escrow as optional extra',
      () {
        final context = TradeContext(
          tradeId: 'trade-raw-buyer',
          participants: const ['seller-pubkey', 'temp-buyer-pubkey'],
        );

        expect(
          context.matchesParticipantSet(const {
            'seller-pubkey',
            'temp-buyer-pubkey',
            'escrow-pubkey',
          }, optionalEscrowPubkey: 'escrow-pubkey'),
          isTrue,
        );
        expect(
          context.conversationId,
          ReservationGroup.groupIdForParticipants(
            tradeId: 'trade-raw-buyer',
            participants: const ['seller-pubkey', 'temp-buyer-pubkey'],
          ),
        );
      },
    );

    test(
      'matches resolved reservation participants with escrow as optional extra',
      () {
        final context = TradeContext(
          tradeId: 'trade-resolved-buyer',
          participants: const ['seller-pubkey', 'real-buyer-pubkey'],
        );

        expect(
          context.matchesParticipantSet(const {
            'seller-pubkey',
            'real-buyer-pubkey',
            'escrow-pubkey',
          }, optionalEscrowPubkey: 'escrow-pubkey'),
          isTrue,
        );
      },
    );

    test('does not accept unrelated extra participants', () {
      final context = TradeContext(
        tradeId: 'trade-extra-participant',
        participants: const ['seller-pubkey', 'temp-buyer-pubkey'],
      );

      expect(
        context.matchesParticipantSet(const {
          'seller-pubkey',
          'temp-buyer-pubkey',
          'unrelated-pubkey',
        }, optionalEscrowPubkey: 'escrow-pubkey'),
        isFalse,
      );
    });
  });
}
