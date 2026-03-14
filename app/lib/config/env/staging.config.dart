import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import 'base.config.dart';

@Injectable(as: Config, env: [Env.staging])
class StagingConfig extends Config {
  static const _grafanaOtlpEndpoint =
      'https://otlp-gateway-prod-us-east-3.grafana.net/otlp';

  static const _grafanaOtlpHeaders = {
    'Authorization':
        'Basic MTU1MzMxMjpnbGNfZXlKdklqb2lNVFk1TkRBMk1TSXNJbTRpT2lKbmNtRm1ZVzVoTFhOMFlXZHBibWNpTENKcklqb2lPWGxWUmtRM1J6VklaR0pxVnpnMVJEWTNZakpSTURoaElpd2liU0k2ZXlKeUlqb2ljSEp2WkMxMWN5MWxZWE4wTFRNaWZYMD0=',
  };

  @override
  List<String> get bootstrapEscrowPubkeys => buildConfigList(
    'HOSTR_BOOTSTRAP_ESCROW_PUBKEY',
    const String.fromEnvironment('HOSTR_BOOTSTRAP_ESCROW_PUBKEY'),
  );

  @override
  Telemetry buildTelemetry() => Telemetry(
    serviceName: 'hostr-app',
    enableExport: true,
    otlpEndpoint: _grafanaOtlpEndpoint,
    otlpHeaders: _grafanaOtlpHeaders,
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
  String get googleMapsApiKey => 'AIzaSyDbIij_LkLDQTePfWnoLo5bmqhDKS2xXbU';
}

class StagingRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 30;
  @override
  String get rpcUrl =>
      'https://rpc.mainnet.rootstock.io/KR2OXu4aSUTZRYlXT5tpVVtE2aqEVI-M';

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
