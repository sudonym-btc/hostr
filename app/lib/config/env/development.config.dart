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
  String get hostrRelay => 'wss://relay.hostr.development';

  @override
  String get googleMapsApiKey => 'AIzaSyDbIij_LkLDQTePfWnoLo5bmqhDKS2xXbU';
}

class DevelopmentRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 33;
  @override
  BoltzConfig get boltz => DevelopmentBoltzConfig();
  @override
  RifRelayConfig get rifRelay => DevelopmentRifRelayConfig();
  @override
  RootstockSupportedContractsConfig get supportedContracts =>
      DefaultRootstockSupportedContractsConfig(
        multiEscrow: DefaultSupportedEscrowContractConfig(
          rifRelay: DevelopmentRifRelayConfig(),
        ),
      );
  @override
  String get rpcUrl => 'https://anvil.hostr.development';
}

class DevelopmentBoltzConfig extends BoltzConfig {
  @override
  String apiUrl = 'https://boltz.hostr.development/v2';
}

class DevelopmentRifRelayConfig extends RifRelayConfig {
  @override
  String get url => 'https://rifrelay.hostr.development';
  @override
  String get callVerifier => '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707';
  @override
  String get deployVerifier => '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';
  @override
  String get smartWalletFactoryAddress =>
      '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9';
}
