import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import 'base.config.dart';

@Injectable(as: Config, env: [Env.staging])
class StagingConfig extends Config {
  // OTLP traces are proxied through nginx at /otlp/ to avoid CORS and
  // keep the Grafana auth token server-side.
  static const _otlpProxyEndpoint = '/otlp';

  @override
  List<String> get bootstrapEscrowPubkeys => buildConfigList(
    'HOSTR_BOOTSTRAP_ESCROW_PUBKEY',
    const String.fromEnvironment('HOSTR_BOOTSTRAP_ESCROW_PUBKEY'),
  );

  @override
  Telemetry buildTelemetry() => Telemetry(
    serviceName: 'hostr-app',
    enableExport: true,
    otlpEndpoint: _otlpProxyEndpoint,
  );

  @override
  List<String> relays = [];
  @override
  String get hostrBlossom => 'https://blossom.staging.hostr.network';
  @override
  String get hostrRelay => 'wss://relay.staging.hostr.network';
  @override
  EvmConfig evmConfig = EvmConfig(
    boltz: BoltzConfig(apiUrl: 'https://api.boltz.exchange/v2'),
    chains: [
      EvmChainConfig(
        id: 'arbitrum',
        chainId: 42161,
        rpcUrl: 'https://arb1.arbitrum.io/rpc',
        accountAbstraction: envBackedAAConfig(),
        escrowContractAddress: const String.fromEnvironment(
          'ESCROW_CONTRACT_ADDRESS',
        ),
        tokens: arbitrumMainnetTokens,
      ),
    ],
  );
  @override
  String get tipsAddress => 'paco@walletofsatoshi.com';
  @override
  String get googleMapsApiKey => requiredBuildConfig(
    'GOOGLE_MAPS_API_KEY',
    const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
  );
}
