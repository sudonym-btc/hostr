import 'dart:io';

import 'package:args/args.dart';
import 'package:hostr_cli/src/config/cli_environment.dart';
import 'package:hostr_cli/src/context/hostr_cli_context.dart';
import 'package:hostr_cli/src/daemon/stdio_daemon.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'stdio',
      defaultsTo: true,
      help: 'Serve newline-delimited JSON-RPC over stdin/stdout.',
    )
    ..addOption('env', defaultsTo: 'production')
    ..addOption('relay', help: 'Override the Hostr relay URL.')
    ..addOption('state-dir', defaultsTo: p.join(_homeDirectory(), '.hostr-cli'))
    ..addFlag(
      'allow-insecure-file-secrets',
      defaultsTo: false,
      help:
          'Allow file-backed secret storage for local development and tests only.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final parsed = parser.parse(args);
  if (parsed['help'] == true) {
    stdout.writeln('hostr-daemon');
    stdout.writeln(parser.usage);
    return;
  }

  final options = HostrCliOptions(
    environment: HostrCliEnvironment.fromName(parsed['env'] as String),
    stateDir: Directory(_expandHome(parsed['state-dir'] as String)),
    json: true,
    dryRun: false,
    allowInsecureFileSecrets:
        parsed['allow-insecure-file-secrets'] == true ||
        Platform.environment['HOSTR_CLI_ALLOW_INSECURE_STORAGE'] == '1' ||
        Platform.environment['HOSTR_CLI_STORAGE'] == 'insecure-file',
    relayOverride: parsed['relay'] as String?,
  );

  final context = await HostrCliRuntimeContext.create(options);
  try {
    await HostrDaemonStdioServer(
      context: context,
      stdin: stdin,
      stdout: stdout,
      stderr: stderr,
    ).serve();
  } finally {
    await context.dispose();
  }
  exit(0);
}

String _homeDirectory() {
  if (Platform.isWindows) {
    return Platform.environment['USERPROFILE'] ?? Directory.current.path;
  }
  return Platform.environment['HOME'] ?? Directory.current.path;
}

String _expandHome(String value) {
  if (value == '~') return _homeDirectory();
  if (value.startsWith('~/')) {
    return p.join(_homeDirectory(), value.substring(2));
  }
  return value;
}
