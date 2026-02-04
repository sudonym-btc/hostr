import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.mock])
class MockConfig extends Config {
  @override
  List<String> relays = ['ws://localhost:5432'];
  @override
  String hostrRelay = 'ws://localhost:5432';

  @override
  List<String> blossom = ['http://localhost:3001'];
  @override
  RootstockConfig rootstock = MockRootstockConfig();
}

class MockRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 33;
  @override
  BoltzConfig get boltz => MockBoltzConfig();
  @override
  String get rpcUrl => 'http://localhost:8545';
}

class MockBoltzConfig extends BoltzConfig {
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
  String get apiUrl => 'https://api.testnet.boltz.exchange/v2';

  @override
  // TODO: implement wsUrl
  String get wsUrl => throw UnimplementedError();
}
