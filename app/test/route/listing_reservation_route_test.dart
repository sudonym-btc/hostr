import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/route/listing_reservation_route.dart';
import 'package:models/main.dart';

void main() {
  group('listing reservation route query helpers', () {
    test('round-trips reserve amount query params', () {
      final amount = DenominatedAmount(
        denomination: 'USD',
        value: BigInt.from(15000000),
        decimals: 6,
      );

      final parsed = parseReserveAmountQuery(
        value: reserveAmountValueQuery(amount),
        denomination: reserveAmountDenominationQuery(amount),
        decimals: reserveAmountDecimalsQuery(amount),
      );

      expect(parsed, amount);
      expect(parsed?.decimals, 6);
    });

    test('parses auto reserve flag', () {
      expect(parseAutoReserveQuery(autoReserveQuery(true)), isTrue);
      expect(parseAutoReserveQuery(null), isFalse);
      expect(parseAutoReserveQuery('false'), isFalse);
    });
  });
}
