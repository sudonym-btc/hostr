import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';

import 'seed/relay_seed.dart';
import 'seed/seed_models.dart';

Future<void> main(List<String> arguments) async {
  SeedPipelineConfig? pipelineConfig;
  DeterministicSeedConfig? legacyConfig;

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
      // Detect pipeline config by presence of 'threadStages' or 'userOverrides'.
      if (map.containsKey('threadStages') || map.containsKey('userOverrides')) {
        pipelineConfig = SeedPipelineConfig.fromLegacy(map);
      } else {
        legacyConfig = DeterministicSeedConfig.fromJson(map);
      }
    } else if (arg.startsWith('--config-file=')) {
      final path = arg.substring('--config-file='.length);
      final raw = await File(path).readAsString();
      final json = jsonDecode(raw);
      final map = Map<String, dynamic>.from(json as Map);
      if (map.containsKey('threadStages') || map.containsKey('userOverrides')) {
        pipelineConfig = SeedPipelineConfig.fromLegacy(map);
      } else {
        legacyConfig = DeterministicSeedConfig.fromJson(map);
      }
    } else if (arg.startsWith('--')) {
      print(
        'Unsupported flag: $arg. relayUrl/rpcUrl/fundProfiles must be provided in config JSON/file.',
      );
      exitCode = 64;
      return;
    }
  }

  final seeder = RelaySeeder();

  if (pipelineConfig != null) {
    await seeder.runPipeline(config: pipelineConfig);
  } else if (legacyConfig != null) {
    await seeder.run(config: legacyConfig);
  } else {
    print('No config provided. Using defaults.');
    await seeder.run(config: const DeterministicSeedConfig());
  }
}
