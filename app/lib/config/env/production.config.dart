import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

import 'base.config.dart';

@Injectable(as: Config, env: [Env.prod])
class ProductionConfig extends Config {
  @override
  List<String> relays = ['wss://relay.damus.io'];
  @override
  List<String> blossom = ['https://blossom.hostr.network'];
  @override
  String rootstockRpcUrl = 'https://public-node.rsk.co';
  @override
  String boltzUrl = 'https://api.boltz.exchange/v2';
}
