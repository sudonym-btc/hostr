import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.dev])
class DevelopmentConfig extends Config {
  @override
  RootstockConfig rootstock = DevelopmentRootstockConfig();

  @override
  List<String> get bootstrapEscrowPubkeys => buildConfigList(
    'HOSTR_BOOTSTRAP_ESCROW_PUBKEY',
    const String.fromEnvironment('HOSTR_BOOTSTRAP_ESCROW_PUBKEY'),
  );

  @override
  String get hostrBlossom => 'https://blossom.hostr.development';

  @override
  String get hostrRelay => 'wss://relay.hostr.development';

  @override
  String get googleMapsApiKey => requiredBuildConfig(
    'GOOGLE_MAPS_API_KEY',
    const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
  );
}

class DevelopmentRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 33;
  @override
  BoltzConfig get boltz => DevelopmentBoltzConfig();
  @override
  RifRelayConfig get rifRelay => EnvBackedRifRelayConfig();
  @override
  RootstockSupportedContractsConfig get supportedContracts =>
      DefaultRootstockSupportedContractsConfig(
        multiEscrow: DefaultSupportedEscrowContractConfig(
          rifRelay: EnvBackedRifRelayConfig(),
        ),
      );
  @override
  String get rpcUrl => 'https://anvil.hostr.development';
}

class DevelopmentBoltzConfig extends BoltzConfig {
  @override
  String apiUrl = 'https://boltz.hostr.development/v2';
}
