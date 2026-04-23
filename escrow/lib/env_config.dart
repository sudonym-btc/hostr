import 'package:hostr_sdk/config/generated/development_env.g.dart'
    as development_env;
import 'package:hostr_sdk/config/generated/production_env.g.dart'
    as production_env;
import 'package:hostr_sdk/config/generated/staging_env.g.dart' as staging_env;
import 'package:hostr_sdk/config/generated/test_env.g.dart' as test_env;
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';

/// Runtime-resolved environment configuration.
///
/// Each generated `*_env.g.dart` file defines identically-named top-level
/// constants.  Dart doesn't allow passing library prefixes as values, so this
/// class provides a single place that switches on the environment string and
/// exposes the correct constants.
class EnvConfig {
  final String relayUrl;
  final String blossomUrl;
  final EvmConfig evmConfig;

  const EnvConfig({
    required this.relayUrl,
    required this.blossomUrl,
    required this.evmConfig,
  });

  /// Normalizes compose profiles and user-facing names into SDK env names.
  static String sdkEnvironment(String environment) {
    final tokens = environment
        .split(',')
        .map((token) => token.trim().toLowerCase())
        .where((token) => token.isNotEmpty)
        .toSet();

    if (tokens.contains('prod') || tokens.contains('production')) return 'prod';
    if (tokens.contains('staging')) return 'staging';
    if (tokens.contains('test')) return 'test';
    if (tokens.contains('mock')) return 'mock';
    return 'dev';
  }

  /// Resolve the correct [EnvConfig] for the given [environment] name.
  ///
  /// Falls back to the test/dev config for unrecognised values.
  factory EnvConfig.forEnvironment(String environment) {
    return switch (sdkEnvironment(environment)) {
      'staging' => const EnvConfig(
          relayUrl: staging_env.relayUrl,
          blossomUrl: staging_env.blossomUrl,
          evmConfig: staging_env.evmConfig,
        ),
      'prod' || 'production' => const EnvConfig(
          relayUrl: production_env.relayUrl,
          blossomUrl: production_env.blossomUrl,
          evmConfig: production_env.evmConfig,
        ),
      'dev' || 'mock' => const EnvConfig(
          relayUrl: development_env.relayUrl,
          blossomUrl: development_env.blossomUrl,
          evmConfig: development_env.evmConfig,
        ),
      _ => const EnvConfig(
          relayUrl: test_env.relayUrl,
          blossomUrl: test_env.blossomUrl,
          evmConfig: test_env.evmConfig,
        ),
    };
  }
}
