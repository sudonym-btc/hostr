import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import 'base.config.dart';

@Injectable(as: Config, env: [Env.prod])
class ProductionConfig extends Config {
  @override
  List<String> relays = ['wss://relay.damus.io'];
  @override
  String get hostrBlossom => 'https://blossom.hostr.network';
  @override
  String get hostrRelay => 'wss://relay.hostr.network';
  @override
  RootstockConfig rootstock = ProductionRootstockConfig();
}

class ProductionRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 30;
  @override
  String get rpcUrl => 'https://public-node.rsk.co';

  @override
  // TODO: implement boltz
  BoltzConfig get boltz => ProductionBoltzConfig();
}

class ProductionBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'https://api.boltz.exchange/v2';

  @override
  // TODO: implement rifRelayCallVerifier
  String get rifRelayCallVerifier => throw UnimplementedError();

  @override
  // TODO: implement rifRelayDeployVerifier
  String get rifRelayDeployVerifier => throw UnimplementedError();

  @override
  // TODO: implement rifRelayUrl
  String get rifRelayUrl => throw UnimplementedError();

  @override
  // TODO: implement rifSmartWalletFactoryAddress
  String get rifSmartWalletFactoryAddress => throw UnimplementedError();

  @override
  // TODO: implement wsUrl
  String get wsUrl => throw UnimplementedError();
}
