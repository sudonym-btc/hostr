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

  final threadAnchor = data['threadAnchor'] as String?;

  // ── Display ────────────────────────────────────────────────────────────
  print('');
  print(sectionHeader('Trade: $tradeId'));

  final cached = data['cached'] as Map<String, dynamic>?;
  if (cached != null) {
    // Support both new token-aware fields and legacy amountSats for old daemons.
    final String amountStr;
    if (cached.containsKey('amountWei')) {
      amountStr = formatTokenAmount(
        cached['amountWei'] as String,
        cached['tokenDecimals'] as int? ?? 8,
        cached['tokenSymbol'] as String? ?? 'sat',
      );
    } else {
      amountStr = '${formatSats(cached['amountSats'] as int? ?? 0)} sats';
    }
    final updatedAt = DateTime.tryParse('${cached['updatedAt'] ?? ''}');
    final updatedLabel = updatedAt == null
        ? '${cached['updatedAt'] ?? '—'}'
        : '${relativeTime(updatedAt)} (${updatedAt.toLocal()})';
    print(kvTable({
      'Status': colorStatus('${cached['status']}'),
      'Amount': amountStr,
      'Last tx': '${cached['txHash'] ?? '—'}',
      'Updated': updatedLabel,
    }));
  }

  final onChain = data['onChain'] as Map<String, dynamic>?;
  if (onChain != null) {
    final tokenDecimals = onChain['tokenDecimals'] as int? ??
        cached?['tokenDecimals'] as int? ??
        8;
    final tokenSymbol = onChain['tokenSymbol'] as String? ??
        cached?['tokenSymbol'] as String? ??
        'sat';
    String amount(String key) => formatTokenAmount(
          onChain[key] as String? ?? '0',
          tokenDecimals,
          tokenSymbol,
        );
    print(kvTable({
      'Active': '${onChain['isActive']}',
      'Buyer': '${onChain['buyer']}',
      'Seller': '${onChain['seller']}',
      'Arbiter': '${onChain['arbiter']}',
      'Payment': amount('paymentAmount'),
      'Bond': amount('bondAmount'),
      'UnlockAt': '${onChain['unlockAt']}',
      'Fee': amount('escrowFee'),
    }));
  } else if (cached == null) {
    print('  Trade not found in cache or on chain.');
  }
  print('');

  // ── Actions ────────────────────────────────────────────────────────────
  final actions = [
    'Audit',
    'Arbitrate',
    if (threadAnchor != null) 'View Thread',
    'Refresh',
  ];

  final idx = SelectOrBack(prompt: 'Action', options: actions).interact();

  if (idx == -1) return Navigation.to(Screen.tradeList);
  final selected = actions[idx];
  switch (selected) {
    case 'Audit':
      return Navigation(Screen.audit, selectedTradeId: tradeId);
    case 'Arbitrate':
      return Navigation(Screen.arbitrate, selectedTradeId: tradeId);
    case 'View Thread':
      return Navigation(Screen.threadDetail, selectedThreadId: threadAnchor!);
    case 'Refresh':
    default:
      return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }
}
