import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/styles.dart';
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
  print(sectionHeader('Trade: $tradeId'));

  final cached = data['cached'] as Map<String, dynamic>?;
  if (cached != null) {
    final amount = cached['amountSats'] is int
        ? formatSats(cached['amountSats'] as int)
        : '${cached['amountSats']}';
    print(kvTable({
      'Status': colorStatus('${cached['status']}'),
      'Amount': '$amount sats',
      'Last tx': '${cached['txHash'] ?? '—'}',
      'Updated': '${cached['updatedAt']}',
    }));
  }

  final onChain = data['onChain'] as Map<String, dynamic>?;
  if (onChain != null) {
    print(kvTable({
      'Active': '${onChain['isActive']}',
      'Buyer': '${onChain['buyer']}',
      'Seller': '${onChain['seller']}',
      'Arbiter': '${onChain['arbiter']}',
      'Amount': '${onChain['amount']} wei',
      'UnlockAt': '${onChain['unlockAt']}',
      'Fee': '${onChain['escrowFee']} wei',
    }));
  } else if (cached == null) {
    print('  Trade not found in cache or on chain.');
  }
  print('');

  // ── Actions ────────────────────────────────────────────────────────────
  final actions = [
    'Audit',
    'Arbitrate',
    'View Thread',
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
      return Navigation(Screen.threadDetail, selectedThreadId: tradeId);
    case 3:
    default:
      // Refresh = re-run this same screen
      return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }
}
