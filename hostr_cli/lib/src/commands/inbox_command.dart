import 'dart:io';

import 'package:args/command_runner.dart';

import 'action_bridge.dart';
import 'base.dart';

class InboxCommand extends Command<int> {
  InboxCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(InboxListCommand(stdout: stdout, stderr: stderr));
    addSubcommand(InboxSendMessageCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'inbox';

  @override
  final String description = 'Read and send Hostr gift-wrapped messages.';
}

class InboxSendMessageCommand extends HostrCliCommand {
  InboxSendMessageCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'input',
        mandatory: true,
        help: 'Message JSON input file, inline object, or "-".',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Broadcast without interactive confirmation.',
      );
  }

  @override
  final String name = 'send-message';

  @override
  final String description = 'Send a text message.';

  @override
  Future<HostrCliResult> runCommand() async {
    return runSharedAction(
      this,
      action: 'hostr.thread.message',
      input: readInputObject(),
      requireYesForLive: true,
    );
  }
}

class InboxListCommand extends HostrCliCommand {
  InboxListCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption('limit', defaultsTo: '50')
      ..addOption('timeout-seconds', defaultsTo: '12');
  }

  @override
  final String name = 'list';

  @override
  final String description = 'List parsed gift-wrapped inbox events.';

  @override
  Future<HostrCliResult> runCommand() async {
    final limit = int.tryParse((argResults?['limit'] as String?) ?? '') ?? 50;
    final timeoutSeconds =
        int.tryParse((argResults?['timeout-seconds'] as String?) ?? '') ?? 12;
    return runSharedAction(
      this,
      action: 'hostr.updates',
      input: {'limit': limit, 'timeoutSeconds': timeoutSeconds},
    );
  }
}
