import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.mock, Env.test])
class MockConfig extends Config {
  @override
  List<String> relays = [];
  @override
  String rootstockRpcUrl = 'https://public-node.testnet.rsk.co';
  @override
  String boltzUrl = 'https://api.testnet.boltz.exchange/v2';
}
