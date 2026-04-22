import 'package:escrow/cli/styles.dart';
import 'package:test/test.dart';

void main() {
  group('formatTokenAmount', () {
    test('formats BTC-family 18-decimal amounts as sats', () {
      expect(
        formatTokenAmount('5000000000000000000', 18, 'BTC'),
        '500,000,000 sats',
      );
    });

    test('formats sat-denominated amounts without decimal scaling', () {
      expect(formatTokenAmount('500000000', 8, 'sat'), '500,000,000 sats');
    });

    test('formats non-BTC tokens with token decimals', () {
      expect(formatTokenAmount('123450000', 6, 'USDT'), '123.45 USDT');
    });
  });
}
