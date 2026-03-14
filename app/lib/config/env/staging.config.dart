import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import 'base.config.dart';

@Injectable(as: Config, env: [Env.staging])
class StagingConfig extends Config {
  /// Hostr escrow daemon's Nostr pubkey.
  /// Derived from the ESCROW_PRIVATE_KEY in staging Secret Manager.
  static const _hostrEscrowPubkey =
      '84d4dd964730c6cd1b901b0bb60a60ca4fb085878efd577b7a3ad60872772c5e';

  static const _grafanaOtlpEndpoint =
      'https://otlp-gateway-prod-us-east-3.grafana.net/otlp';

  static const _grafanaOtlpHeaders = {
    'Authorization':
        'Basic MTU1MzMxMjpnbGNfZXlKdklqb2lNVFk1TkRBMk1TSXNJbTRpT2lKbmNtRm1ZVzVoTFhOMFlXZHBibWNpTENKcklqb2lPWGxWUmtRM1J6VklaR0pxVnpnMVJEWTNZakpSTURoaElpd2liU0k2ZXlKeUlqb2ljSEp2WkMxMWN5MWxZWE4wTFRNaWZYMD0=',
  };

  @override
  List<String> get bootstrapEscrowPubkeys => [_hostrEscrowPubkey];

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
  RifRelayConfig get rifRelay => ProductionRifRelayConfig();

  @override
  RootstockSupportedContractsConfig get supportedContracts =>
      DefaultRootstockSupportedContractsConfig(
        multiEscrow: DefaultSupportedEscrowContractConfig(
          rifRelay: ProductionRifRelayConfig(),
        ),
      );
}

class ProductionBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'https://api.boltz.exchange/v2';
}

class ProductionRifRelayConfig extends RifRelayConfig {
  @override
  String get url => 'https://boltz.mainnet.relay.rifcomputing.net';

  @override
  String get callVerifier => '0xe221608F3FaBbeDfFb7537F8a9001e80654f55C8';

  @override
  String get deployVerifier => '0xc0F5bEF6b20Be41174F826684c663a8635c6A081';

  @override
  String get smartWalletFactoryAddress =>
      '0x44944a80861120B58cc48B066d57cDAf5eC213dd';
}
