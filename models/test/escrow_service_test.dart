import 'package:models/main.dart';
import 'package:test/test.dart';

void main() {
  group('EscrowServiceContent', () {
    test('serializes EVM params under params and fee under fee', () {
      final content = EscrowServiceContent(
        pubkey: 'escrow-pubkey',
        type: EscrowType.EVM,
        maxDuration: const Duration(days: 365),
        fee: EscrowFee(
          ppm: 10000,
          base: BigInt.from(5),
          min: BigInt.from(2),
          max: BigInt.from(100),
          assetOverrides: {
            '0xToken': EscrowFee(ppm: 20000, base: BigInt.from(7)),
          },
        ),
        params: const EscrowServiceParams(
          arbiterAddress: '0xArbiter',
          contractAddress: '0xContract',
          contractBytecodeHash: '0xBytecodeHash',
          chainId: 30,
        ),
      );

      expect(content.toJson(), {
        'pubkey': 'escrow-pubkey',
        'type': 'EVM',
        'maxDuration': 31536000,
        'fee': {
          'ppm': 10000,
          'base': '5',
          'min': '2',
          'max': '100',
          'assetOverrides': {
            '0xToken': {
              'ppm': 20000,
              'base': '7',
              'min': '0',
              'max': '0',
            },
          },
        },
        'params': {
          'arbiterAddress': '0xArbiter',
          'contractAddress': '0xContract',
          'contractBytecodeHash': '0xBytecodeHash',
          'chainId': 30,
        },
      });
    });

    test('calculates base ppm fee and asset override fee', () {
      final content = EscrowServiceContent(
        pubkey: 'escrow-pubkey',
        type: EscrowType.EVM,
        maxDuration: const Duration(days: 1),
        fee: EscrowFee(
          ppm: 10000,
          base: BigInt.from(10),
          min: BigInt.from(20),
          max: BigInt.from(200),
          assetOverrides: {
            '0xToken': EscrowFee(
              ppm: 5000,
              base: BigInt.from(3),
              min: BigInt.from(0),
              max: BigInt.from(0),
            ),
          },
        ),
        params: const EscrowServiceParams(
          arbiterAddress: '0xArbiter',
          contractAddress: '0xContract',
          contractBytecodeHash: '0xBytecodeHash',
          chainId: 30,
        ),
      );

      expect(content.escrowFee(BigInt.from(10000)), BigInt.from(110));
      expect(
        content.escrowFee(BigInt.from(10000), tokenAddress: '0xToken'),
        BigInt.from(53),
      );
    });
  });
}
