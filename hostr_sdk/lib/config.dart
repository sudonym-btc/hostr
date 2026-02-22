import 'package:ndk/ndk.dart';

import 'datasources/storage.dart';
import 'util/custom_logger.dart';

class HostrConfig {
  final List<String> bootstrapRelays;
  final List<String> bootstrapBlossom;
  final String hostrRelay;
  final RootstockConfig rootstockConfig;
  final NdkConfig ndkConfig;
  final HostrSDKStorage storage;
  final CustomLogger logger;

  HostrConfig({
    required this.bootstrapRelays,
    required this.bootstrapBlossom,
    required this.hostrRelay,
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
             fetchedRangesEnabled: true,
             engine: NdkEngine.JIT,
             defaultQueryTimeout: Duration(seconds: 10),
             bootstrapRelays: bootstrapRelays,
             //  logLevel: LogLevel.all,
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
