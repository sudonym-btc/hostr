import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:interact_cli/interact_cli.dart';

/// Prompts the user for arbitration parameters and executes on-chain.
Future<Navigation> arbitrateScreen(
  DaemonClient client,
  String tradeId,
) async {
  print('');
  print('── Arbitrate: $tradeId ──');
  print('');
  print('  Enter the forward ratio — the fraction of escrowed funds sent to');
  print('  the seller. Must be strictly between 0 and 1.');
  print(
      '  Example: 0.5 = split 50/50, 0.9 = 90% to seller, 0.1 = mostly refund buyer.');
  print('');

  final forwardStr = Input(prompt: 'Forward ratio (0–1)').interact();
  final forward = double.tryParse(forwardStr.trim());

  if (forward == null || forward <= 0 || forward >= 1) {
    print('  Invalid value. Must be a number strictly between 0 and 1.');
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  // Confirmation
  final confirmed = Confirm(
    prompt: 'Arbitrate trade $tradeId with forward=$forward?',
    defaultValue: false,
  ).interact();

  if (!confirmed) {
    print('  Cancelled.');
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  // ── Execute ────────────────────────────────────────────────────────────
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Submitting arbitration tx…',
      SpinnerStateType.done => 'Transaction submitted',
      SpinnerStateType.failed => 'Transaction failed',
    },
  ).interact();

  try {
    final txHash = await client.arbitrate(tradeId, forward);
    spinner.done();
    print('  Tx hash: $txHash');
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
  }

  print('');

  final actions = [
    'View updated trade detail',
  ];

  final idx = SelectOrBack(prompt: 'Next', options: actions).interact();

  switch (idx) {
    case 0:
      return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
    case -1:
    default:
      return Navigation.to(Screen.tradeList);
  }
}
