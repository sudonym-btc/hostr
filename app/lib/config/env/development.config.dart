import 'package:flutter/foundation.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/stubs/keypairs.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.dev])
class DevelopmentConfig extends Config {
  @override
  RootstockConfig rootstock = DevelopmentRootstockConfig();

  @override
  List<String> get bootstrapEscrowPubkeys => [MockKeys.escrow.publicKey];

  @override
  String get hostrBlossom => 'https://blossom.hostr.development';

  @override
  String get hostrRelay => kIsWeb
      ? 'wss://relay.hostr.development'
      : 'wss://relay.hostr.development';
}

class DevelopmentRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 33;
  @override
  BoltzConfig get boltz => DevelopmentBoltzConfig();
  @override
  String get rpcUrl => 'https://anvil.hostr.development';
}

class DevelopmentBoltzConfig extends BoltzConfig {
  @override
  String apiUrl = 'http://boltz.hostr.development:9001/v2';

  @override
  String get rifRelayUrl => 'http://rifrelay.hostr.development:8090';
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
