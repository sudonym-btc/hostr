import 'package:flutter/foundation.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.dev])
class DevelopmentConfig extends Config {
  @override
  RootstockConfig rootstock = DevelopmentRootstockConfig();

  @override
  String get hostrBlossom => 'http://blossom.hostr.development';

  @override
  String get hostrRelay =>
      kIsWeb ? 'ws://relay.hostr.development' : 'wss://relay.hostr.development';
}

class DevelopmentRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 33;
  @override
  BoltzConfig get boltz => DevelopmentBoltzConfig();
  @override
  String get rpcUrl => 'http://localhost:8545';
}

class DevelopmentBoltzConfig extends BoltzConfig {
  @override
  String apiUrl = 'http://localhost:9001/v2'; //'https://api.testnet.boltz.exchange/v2';

  @override
  String get rifRelayUrl => 'http://localhost:8090';
  @override
  String get rifRelayCallVerifier =>
      '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707';
  @override
  String get rifRelayDeployVerifier =>
      '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';
  @override
  String get rifSmartWalletFactoryAddress =>
      '0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE';
}
