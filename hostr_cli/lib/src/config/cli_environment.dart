import 'package:hostr_sdk/config/generated/development_env.g.dart' as dev;
import 'package:hostr_sdk/config/generated/production_env.g.dart' as prod;
import 'package:hostr_sdk/config/generated/staging_env.g.dart' as staging;
import 'package:hostr_sdk/config/generated/test_env.g.dart' as test_env;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart' as sdk_injection;

class HostrCliEnvironment {
  const HostrCliEnvironment({
    required this.name,
    required this.sdkEnvironment,
    required this.hostrRelay,
    required this.bootstrapRelays,
    required this.bootstrapBlossom,
    required this.bootstrapEscrowPubkeys,
    required this.evmConfig,
  });

  final String name;
  final String sdkEnvironment;
  final String hostrRelay;
  final List<String> bootstrapRelays;
  final List<String> bootstrapBlossom;
  final List<String> bootstrapEscrowPubkeys;
  final EvmConfig evmConfig;

  HostrCliEnvironment copyWith({
    String? hostrRelay,
    List<String>? bootstrapRelays,
    List<String>? bootstrapBlossom,
  }) {
    return HostrCliEnvironment(
      name: name,
      sdkEnvironment: sdkEnvironment,
      hostrRelay: hostrRelay ?? this.hostrRelay,
      bootstrapRelays: bootstrapRelays ?? this.bootstrapRelays,
      bootstrapBlossom: bootstrapBlossom ?? this.bootstrapBlossom,
      bootstrapEscrowPubkeys: bootstrapEscrowPubkeys,
      evmConfig: evmConfig,
    );
  }

  static HostrCliEnvironment fromName(String input) {
    final normalized = input.trim().toLowerCase();
    switch (normalized) {
      case 'dev':
      case 'development':
      case 'local':
        return const HostrCliEnvironment(
          name: 'development',
          sdkEnvironment: sdk_injection.Env.dev,
          hostrRelay: dev.relayUrl,
          bootstrapRelays: dev.bootstrapRelays,
          bootstrapBlossom: [dev.blossomUrl],
          bootstrapEscrowPubkeys: dev.bootstrapEscrowPubkeys,
          evmConfig: dev.evmConfig,
        );
      case 'test':
        return const HostrCliEnvironment(
          name: 'test',
          sdkEnvironment: sdk_injection.Env.dev,
          hostrRelay: test_env.relayUrl,
          bootstrapRelays: test_env.bootstrapRelays,
          bootstrapBlossom: [test_env.blossomUrl],
          bootstrapEscrowPubkeys: test_env.bootstrapEscrowPubkeys,
          evmConfig: test_env.evmConfig,
        );
      case 'staging':
        return const HostrCliEnvironment(
          name: 'staging',
          sdkEnvironment: sdk_injection.Env.staging,
          hostrRelay: staging.relayUrl,
          bootstrapRelays: staging.bootstrapRelays,
          bootstrapBlossom: [staging.blossomUrl],
          bootstrapEscrowPubkeys: staging.bootstrapEscrowPubkeys,
          evmConfig: staging.evmConfig,
        );
      case 'prod':
      case 'production':
        return const HostrCliEnvironment(
          name: 'production',
          sdkEnvironment: sdk_injection.Env.prod,
          hostrRelay: prod.relayUrl,
          bootstrapRelays: prod.bootstrapRelays,
          bootstrapBlossom: [prod.blossomUrl],
          bootstrapEscrowPubkeys: prod.bootstrapEscrowPubkeys,
          evmConfig: prod.evmConfig,
        );
      default:
        throw ArgumentError.value(
          input,
          'env',
          'Expected development, test, staging, or production',
        );
    }
  }
}
