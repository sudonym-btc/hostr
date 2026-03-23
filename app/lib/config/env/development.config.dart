import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.dev])
class DevelopmentConfig extends Config {
  @override
  EvmConfig evmConfig = EvmConfig(
    boltz: BoltzConfig(apiUrl: 'https://boltz.hostr.development/v2'),
    chains: [
      EvmChainConfig(
        id: 'arbitrum-regtest',
        chainId: 412346,
        rpcUrl: 'https://arbitrum.hostr.development',
        accountAbstraction: envBackedAAConfig(),
        tokens: envBackedTokens(),
      ),
    ],
  );

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
