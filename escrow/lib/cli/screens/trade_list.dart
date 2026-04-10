import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/styles.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:escrow/shared/protocol.dart';
import 'package:interact_cli/interact_cli.dart';

/// Shows all trades and lets the user select one.
Future<Navigation> tradeListScreen(DaemonClient client) async {
  // ── Loading ────────────────────────────────────────────────────────────
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Fetching trades…',
      SpinnerStateType.done => 'Trades loaded',
      SpinnerStateType.failed => 'Failed to load trades',
    },
  ).interact();

  List<TradeSummary> trades;
  try {
    trades = await client.listTrades();
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    return Navigation.to(Screen.mainMenu);
  }

  if (trades.isEmpty) {
    print('  No trades found.');
    pressAnyKey();
    return Navigation.to(Screen.mainMenu);
  }

  // ── Selection (already sorted by daemon: pending first, then updatedAt) ─
  final options = trades.map((t) {
    final short =
        t.tradeId.length > 12 ? '${t.tradeId.substring(0, 12)}…' : t.tradeId;
    final sats = formatSats(t.amountSats).padLeft(12);
    final status = colorStatus(t.status.padRight(12));
    final time = kDimStyle.render(relativeTime(t.updatedAt));
    return '$short  $sats sats  $status  $time';
  }).toList();

  final idx = SelectOrBack(prompt: 'Trades', options: options).interact();

  if (idx == -1) {
    return Navigation.to(Screen.mainMenu);
  }

  return Navigation(
    Screen.tradeDetail,
    selectedTradeId: trades[idx].tradeId,
  );
}
