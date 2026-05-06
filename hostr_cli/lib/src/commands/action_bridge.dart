import '../context/hostr_cli_context.dart';
import '../daemon/hostr_daemon.dart';
import 'base.dart';

Future<HostrCliResult> runSharedAction(
  HostrCliCommand command, {
  required String action,
  required Map<String, dynamic> input,
  bool requireYesForLive = false,
}) async {
  final effectiveInput = <String, dynamic>{...input};
  if (command.dryRun) {
    effectiveInput['dryRun'] = true;
  } else if (requireYesForLive) {
    effectiveInput['dryRun'] = effectiveInput['dryRun'] == true;
  } else if (effectiveInput.containsKey('dryRun')) {
    effectiveInput['dryRun'] = effectiveInput['dryRun'] == true;
  }

  final context = await HostrCliRuntimeContext.create(command.cliOptions);
  try {
    if (requireYesForLive &&
        effectiveInput['dryRun'] != true &&
        command.argResults?['yes'] != true) {
      final session = await context.runtime.foregroundSession();
      await session.ensureInitialized();
      final pubkey = session.auth.activePubkey;
      if (pubkey == null || pubkey.isEmpty) {
        return command.failure(
          'auth_required',
          'Action "$action" requires an active Hostr session.',
        );
      }
      return command.failure(
        'confirmation_required',
        'Refusing to run live action without --yes.',
        hint: 'Run with --dry-run first, then add --yes.',
        retryable: true,
      );
    }

    final result = await HostrDaemon(
      context,
    ).callForeground(action: action, input: effectiveInput);
    return HostrCliResult(
      ok: result.ok,
      command: command.commandPath,
      environment: result.environment,
      dryRun: result.dryRun,
      data: result.data,
      warnings: result.warnings,
      errors: result.errors,
    );
  } finally {
    await context.dispose();
  }
}
