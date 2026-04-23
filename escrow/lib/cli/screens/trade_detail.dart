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
  final participants = data['participants'] as Map<String, dynamic>?;

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
    final updatedBlockNum = _jsonInt(cached['updatedBlockNum']);
    final updatedBlockTimestamp = DateTime.tryParse(
      '${cached['updatedBlockTimestamp'] ?? ''}',
    );
    print(kvTable({
      'Status': colorStatus('${cached['status']}'),
      'Amount': amountStr,
      'Last tx': '${cached['txHash'] ?? '—'}',
      'Updated block': updatedBlockNum != null ? '$updatedBlockNum' : '—',
      'Updated at': updatedBlockTimestamp != null
          ? '${relativeTime(updatedBlockTimestamp)} (${updatedBlockTimestamp.toLocal()})'
          : '—',
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

  if (participants != null) {
    final buyer = participants['buyer'] as Map<String, dynamic>?;
    final seller = participants['seller'] as Map<String, dynamic>?;
    print(kvTable({
      if (buyer != null)
        'Buyer Nostr': _formatParticipant(
          buyer['displayName'] as String?,
          buyer['pubkey'] as String?,
        ),
      if (seller != null)
        'Seller Nostr': _formatParticipant(
          seller['displayName'] as String?,
          seller['pubkey'] as String?,
        ),
    }));
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

int? _jsonInt(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

String _formatParticipant(String? displayName, String? pubkey) {
  if (pubkey == null || pubkey.isEmpty) return '—';
  final short = pubkey.substring(0, 5);
  return displayName != null && displayName.isNotEmpty
      ? '$displayName ($short)'
      : short;
}
