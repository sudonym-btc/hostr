import 'package:marketplace_evm/marketplace_evm.dart';
import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:injectable/injectable.dart';
import 'package:marketplace_models/stubs/keypairs.dart';

import '../../../injection.dart';
import 'base.config.dart';

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
  EvmConfig evmConfig = env.evmConfig;

  @override
  String get googleMapsApiKey => 'test-key';
}
