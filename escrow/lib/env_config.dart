import 'dart:io';

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
  final List<String> bootstrapRelays;
  final String blossomUrl;
  final EvmConfig evmConfig;

  const EnvConfig({
    required this.relayUrl,
    required this.bootstrapRelays,
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
    // Compose integration profiles like "test,ci" still run against the real
    // relay/chain stack, so they must use the live SDK environment rather
    // than the in-memory SDK test environment.
    if (tokens.contains('test') && tokens.contains('ci')) return 'dev';
    if (tokens.contains('test')) return 'test';
    if (tokens.contains('mock')) return 'mock';
    return 'dev';
  }

  /// Resolve the correct [EnvConfig] for the given [environment] name.
  ///
  /// Falls back to the test/dev config for unrecognised values.
  factory EnvConfig.forEnvironment(String environment) {
    final config = switch (sdkEnvironment(environment)) {
      'staging' => const EnvConfig(
          relayUrl: staging_env.relayUrl,
          bootstrapRelays: staging_env.bootstrapRelays,
          blossomUrl: staging_env.blossomUrl,
          evmConfig: staging_env.evmConfig,
        ),
      'prod' || 'production' => const EnvConfig(
          relayUrl: production_env.relayUrl,
          bootstrapRelays: production_env.bootstrapRelays,
          blossomUrl: production_env.blossomUrl,
          evmConfig: production_env.evmConfig,
        ),
      'dev' || 'mock' => const EnvConfig(
          relayUrl: development_env.relayUrl,
          bootstrapRelays: development_env.bootstrapRelays,
          blossomUrl: development_env.blossomUrl,
          evmConfig: development_env.evmConfig,
        ),
      _ => const EnvConfig(
          relayUrl: test_env.relayUrl,
          bootstrapRelays: test_env.bootstrapRelays,
          blossomUrl: test_env.blossomUrl,
          evmConfig: test_env.evmConfig,
        ),
    };
    return config._withRuntimeOverrides();
  }

  EnvConfig _withRuntimeOverrides() {
    return EnvConfig(
      relayUrl: Platform.environment['HOSTR_RELAY_URL'] ?? relayUrl,
      bootstrapRelays: _runtimeBootstrapRelays(bootstrapRelays),
      blossomUrl: Platform.environment['HOSTR_BLOSSOM_URL'] ?? blossomUrl,
      evmConfig: _evmConfigWithRuntimeOverrides(evmConfig),
    );
  }

  static List<String> _runtimeBootstrapRelays(List<String> defaults) {
    final value = Platform.environment['HOSTR_BOOTSTRAP_RELAYS'] ??
        Platform.environment['BOOTSTRAP_RELAYS'];
    if (value == null) return defaults;

    final relays = value
        .split(',')
        .map((relay) => relay.trim())
        .where((relay) => relay.isNotEmpty)
        .toList(growable: false);
    return relays.isEmpty ? defaults : relays;
  }

  static EvmConfig _evmConfigWithRuntimeOverrides(EvmConfig config) {
    return EvmConfig(
      boltz: config.boltz,
      chains: [
        for (final chain in config.chains)
          EvmChainConfig(
            id: chain.id,
            chainId: chain.chainId,
            rpcUrls: _runtimeRpcUrls(chain),
            blockExplorerUrl: chain.blockExplorerUrl,
            nativeDenomination: chain.nativeDenomination,
            boltzCurrency: chain.boltzCurrency,
            accountAbstraction: chain.accountAbstraction,
            escrowContractAddress: chain.escrowContractAddress,
            tokens: chain.tokens,
          ),
      ],
    );
  }

  static List<String> _runtimeRpcUrls(EvmChainConfig chain) {
    final value = Platform.environment[_chainEnvKey(chain.id, 'RPC_URL')];
    if (value == null) return chain.rpcUrls;

    final urls = value
        .split(',')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    return urls.isEmpty ? chain.rpcUrls : urls;
  }

  static String _chainEnvKey(String chainId, String suffix) {
    final normalized = chainId.toUpperCase().replaceAll('-', '_');
    return 'EVM_CHAIN_${normalized}_$suffix';
  }
}
