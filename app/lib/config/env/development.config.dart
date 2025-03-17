import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.dev])
class DevelopmentConfig extends Config {
  @override
  List<String> relays = ['ws://relay.hostr.development'];
  @override
  List<String> blossom = ['http://blossom.hostr.development'];
  @override
  String rootstockRpcUrl =
      'http://localhost:8545'; //'https://public-node.testnet.rsk.co';
  @override
  String boltzUrl =
      'http://localhost:9001/v2'; //'https://api.testnet.boltz.exchange/v2';
}
