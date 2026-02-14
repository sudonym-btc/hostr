import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

void main() {
  group('Reservation.validate', () {
    for (final scenario in MOCK_RESERVATION_SCENARIOS) {
      test(scenario.description, () {
        final result = Reservation.validate(
          scenario.reservation,
          scenario.listing,
        );

        if (scenario.isValid) {
          expect(result, true);
          return;
        }

        if (scenario.expectedError != null) {
          expect(result, scenario.expectedError);
        } else {
          expect(result, false);
        }
      });
    }
  });
}
