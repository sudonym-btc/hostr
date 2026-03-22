import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/stubs/keypairs.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.mock])
class MockConfig extends Config {
  @override
  bool get useSecureKeyValueStorage => false;

  @override
  List<String> get bootstrapEscrowPubkeys => [MockKeys.escrow.publicKey];

  /// No relay — [InMemoryRequests] handles everything in-process.
  @override
  List<String> get relays => [];

  @override
  String hostrRelay = '';

  @override
  String get hostrBlossom => '';

  @override
  RootstockConfig rootstock = MockRootstockConfig();

  @override
  String get googleMapsApiKey => 'mock-key';
}

class MockRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 412346;
  @override
  BoltzConfig get boltz => MockBoltzConfig();
  @override
  AccountAbstractionConfig get accountAbstraction =>
      MockAccountAbstractionConfig();
  @override
  String get rpcUrl => 'http://localhost:8545';
}

class MockBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'https://api.testnet.boltz.exchange/v2';

  @override
  // TODO: implement wsUrl
  String get wsUrl => throw UnimplementedError();
}

class MockAccountAbstractionConfig extends AccountAbstractionConfig {
  @override
  String get bundlerUrl => 'http://localhost:3010/rpc';

  @override
  String get entryPointAddress => '0x0000000000000000000000000000000000000000';

  @override
  String get accountFactoryAddress =>
      '0x0000000000000000000000000000000000000000';

  @override
  String get paymasterAddress => '0x0000000000000000000000000000000000000000';
}
