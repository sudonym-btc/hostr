import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import 'base.config.dart';
import 'development.config.dart';

@Injectable(as: Config, env: [Env.test])
class TestConfig extends Config {
  @override
  bool get useSecureKeyValueStorage => false;

  @override
  String get hostrRelay => 'ws://localhost:5432';

  @override
  String get hostrBlossom => 'http://localhost:3001';

  @override
  RootstockConfig rootstock = DevelopmentRootstockConfig();
}
