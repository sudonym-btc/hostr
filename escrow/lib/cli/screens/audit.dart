import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:interact_cli/interact_cli.dart';

/// Runs a full trade audit and displays the result.
Future<Navigation> auditScreen(
  DaemonClient client,
  String tradeId,
) async {
  // ── Loading ────────────────────────────────────────────────────────────
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Running on-chain audit…',
      SpinnerStateType.done => 'Audit complete',
      SpinnerStateType.failed => 'Audit failed',
    },
  ).interact();

  Map<String, dynamic> result;
  try {
    result = await client.audit(tradeId);
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  // ── Display ────────────────────────────────────────────────────────────
  print('');
  print(result['formatted'] ?? '(no formatted output)');
  print('');

  if (result['explanation'] != null) {
    print('Explanation: ${result['explanation']}');
    print('');
  }

  // ── What next? ─────────────────────────────────────────────────────────
  final actions = [
    'Arbitrate this trade',
  ];

  final idx = SelectOrBack(prompt: 'Next', options: actions).interact();

  switch (idx) {
    case 0:
      return Navigation(Screen.arbitrate, selectedTradeId: tradeId);
    case -1:
    default:
      return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }
}
