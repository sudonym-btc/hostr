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
  int get chainId => 33;
  @override
  BoltzConfig get boltz => MockBoltzConfig();
  @override
  RifRelayConfig get rifRelay => MockRifRelayConfig();
  @override
  RootstockSupportedContractsConfig get supportedContracts =>
      DefaultRootstockSupportedContractsConfig(
        multiEscrow: DefaultSupportedEscrowContractConfig(
          rifRelay: MockRifRelayConfig(),
        ),
      );
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

class MockRifRelayConfig extends RifRelayConfig {
  @override
  // TODO: implement rifRelayCallVerifier
  String get callVerifier => throw UnimplementedError();

  @override
  // TODO: implement rifRelayDeployVerifier
  String get deployVerifier => throw UnimplementedError();

  @override
  // TODO: implement rifRelayUrl
  String get url => throw UnimplementedError();

  @override
  // TODO: implement rifSmartWalletFactoryAddress
  String get smartWalletFactoryAddress => throw UnimplementedError();
}
