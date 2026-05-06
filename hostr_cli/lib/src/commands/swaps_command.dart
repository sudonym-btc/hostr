import 'dart:io';

import 'package:args/command_runner.dart';

import 'action_bridge.dart';
import 'base.dart';

class SwapsCommand extends Command<int> {
  SwapsCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(SwapsListCommand(stdout: stdout, stderr: stderr));
    addSubcommand(SwapsWatchCommand(stdout: stdout, stderr: stderr));
    addSubcommand(SwapsRecoverCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'swaps';

  @override
  final String description =
      'Inspect and recover persisted Hostr Boltz swap operations.';
}

class SwapsListCommand extends HostrCliCommand {
  SwapsListCommand({required super.stdout, required super.stderr}) {
    argParser.addOption(
      'namespace',
      defaultsTo: 'all',
      allowed: const ['all', 'swap_in', 'swap_out'],
      help: 'Which persisted swap namespace to list.',
    );
  }

  @override
  final String name = 'list';

  @override
  final String description = 'List persisted swap-in and swap-out states.';

  @override
  Future<HostrCliResult> runCommand() async {
    return runSharedAction(
      this,
      action: 'hostr.swaps.list',
      input: {'namespace': argResults?['namespace'] as String? ?? 'all'},
    );
  }
}

class SwapsWatchCommand extends HostrCliCommand {
  SwapsWatchCommand({required super.stdout, required super.stderr}) {
    argParser.addOption(
      'swap-id',
      mandatory: true,
      help: 'Persisted Boltz swap id to watch until proof or terminal state.',
    );
  }

  @override
  final String name = 'watch';

  @override
  final String description =
      'Resume an externally paid swap until escrow proof is available.';

  @override
  Future<HostrCliResult> runCommand() async {
    return runSharedAction(
      this,
      action: 'hostr.swaps.watch',
      input: {
        'swapId': (argResults?['swap-id'] as String).trim(),
        'dryRun': dryRun,
      },
    );
  }
}

class SwapsRecoverCommand extends HostrCliCommand {
  SwapsRecoverCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addFlag(
        'background',
        negatable: false,
        help:
            'Only run recovery steps that are safe without foreground payment interaction.',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Run live recovery without interactive confirmation.',
      );
  }

  @override
  final String name = 'recover';

  @override
  final String description =
      'Resume persisted swap operations and attempt refunds where applicable.';

  @override
  Future<HostrCliResult> runCommand() async {
    return runSharedAction(
      this,
      action: 'hostr.swaps.recoverAll',
      input: {'background': argResults?['background'] == true},
      requireYesForLive: true,
    );
  }
}
