import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/diagnostics_command.dart';
import 'commands/escrow_methods_command.dart';
import 'commands/inbox_command.dart';
import 'commands/listings_command.dart';
import 'commands/profile_command.dart';
import 'commands/reservations_command.dart';
import 'commands/session_command.dart';
import 'commands/swaps_command.dart';

Future<int> runHostrCli(
  List<String> arguments, {
  required IOSink stdout,
  required IOSink stderr,
}) async {
  final runner =
      CommandRunner<int>(
          'hostr',
          'Hostr command-line interface for desktop agents.',
        )
        ..argParser.addOption(
          'env',
          defaultsTo: 'production',
          allowed: [
            'development',
            'dev',
            'local',
            'test',
            'staging',
            'production',
            'prod',
          ],
          help: 'Hostr environment.',
        )
        ..argParser.addOption(
          'relay',
          help: 'Override the Hostr relay URL for this invocation.',
        )
        ..argParser.addOption(
          'state-dir',
          help: 'Directory for CLI database and local state.',
        )
        ..argParser.addFlag(
          'json',
          negatable: false,
          help: 'Write machine-readable JSON result envelopes.',
        )
        ..argParser.addFlag(
          'dry-run',
          negatable: false,
          help:
              'Validate and build planned effects without publishing, uploading, or transacting.',
        )
        ..argParser.addFlag(
          'allow-insecure-file-secrets',
          negatable: false,
          help:
              'Use a chmod 600 JSON secrets file when no OS secure store is available. Development only.',
        )
        ..addCommand(SessionCommand(stdout: stdout, stderr: stderr))
        ..addCommand(ProfileCommand(stdout: stdout, stderr: stderr))
        ..addCommand(ListingsCommand(stdout: stdout, stderr: stderr))
        ..addCommand(ReservationsCommand(stdout: stdout, stderr: stderr))
        ..addCommand(EscrowMethodsCommand(stdout: stdout, stderr: stderr))
        ..addCommand(SwapsCommand(stdout: stdout, stderr: stderr))
        ..addCommand(TripsCommand(stdout: stdout, stderr: stderr))
        ..addCommand(BookingsCommand(stdout: stdout, stderr: stderr))
        ..addCommand(InboxCommand(stdout: stdout, stderr: stderr))
        ..addCommand(DiagnosticsCommand(stdout: stdout, stderr: stderr));

  try {
    return await runner.run(arguments) ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    return 64;
  }
}
