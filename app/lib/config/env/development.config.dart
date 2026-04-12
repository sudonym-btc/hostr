import 'package:hostr_sdk/config/generated/development_env.g.dart' as env;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.dev])
class DevelopmentConfig extends Config {
  @override
  EvmConfig evmConfig = env.evmConfig;
  @override
  List<String> get bootstrapEscrowPubkeys => env.bootstrapEscrowPubkeys;
  @override
  List<String> get relays => [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.primal.net',
    'wss://purplepag.es',
  ];
  @override
  String get hostrBlossom => env.blossomUrl;
  @override
  String get hostrRelay => env.relayUrl;
  @override
  String get googleMapsApiKey => env.googleMapsApiKey;
  @override
  String get tipsAddress => env.tipsAddress;
}
