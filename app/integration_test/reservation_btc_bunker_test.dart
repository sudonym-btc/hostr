import 'support/e2e_test_harness.dart';

void main() {
  runE2eTests(
    suites: {E2eSuite.reservations},
    loginModes: {E2eLoginMode.bunker},
    reservationCases: {E2eReservationCase.btc},
  );
}
