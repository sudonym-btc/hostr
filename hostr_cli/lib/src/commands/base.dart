import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../config/cli_environment.dart';
import '../context/hostr_cli_context.dart';
import '../output/result.dart';

export '../output/result.dart';

abstract class HostrCliCommand extends Command<int> {
  HostrCliCommand({required this.stdout, required this.stderr});

  final IOSink stdout;
  final IOSink stderr;

  String get commandPath {
    final names = <String>[];
    Command<dynamic>? current = this;
    while (current != null) {
      if (current.name.isNotEmpty) names.add(current.name);
      current = current.parent;
    }
    return names.reversed.join(' ');
  }

  bool get jsonOutput => globalResults?['json'] == true;
  bool get dryRun => globalResults?['dry-run'] == true;

  HostrCliOptions get cliOptions {
    final rawEnv = (globalResults?['env'] as String?) ?? 'production';
    final rawStateDir =
        (globalResults?['state-dir'] as String?) ??
        p.join(_homeDirectory(), '.hostr-cli');
    final allowInsecure =
        globalResults?['allow-insecure-file-secrets'] == true ||
        Platform.environment['HOSTR_CLI_ALLOW_INSECURE_STORAGE'] == '1' ||
        Platform.environment['HOSTR_CLI_STORAGE'] == 'insecure-file' ||
        Platform.environment['HOSTR_CLI_STORAGE'] == 'file';
    return HostrCliOptions(
      environment: HostrCliEnvironment.fromName(rawEnv),
      stateDir: Directory(_expandHome(rawStateDir)),
      json: jsonOutput,
      dryRun: dryRun,
      allowInsecureFileSecrets: allowInsecure,
      relayOverride: globalResults?['relay'] as String?,
    );
  }

  @override
  Future<int> run() async {
    try {
      final result = await runCommand();
      result.writeTo(stdout, json: jsonOutput);
      return result.ok ? 0 : 1;
    } on HostrCliException catch (error) {
      final result = HostrCliResult(
        ok: false,
        command: commandPath,
        environment: _safeEnvName(),
        dryRun: dryRun,
        errors: [error.toIssue()],
      );
      result.writeTo(jsonOutput ? stdout : stderr, json: jsonOutput);
      return error.exitCode;
    } on UsageException catch (error) {
      stderr.writeln(error);
      return 64;
    } catch (error) {
      final result = HostrCliResult(
        ok: false,
        command: commandPath,
        environment: _safeEnvName(),
        dryRun: dryRun,
        errors: [
          HostrCliIssue(
            code: 'unexpected_error',
            message: error.toString(),
            retryable: false,
          ),
        ],
      );
      result.writeTo(jsonOutput ? stdout : stderr, json: jsonOutput);
      return 1;
    }
  }

  Future<HostrCliResult> runCommand();

  Future<HostrCliContext> createContext() => HostrCliContext.create(cliOptions);

  HostrCliResult ok(Object? data, {List<HostrCliIssue> warnings = const []}) {
    return HostrCliResult(
      ok: true,
      command: commandPath,
      environment: _safeEnvName(),
      dryRun: dryRun,
      data: data,
      warnings: warnings,
    );
  }

  HostrCliResult failure(
    String code,
    String message, {
    String? path,
    String? hint,
    bool retryable = false,
    Object? details,
  }) {
    return HostrCliResult(
      ok: false,
      command: commandPath,
      environment: _safeEnvName(),
      dryRun: dryRun,
      errors: [
        HostrCliIssue(
          code: code,
          message: message,
          path: path,
          hint: hint,
          retryable: retryable,
          details: details,
        ),
      ],
    );
  }

  Map<String, dynamic> readInputObject() {
    final raw = argResults?['input'] as String?;
    if (raw == null || raw.trim().isEmpty) {
      throw HostrCliException(
        'missing_input',
        'Pass --input with a JSON file path, "-" for stdin, or an inline JSON object.',
        exitCode: 64,
      );
    }
    final source = raw == '-'
        ? _readStdinSync()
        : raw.trimLeft().startsWith('{')
        ? raw
        : File(_expandHome(raw)).readAsStringSync();
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw HostrCliException(
        'invalid_input',
        'Input must be a JSON object.',
        exitCode: 64,
      );
    }
    return decoded;
  }

  List<String> stringListOption(String name) {
    final values = argResults?[name];
    if (values is List) return values.map((value) => value.toString()).toList();
    if (values is String && values.trim().isNotEmpty) {
      return values.split(',').map((value) => value.trim()).toList();
    }
    return const [];
  }

  String _safeEnvName() {
    try {
      return cliOptions.environment.name;
    } catch (_) {
      return (globalResults?['env'] as String?) ?? 'production';
    }
  }
}

String _readStdinSync() {
  final bytes = <int>[];
  while (true) {
    final byte = stdin.readByteSync();
    if (byte == -1) break;
    bytes.add(byte);
  }
  return utf8.decode(bytes);
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

extension RequiredArg on Map<String, dynamic> {
  T require<T>(String key) {
    final value = this[key];
    if (value is T) return value;
    throw HostrCliException(
      'missing_field',
      'Missing or invalid field "$key".',
      path: key,
      exitCode: 64,
    );
  }
}
