import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/stubs/keypairs.dart';

import '../../../injection.dart';
import 'base.config.dart';

@Injectable(as: Config, env: [Env.mock])
class MockConfig extends Config {
  @override
  bool get useSecureKeyValueStorage => false;

  @override
  List<String> get bootstrapEscrowPubkeys => [MockKeys.escrow.publicKey];

  /// No relay — [InMemoryRequests] handles everything in-process.
  @override
  List<String> get relays => [];

  @override
  String hostrRelay = '';

  @override
  String get hostrBlossom => '';

  @override
  EvmConfig evmConfig = EvmConfig(
    boltz: BoltzConfig(apiUrl: 'https://api.testnet.boltz.exchange/v2'),
    chains: [
      EvmChainConfig(
        id: 'arbitrum-regtest',
        chainId: 412346,
        rpcUrl: 'http://localhost:8545',
        nativeDenomination: 'ETH',
        accountAbstraction: AAConfig(
          bundlerUrl: 'http://localhost:3010/rpc',
          entryPointAddress: '0x0000000000000000000000000000000000000000',
          accountFactoryAddress: '0x0000000000000000000000000000000000000000',
          paymasterAddress: '0x0000000000000000000000000000000000000000',
        ),
      ),
    ],
  );

  @override
  String get googleMapsApiKey => 'mock-key';
}
