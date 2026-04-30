import 'support/e2e_test_harness.dart';

void main() {
  runE2eTests(
    suites: {E2eSuite.guestCancellations},
    loginModes: {E2eLoginMode.nsec},
    cancellationCases: {E2eCancellationCase.hostLive},
  );
}
