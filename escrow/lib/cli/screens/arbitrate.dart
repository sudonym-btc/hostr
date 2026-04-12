import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/styles.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:interact_cli/interact_cli.dart';

/// Prompts the user for arbitration parameters and executes on-chain.
Future<Navigation> arbitrateScreen(
  DaemonClient client,
  String tradeId,
) async {
  print('');
  print(sectionHeader('Arbitrate: $tradeId'));
  print('');
  print('  Enter the forward ratios — the fraction sent to the seller.');
  print('  Each must be between 0 and 1 (inclusive).');
  print('  Example: 1 = all to seller, 0 = full refund to buyer, 0.5 = split.');
  print('');
  print(kDimStyle.render('  Leave blank to go back.'));
  print('');

  // ── Payment forward ────────────────────────────────────────────────
  final paymentStr = Input(prompt: 'Payment forward ratio (0–1)').interact();

  if (paymentStr.trim().isEmpty) {
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  final paymentForward = double.tryParse(paymentStr.trim());

  if (paymentForward == null || paymentForward < 0 || paymentForward > 1) {
    print('  Invalid value. Must be a number between 0 and 1.');
    pressAnyKey();
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  // ── Bond forward ───────────────────────────────────────────────────
  final bondStr = Input(
    prompt: 'Bond (security deposit) forward ratio (0–1)',
    defaultValue: '0',
  ).interact();

  final bondForward = double.tryParse(bondStr.trim());

  if (bondForward == null || bondForward < 0 || bondForward > 1) {
    print('  Invalid value. Must be a number between 0 and 1.');
    pressAnyKey();
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  // Confirmation
  final confirmed = Confirm(
    prompt:
        'Arbitrate trade $tradeId with paymentForward=$paymentForward, bondForward=$bondForward?',
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
    final txHash = await client.arbitrate(tradeId, paymentForward, bondForward);
    spinner.done();
    print('  Tx hash: $txHash');
  } catch (e) {
    spinner.failed();
    print('');
    print('  Error: $e');
    print('');
    Input(prompt: 'Press Enter to continue').interact();
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
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
