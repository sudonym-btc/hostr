import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.mock, Env.test])
class MockConfig extends Config {
  @override
  List<String> relays = ['ws://localhost:5432'];
  @override
  List<String> blossom = ['http://127.0.0.1:3000'];
  @override
  String rootstockRpcUrl = 'http://localhost:8545';
  @override
  String boltzUrl = 'https://api.testnet.boltz.exchange/v2';
}
