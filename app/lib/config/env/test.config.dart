import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/stubs/keypairs.dart';

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
  EvmConfig evmConfig = EvmConfig(
    boltz: BoltzConfig(apiUrl: 'https://boltz.hostr.development/v2'),
    chains: [
      EvmChainConfig(
        id: 'arbitrum-regtest',
        chainId: 412346,
        rpcUrl: 'https://arbitrum.hostr.development',
        accountAbstraction: envBackedAAConfig(),
        tokens: envBackedTokens(),
      ),
    ],
  );

  @override
  String get googleMapsApiKey => 'test-key';
}
