import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';
import 'development.config.dart';

@Injectable(as: Config, env: [Env.test])
class TestConfig extends Config {
  @override
  List<String> relays = ['ws://localhost:5432'];
  @override
  String hostrRelay = 'ws://localhost:5432';

  @override
  List<String> blossom = ['http://localhost:3001'];
  @override
  RootstockConfig rootstock = DevelopmentRootstockConfig();
}
