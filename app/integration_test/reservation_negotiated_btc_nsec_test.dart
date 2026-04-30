import 'support/e2e_test_harness.dart';

void main() {
  runE2eTests(
    suites: {E2eSuite.reservations},
    loginModes: {E2eLoginMode.nsec},
    reservationCases: {E2eReservationCase.negotiatedBtc},
  );
}
