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
  RootstockConfig rootstock = StagingRootstockConfig();
  @override
  String get tipsAddress => 'paco@walletofsatoshi.com';
  @override
  String get googleMapsApiKey => requiredBuildConfig(
    'GOOGLE_MAPS_API_KEY',
    const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
  );
}

class StagingRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 30;
  @override
  String get rpcUrl =>
      'https://rpc.mainnet.rootstock.io/8ahfS5JENd8hLBtvBxTUoA66ru6Ihg-M';

  @override
  BoltzConfig get boltz => ProductionBoltzConfig();

  @override
  RifRelayConfig get rifRelay => EnvBackedRifRelayConfig();

  @override
  RootstockSupportedContractsConfig get supportedContracts =>
      DefaultRootstockSupportedContractsConfig(
        multiEscrow: DefaultSupportedEscrowContractConfig(
          rifRelay: EnvBackedRifRelayConfig(),
        ),
      );
}

class ProductionBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'https://api.boltz.exchange/v2';
}
