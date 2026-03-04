import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:escrow/shared/protocol.dart';
import 'package:interact_cli/interact_cli.dart';

/// Shows all pending trades and lets the user select one.
Future<Navigation> tradeListScreen(DaemonClient client) async {
  // ── Loading ────────────────────────────────────────────────────────────
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Fetching pending trades…',
      SpinnerStateType.done => 'Trades loaded',
      SpinnerStateType.failed => 'Failed to load trades',
    },
  ).interact();

  List<TradeSummary> trades;
  try {
    trades = await client.listPending();
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    return Navigation.to(Screen.mainMenu);
  }

  if (trades.isEmpty) {
    print('  No pending trades.');
    return Navigation.to(Screen.mainMenu);
  }

  // ── Selection ──────────────────────────────────────────────────────────
  final options = trades.map((t) {
    final short =
        t.tradeId.length > 12 ? '${t.tradeId.substring(0, 12)}…' : t.tradeId;
    return '$short  ${t.amountSats} sats  (${t.status})';
  }).toList();

  final idx =
      SelectOrBack(prompt: 'Pending Trades', options: options).interact();

  if (idx == -1) {
    return Navigation.to(Screen.mainMenu);
  }

  return Navigation(
    Screen.tradeDetail,
    selectedTradeId: trades[idx].tradeId,
  );
}
