@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('EvmChain escrow token resolution', () {
    test('uses a host-accepted token for the reservation denomination', () {
      final method = _escrowMethod([
        ['a', 'USD', '412346:0x712516e61c8b383df4a63cfe83d7701bce54b03e'],
        ['a', 'BTC', '33:0x0000000000000000000000000000000000000000'],
      ]);

      expect(
        EvmChain.acceptedEscrowTokenTagId(
          sellerMethod: method,
          denominated: _amount('USD'),
          chainId: 412346,
        ),
        '412346:0x712516e61c8b383df4a63cfe83d7701bce54b03e',
      );
    });

    test('refuses to fall back to an unaccepted bridge token', () {
      final method = _escrowMethod([
        ['a', 'USD', '412346:0x712516e61c8b383df4a63cfe83d7701bce54b03e'],
      ]);

      expect(
        () => EvmChain.acceptedEscrowTokenTagId(
          sellerMethod: method,
          denominated: _amount('BTC'),
          chainId: 412346,
        ),
        throwsA(
          isA<UnsupportedEscrowPaymentTokenException>()
              .having((error) => error.denomination, 'denomination', 'BTC')
              .having((error) => error.chainId, 'chainId', 412346)
              .having(
                (error) => error.acceptedTokenTagIds,
                'acceptedTokenTagIds',
                isEmpty,
              ),
        ),
      );
    });

    test(
      'ignores accepted tokens for other chains and Lightning sentinels',
      () {
        final method = _escrowMethod([
          ['a', 'BTC', 'BTC'],
          ['a', 'BTC', '33:0x0000000000000000000000000000000000000000'],
        ]);

        expect(
          () => EvmChain.acceptedEscrowTokenTagId(
            sellerMethod: method,
            denominated: _amount('BTC'),
            chainId: 412346,
          ),
          throwsA(isA<UnsupportedEscrowPaymentTokenException>()),
        );
      },
    );
  });
}

EscrowMethod _escrowMethod(List<List<String>> tags) {
  final pubkey = List.filled(64, '0').join();
  return EscrowMethod.fromNostrEvent(
    Nip01EventModel.fromJson({
      'id': '',
      'pubkey': pubkey,
      'created_at': 0,
      'kind': kNostrKindEscrowMethod,
      'tags': tags,
      'content': '',
      'sig': '',
    }),
  );
}

DenominatedAmount _amount(String denomination) {
  return DenominatedAmount(
    denomination: denomination,
    value: BigInt.one,
    decimals: DenominatedAmount.decimalsFor(denomination),
  );
}
