import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:models/main.dart';

import 'base.dart';

class DiagnosticsCommand extends Command<int> {
  DiagnosticsCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(DiagnosticsNativeCommand(stdout: stdout, stderr: stderr));
    addSubcommand(DiagnosticsConfigCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'diagnostics';

  @override
  final String description =
      'Inspect CLI runtime configuration and native libraries.';
}

class DiagnosticsNativeCommand extends HostrCliCommand {
  DiagnosticsNativeCommand({required super.stdout, required super.stderr});

  @override
  final String name = 'native';

  @override
  final String description = 'Verify H3 and secp256k1 native backend loading.';

  @override
  Future<HostrCliResult> runCommand() async {
    Object? h3Error;
    String? h3Backend;
    try {
      H3Engine.bundled();
      h3Backend = describeH3BackendSelection();
    } catch (error) {
      h3Error = error.toString();
    }

    await loadSecp256k1Backend();
    final h3 = <String, Object?>{
      'ok': h3Error == null,
      'backend': h3Backend ?? describeH3BackendSelection(),
    };
    if (h3Error != null) {
      h3['error'] = h3Error;
    }
    final secp256k1LoadError = getSecp256k1LoadError();
    final secp256k1 = <String, Object?>{
      'fastBackendLoaded': isFastSecp256k1BackendLoaded(),
      'backend': describeSecp256k1Backend(),
    };
    if (secp256k1LoadError != null) {
      secp256k1['loadError'] = secp256k1LoadError.toString();
    }
    return ok({
      'h3': h3,
      'secp256k1': secp256k1,
      'platform': {
        'operatingSystem': Platform.operatingSystem,
        'resolvedExecutable': Platform.resolvedExecutable,
      },
    });
  }
}

class DiagnosticsConfigCommand extends HostrCliCommand {
  DiagnosticsConfigCommand({required super.stdout, required super.stderr});

  @override
  final String name = 'config';

  @override
  final String description = 'Show resolved CLI environment configuration.';

  @override
  Future<HostrCliResult> runCommand() async {
    final options = cliOptions;
    return ok({
      'environment': options.environment.name,
      'sdkEnvironment': options.environment.sdkEnvironment,
      'hostrRelay': options.relayOverride ?? options.environment.hostrRelay,
      'bootstrapRelays': options.environment.bootstrapRelays,
      'bootstrapBlossom': options.environment.bootstrapBlossom,
      'bootstrapEscrowPubkeys': options.environment.bootstrapEscrowPubkeys,
      'stateDir': options.stateDir.path,
      'allowInsecureFileSecrets': options.allowInsecureFileSecrets,
    });
  }
}
