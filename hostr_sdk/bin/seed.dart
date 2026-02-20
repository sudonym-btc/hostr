import 'dart:convert';
import 'dart:io';

import 'seed/relay_seed.dart';
import 'seed/seed_models.dart';

Future<void> main(List<String> arguments) async {
  DeterministicSeedConfig? deterministicConfig;

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
      deterministicConfig = DeterministicSeedConfig.fromJson(map);
    } else if (arg.startsWith('--config-file=')) {
      final path = arg.substring('--config-file='.length);
      final raw = await File(path).readAsString();
      final json = jsonDecode(raw);
      final map = Map<String, dynamic>.from(json as Map);
      deterministicConfig = DeterministicSeedConfig.fromJson(map);
    } else if (arg.startsWith('--')) {
      print(
        'Unsupported flag: $arg. relayUrl/rpcUrl/fundProfiles must be provided in config JSON/file.',
      );
      exitCode = 64;
      return;
    }
  }

  if (deterministicConfig == null) {
    print(
      'No config provided. Using defaults. relayUrl/rpcUrl/fundProfiles must be provided in config JSON/file.',
    );
    deterministicConfig = const DeterministicSeedConfig();
  }

  final seeder = RelaySeeder();
  await seeder.run(config: deterministicConfig);
}
