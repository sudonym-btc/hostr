import 'dart:convert';
import 'dart:io';

import 'seed/relay_seed.dart';
import 'seed/seed_models.dart';

Future<void> main(List<String> arguments) async {
  String? relayUrl;
  String? rpcUrl;
  bool? fundProfiles;
  BigInt? fundAmountWei;
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
      relayUrl = deterministicConfig.relayUrl;
      rpcUrl = deterministicConfig.rpcUrl;
      fundProfiles = deterministicConfig.fundProfiles;
      fundAmountWei = deterministicConfig.fundAmountWei;
    } else if (arg.startsWith('--config-file=')) {
      final path = arg.substring('--config-file='.length);
      final raw = await File(path).readAsString();
      final json = jsonDecode(raw);
      final map = Map<String, dynamic>.from(json as Map);
      deterministicConfig = DeterministicSeedConfig.fromJson(map);
      relayUrl = deterministicConfig.relayUrl;
      rpcUrl = deterministicConfig.rpcUrl;
      fundProfiles = deterministicConfig.fundProfiles;
      fundAmountWei = deterministicConfig.fundAmountWei;
    } else if (arg.startsWith('--')) {
      print(
        'Unsupported flag: $arg. relayUrl/rpcUrl/fundProfiles must be provided in config JSON/file.',
      );
      exitCode = 64;
      return;
    }
  }

  if (relayUrl == null || relayUrl.isEmpty) {
    print('Please provide relayUrl in --config-json or --config-file.');
    exitCode = 64;
    return;
  }

  if (rpcUrl == null || rpcUrl.isEmpty) {
    print('Please provide rpcUrl in --config-json or --config-file.');
    exitCode = 64;
    return;
  }

  final seeder = RelaySeeder();
  await seeder.run(
    relayUrl: relayUrl,
    fundProfiles: fundProfiles ?? false,
    rpcUrl: rpcUrl,
    fundAmountWei: fundAmountWei,
    deterministicConfig: deterministicConfig,
  );
}
