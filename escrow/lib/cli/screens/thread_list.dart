import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:escrow/shared/protocol.dart';
import 'package:interact_cli/interact_cli.dart';

/// Lists all synced threads and lets the user select one.
Future<Navigation> threadListScreen(DaemonClient client) async {
  // ── Loading ────────────────────────────────────────────────────────────
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading threads…',
      SpinnerStateType.done => 'Threads loaded',
      SpinnerStateType.failed => 'Failed to load threads',
    },
  ).interact();

  List<ThreadSummary> threads;
  try {
    threads = await client.listThreads();
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    return Navigation.to(Screen.mainMenu);
  }

  if (threads.isEmpty) {
    print('  No threads found.');
    pressAnyKey();
    return Navigation.to(Screen.mainMenu);
  }

  // ── Resolve display names ──────────────────────────────────────────────
  final allPubkeys = threads.expand((t) => t.participants).toSet().toList();
  Map<String, String?> names;
  try {
    names = await client.resolveNames(allPubkeys);
  } catch (_) {
    names = {};
  }

  String label(String pk) {
    final name = names[pk];
    final short = pk.substring(0, 5);
    return name != null ? '$name ($short)' : short;
  }

  // ── Selection ──────────────────────────────────────────────────────────
  final options = threads.map((t) {
    final who = t.participants.map(label).join(', ');
    final preview = t.lastMessage != null && t.lastMessage!.isNotEmpty
        ? (t.lastMessage!.length > 40
            ? '${t.lastMessage!.substring(0, 40)}…'
            : t.lastMessage!)
        : '(no messages)';
    return '$who  (${t.messageCount} msgs)  $preview';
  }).toList();

  final idx = SelectOrBack(prompt: 'Threads', options: options).interact();

  if (idx == -1) {
    return Navigation.to(Screen.mainMenu);
  }

  return Navigation(
    Screen.threadDetail,
    selectedThreadId: threads[idx].anchor,
  );
}
