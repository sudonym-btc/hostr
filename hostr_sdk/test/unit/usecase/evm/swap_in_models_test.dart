@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/evm/operations/swap_in/swap_in_models.dart';
import 'package:test/test.dart';

void main() {
  group('SwapInDexBuffer', () {
    test('standard applies max of 0.1 percent and 2 sats', () {
      expect(
        SwapInDexBuffer.standard.applyToSats(BigInt.from(1000)),
        BigInt.from(1002),
        reason: '2 sats should beat 0.1% for small swaps',
      );
      expect(
        SwapInDexBuffer.standard.applyToSats(BigInt.from(1000000)),
        BigInt.from(1001000),
        reason: '0.1% should beat the 2-sat minimum for larger swaps',
      );
    });

    test('percentage buffer rounds up to avoid losing fractional bps', () {
      expect(
        const SwapInDexBuffer(
          basisPoints: 1,
          minSats: 0,
        ).applyToSats(BigInt.from(10001)),
        BigInt.from(10003),
      );
    });

    test('zero leaves the amount unchanged', () {
      expect(
        SwapInDexBuffer.zero.applyToSats(BigInt.from(6576)),
        BigInt.from(6576),
      );
    });
  });
}
