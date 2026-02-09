import 'thread_builders.dart';
import 'thread_scenario.dart';

final List<ThreadScenario> MOCK_THREAD_SCENARIOS = [
  buildPendingGuestToHostScenario(),
  buildPaidGuestToHostScenario(),
  buildSelfSignedGuestToHostScenario(),
  buildConfirmedGuestToHostScenario(),
  buildCancelledGuestToHostScenario(),
];
