import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:escrow/shared/protocol.dart';
import 'package:interact_cli/interact_cli.dart';

/// Shows all messages in a thread with an interactive reply loop.
Future<Navigation> threadDetailScreen(
  DaemonClient client,
  String threadId,
) async {
  // ── Loading ────────────────────────────────────────────────────────────
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading thread…',
      SpinnerStateType.done => 'Thread loaded',
      SpinnerStateType.failed => 'Failed to load thread',
    },
  ).interact();

  List<ThreadMessage> messages;
  List<String> participants;
  try {
    final result = await client.getThread(threadId);
    messages = result.messages;
    participants = result.participants;
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    return Navigation.to(Screen.threadList);
  }

  // ── Display messages ───────────────────────────────────────────────────
  print('');
  print('── Thread: $threadId ──');
  print(
      '   Participants: ${participants.map((p) => p.length > 8 ? '${p.substring(0, 8)}…' : p).join(', ')}');
  print('');

  if (messages.isEmpty) {
    print('  (no messages)');
  } else {
    for (final msg in messages) {
      _printMessage(msg);
    }
  }

  // ── Interactive reply loop ─────────────────────────────────────────────
  print('');
  print('─── Enter a reply, or leave blank to go back ───');

  while (true) {
    final reply = Input(prompt: 'Reply').interact();
    if (reply.trim().isEmpty) break;

    try {
      await client.sendReply(threadId, reply.trim());
      print('  ✓ Sent');
    } catch (e) {
      print('  Send error: $e');
    }
  }

  // ── What next? ─────────────────────────────────────────────────────────
  final actions = [
    'Refresh this thread',
  ];

  final idx = SelectOrBack(prompt: 'Next', options: actions).interact();

  switch (idx) {
    case 0:
      return Navigation(Screen.threadDetail, selectedThreadId: threadId);
    case -1:
    default:
      return Navigation.to(Screen.threadList);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

void _printMessage(ThreadMessage msg) {
  final sender =
      msg.pubKey.length > 8 ? '${msg.pubKey.substring(0, 8)}…' : msg.pubKey;
  final dt =
      DateTime.fromMillisecondsSinceEpoch(msg.createdAt * 1000).toLocal();
  final timeStr =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  final dateStr = '$timeStr, ${dt.day} ${_monthAbbr(dt.month)} ${dt.year}';
  final content = msg.content.isNotEmpty ? msg.content : '[event]';
  print('  $sender: $content');
  print('    $dateStr');
}

String _monthAbbr(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
