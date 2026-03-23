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
  EvmConfig evmConfig = EvmConfig(
    boltz: BoltzConfig(apiUrl: 'https://api.boltz.exchange/v2'),
    chains: [
      EvmChainConfig(
        id: 'arbitrum',
        chainId: 42161,
        rpcUrl: 'https://arb1.arbitrum.io/rpc',
        accountAbstraction: envBackedAAConfig(),
        tokens: arbitrumMainnetTokens,
      ),
    ],
  );
  @override
  String get tipsAddress => 'paco@walletofsatoshi.com';
  @override
  String get googleMapsApiKey => requiredBuildConfig(
    'GOOGLE_MAPS_API_KEY',
    const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
  );
}
