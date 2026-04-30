import 'support/e2e_test_harness.dart';

void main() {
  runE2eTests(suites: {E2eSuite.listings}, loginModes: {E2eLoginMode.nsec});
}
