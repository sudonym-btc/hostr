import 'package:hostr_sdk/datasources/storage.dart';
import 'package:ndk/ndk.dart';

class HostrConfig {
  final List<String> bootstrapRelays;
  final List<String> bootstrapBlossom;
  final RootstockConfig rootstockConfig;
  final NdkConfig ndkConfig;
  final HostrSDKStorage storage;

  HostrConfig({
    required this.bootstrapRelays,
    required this.bootstrapBlossom,
    required this.rootstockConfig,
    KeyValueStorage? storage,
    NdkConfig? ndk,
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
           );
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
