import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/stubs/keypairs.dart';

import '../../../injection.dart';
import 'base.config.dart';
import 'development.config.dart';

@Injectable(as: Config, env: [Env.test])
class TestConfig extends Config {
  @override
  bool get useSecureKeyValueStorage => false;

  @override
  List<String> get bootstrapEscrowPubkeys => [MockKeys.escrow.publicKey];

  /// No relay — [InMemoryRequests] handles everything in-process.
  @override
  List<String> get relays => [];

  @override
  String get hostrRelay => '';

  @override
  String get hostrBlossom => '';

  @override
  RootstockConfig rootstock = DevelopmentRootstockConfig();
}
