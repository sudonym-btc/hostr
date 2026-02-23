import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';

import 'seed/relay_seed.dart';

/// Allow self-signed certificates so the seeder can connect to local
/// relay/blossom/etc. over TLS without a trusted CA chain.
class _PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }
}

Future<void> main(List<String> arguments) async {
  HttpOverrides.global = _PermissiveHttpOverrides();

  // NDK's internal WebSocket transport can fire SocketExceptions from
  // dart:io Timer callbacks when the relay drops the connection or during
  // ndk.destroy(). These are uncatchable with try/catch, so we absorb
  // them here so they don't crash the process with exit code 255.
  await runZonedGuarded(
    () async {
      await _run(arguments);
    },
    (error, stack) {
      // SocketExceptions from a closed relay socket are expected during
      // teardown — log and swallow.
      if (error is SocketException) {
        stderr.writeln(
          '[warn] Ignoring async SocketException during '
          'teardown: $error',
        );
        return;
      }
      // Anything else is unexpected — print and set a non-zero exit code.
      stderr.writeln('[error] Unhandled async error: $error');
      stderr.writeln(stack);
      exitCode = 1;
    },
  );
}

Future<void> _run(List<String> arguments) async {
  SeedPipelineConfig? config;

  final positionalArgs = arguments
      .where((arg) => !arg.startsWith('--'))
      .toList();
  if (positionalArgs.isNotEmpty) {
    print(
      'Positional arguments are not supported. Set relayUrl in config JSON/file.',
    );
    exitCode = 64;
    return;
  }

  for (final arg in arguments) {
    if (arg.startsWith('--config-json=')) {
      final json = jsonDecode(arg.substring('--config-json='.length));
      final map = Map<String, dynamic>.from(json as Map);
      config = SeedPipelineConfig.fromJson(map);
    } else if (arg.startsWith('--config-file=')) {
      final path = arg.substring('--config-file='.length);
      final raw = await File(path).readAsString();
      final json = jsonDecode(raw);
      final map = Map<String, dynamic>.from(json as Map);
      config = SeedPipelineConfig.fromJson(map);
    } else if (arg.startsWith('--')) {
      print(
        'Unsupported flag: $arg. relayUrl/rpcUrl/fundProfiles must be provided in config JSON/file.',
      );
      exitCode = 64;
      return;
    }
  }

  final seeder = RelaySeeder();
  await seeder.runPipeline(config: config ?? const SeedPipelineConfig());
}
