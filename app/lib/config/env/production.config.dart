import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import 'base.config.dart';

@Injectable(as: Config, env: [Env.prod])
class ProductionConfig extends Config {
  @override
  List<String> get bootstrapEscrowPubkeys => buildConfigList(
    'HOSTR_BOOTSTRAP_ESCROW_PUBKEY',
    const String.fromEnvironment('HOSTR_BOOTSTRAP_ESCROW_PUBKEY'),
  );
  @override
  List<String> relays = ['wss://relay.damus.io'];
  @override
  String get hostrBlossom => 'https://blossom.hostr.network';
  @override
  String get hostrRelay => 'wss://relay.hostr.network';
  @override
  RootstockConfig rootstock = ProductionRootstockConfig();
  @override
  String get tipsAddress => 'paco@walletofsatoshi.com';
  @override
  String get googleMapsApiKey => requiredBuildConfig(
    'GOOGLE_MAPS_API_KEY',
    const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
  );
}

class ProductionRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 30;
  @override
  String get rpcUrl => 'https://public-node.rsk.co';

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
