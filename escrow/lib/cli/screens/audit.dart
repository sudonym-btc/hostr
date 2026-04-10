import 'package:artisanal/style.dart';
import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/styles.dart';
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
  print(sectionHeader('Trade Audit: $tradeId'));
  print('');

  // Show party stages in a key-value table.
  final stages = <String, String>{};
  if (result['hasBuyer'] == true) {
    stages['Buyer'] = _styledStage(result['buyerStage']);
  }
  if (result['hasSeller'] == true) {
    stages['Seller'] = _styledStage(result['sellerStage']);
  }
  if (result['hasEscrow'] == true) {
    stages['Escrow'] = _styledStage(result['escrowStage']);
  }
  if (stages.isNotEmpty) {
    print(kvTable(stages));
    print('');
  }

  // Print the formatted report with colourised check/cross marks.
  final formatted = result['formatted'] as String? ?? '(no formatted output)';
  print(_coloriseAuditReport(formatted));
  print('');

  if (result['explanation'] != null) {
    print(kKeyStyle.render('Summary: ') + result['explanation'].toString());
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

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Colourise ✓/✗ and party headers in the plain-text audit report.
String _coloriseAuditReport(String report) {
  final okStyle = Style().foreground(Colors.success);
  final failStyle = Style().foreground(Colors.error);

  return report.split('\n').map((line) {
    // Party section headers: ── Seller (abc123…def456) ──
    if (line.startsWith('──') && line.endsWith('──')) {
      return kHeaderStyle.render(line);
    }
    // Top-level header
    if (line.startsWith('═══')) {
      return kHeaderStyle.render(line);
    }
    // Check / cross lines
    if (line.contains('✓')) {
      return okStyle.render(line);
    }
    if (line.contains('✗')) {
      return failStyle.render(line);
    }
    // Summary line
    if (line.startsWith('Summary:')) {
      return kKeyStyle.render(line);
    }
    return line;
  }).join('\n');
}

/// Style a stage name: green for final stages, yellow for mid-flow, dim if null.
String _styledStage(String? stage) {
  if (stage == null) return kDimStyle.render('unknown');
  final lower = stage.toLowerCase();
  if (lower.contains('complete') || lower.contains('released')) {
    return Style().foreground(Colors.success).render(stage);
  }
  if (lower.contains('dispute') || lower.contains('expired')) {
    return Style().foreground(Colors.error).render(stage);
  }
  return Style().foreground(Colors.warning).render(stage);
}
