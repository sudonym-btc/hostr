import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:interact_cli/interact_cli.dart';

/// Shows on-chain details for a single trade and offers actions.
Future<Navigation> tradeDetailScreen(
  DaemonClient client,
  String tradeId,
) async {
  // ── Loading ────────────────────────────────────────────────────────────
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading trade…',
      SpinnerStateType.done => 'Trade loaded',
      SpinnerStateType.failed => 'Failed to load trade',
    },
  ).interact();

  Map<String, dynamic> data;
  try {
    data = await client.getTrade(tradeId);
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    return Navigation.to(Screen.tradeList);
  }

  // ── Display ────────────────────────────────────────────────────────────
  print('');
  print('── Trade: $tradeId ──');

  final cached = data['cached'] as Map<String, dynamic>?;
  if (cached != null) {
    print('  Status   : ${cached['status']}');
    print('  Amount   : ${cached['amountSats']} sats');
    print('  Last tx  : ${cached['txHash'] ?? '—'}');
    print('  Updated  : ${cached['updatedAt']}');
  }

  final onChain = data['onChain'] as Map<String, dynamic>?;
  if (onChain != null) {
    print('  Active   : ${onChain['isActive']}');
    print('  Buyer    : ${onChain['buyer']}');
    print('  Seller   : ${onChain['seller']}');
    print('  Arbiter  : ${onChain['arbiter']}');
    print('  Amount   : ${onChain['amount']} wei');
    print('  UnlockAt : ${onChain['unlockAt']}');
    print('  Fee      : ${onChain['escrowFee']} wei');
  } else if (cached == null) {
    print('  Trade not found in cache or on chain.');
  }
  print('');

  // ── Actions ────────────────────────────────────────────────────────────
  final actions = [
    'Audit',
    'Arbitrate',
    'Refresh',
  ];

  final idx = SelectOrBack(prompt: 'Action', options: actions).interact();

  switch (idx) {
    case -1:
      return Navigation.to(Screen.tradeList);
    case 0:
      return Navigation(Screen.audit, selectedTradeId: tradeId);
    case 1:
      return Navigation(Screen.arbitrate, selectedTradeId: tradeId);
    case 2:
    default:
      // Refresh = re-run this same screen
      return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }
}
