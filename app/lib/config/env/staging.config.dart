import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import 'base.config.dart';

@Injectable(as: Config, env: [Env.staging])
class StagingConfig extends Config {
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
}

class ProductionBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'https://api.boltz.exchange/v2';

  @override
  String get rifRelayUrl => 'https://boltz.mainnet.relay.rifcomputing.net';

  @override
  String get rifRelayCallVerifier =>
      '0xe221608F3FaBbeDfFb7537F8a9001e80654f55C8';

  @override
  String get rifRelayDeployVerifier =>
      '0xc0F5bEF6b20Be41174F826684c663a8635c6A081';

  @override
  String get rifSmartWalletFactoryAddress =>
      '0x44944a80861120B58cc48B066d57cDAf5eC213dd';
}
