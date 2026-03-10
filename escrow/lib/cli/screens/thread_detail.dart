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

  // ── Resolve display names ──────────────────────────────────────────────
  Map<String, String?> names;
  try {
    names = await client.resolveNames(participants);
  } catch (_) {
    names = {};
  }

  String label(String pk) {
    final name = names[pk];
    final short = pk.substring(0, 5);
    return name != null ? '$name ($short)' : short;
  }

  // ── Display messages ───────────────────────────────────────────────────
  print('');
  print('── Thread: $threadId ──');
  print('   Participants: ${participants.map(label).join(', ')}');
  print('');

  if (messages.isEmpty) {
    print('  (no messages)');
  } else {
    for (final msg in messages) {
      _printMessage(msg, names);
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
      return Navigation(Screen.threadDetail, selectedThreadId: threadId);
    } catch (e) {
      print('  Send error: $e');
    }
  }

  // ── What next? ─────────────────────────────────────────────────────────
  final actions = [
    'Refresh this thread',
    'View Trade',
  ];

  final idx = SelectOrBack(prompt: 'Next', options: actions).interact();

  switch (idx) {
    case 0:
      return Navigation(Screen.threadDetail, selectedThreadId: threadId);
    case 1:
      return Navigation(Screen.tradeDetail, selectedTradeId: threadId);
    case -1:
    default:
      return Navigation.to(Screen.threadList);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

void _printMessage(ThreadMessage msg, Map<String, String?> names) {
  final name = names[msg.pubKey];
  final short = msg.pubKey.substring(0, 5);
  final sender = name != null ? '$name ($short)' : short;
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
