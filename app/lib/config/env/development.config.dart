import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.dev])
class DevelopmentConfig extends Config {
  @override
  List<String> relays = ['ws://relay:8080'];
  @override
  List<String> blossom = ['http://127.0.0.1:3000'];
  @override
  String rootstockRpcUrl =
      'http://localhost:8545'; //'https://public-node.testnet.rsk.co';
  @override
  String boltzUrl =
      'https://api.boltz.exchange/v2'; //'https://api.testnet.boltz.exchange/v2';
}
