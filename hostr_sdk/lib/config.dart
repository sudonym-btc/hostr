import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/ndk.dart';

class HostrConfig {
  final List<String> bootstrapRelays;
  final List<String> bootstrapBlossom;
  final RootstockConfig rootstockConfig;
  final NdkConfig ndkConfig;
  final HostrSDKStorage storage;
  final CustomLogger logger;

  HostrConfig({
    required this.bootstrapRelays,
    required this.bootstrapBlossom,
    required this.rootstockConfig,
    KeyValueStorage? storage,
    NdkConfig? ndk,
    CustomLogger? logs,
  }) : storage = HostrSDKStorage.fromKeyValue(
         storage ?? InMemoryKeyValueStorage(),
       ),
       ndkConfig =
           ndk ??
           NdkConfig(
             eventVerifier: Bip340EventVerifier(),
             cache: MemCacheManager(),
             engine: NdkEngine.JIT,
             defaultQueryTimeout: Duration(seconds: 10),
             bootstrapRelays: bootstrapRelays,
           ),
       logger = logs ?? CustomLogger();
}

abstract class EvmConfig {
  int get chainId;
  String get rpcUrl;
}

abstract class RootstockConfig extends EvmConfig {
  BoltzConfig get boltz;
}

abstract class BoltzConfig {
  String get apiUrl;
  String get wsUrl => '${apiUrl.replaceFirst('http', 'ws')}/ws';

  String get rifRelayUrl;
  String get rifRelayCallVerifier;
  String get rifRelayDeployVerifier;
  String get rifSmartWalletFactoryAddress;
}
