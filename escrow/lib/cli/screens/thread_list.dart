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
    return Navigation.to(Screen.mainMenu);
  }

  // ── Selection ──────────────────────────────────────────────────────────
  final options = threads.map((t) {
    final short =
        t.anchor.length > 16 ? '${t.anchor.substring(0, 16)}…' : t.anchor;
    final preview = t.lastMessage != null && t.lastMessage!.isNotEmpty
        ? (t.lastMessage!.length > 40
            ? '${t.lastMessage!.substring(0, 40)}…'
            : t.lastMessage!)
        : '(no messages)';
    return '$short  (${t.messageCount} msgs)  $preview';
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
