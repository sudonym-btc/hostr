import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';

import 'datasources/storage.dart';
import 'util/custom_logger.dart';

class HostrConfig {
  final List<String> bootstrapRelays;
  final List<String> bootstrapBlossom;
  final List<String> bootstrapEscrowPubkeys;
  final String hostrRelay;
  final RootstockConfig rootstockConfig;
  final NdkConfig ndkConfig;
  final HostrSDKStorage storage;
  final KeyValueStorage keyValueStorage;
  final CustomLogger logger;

  /// Minimum EVM balance (in sats) per address before auto-withdrawal
  /// triggers.  Must be above typical swap-out fees to avoid losing money
  /// on small amounts.
  final int autoWithdrawMinimumSats;

  HostrConfig({
    required this.bootstrapRelays,
    required this.bootstrapBlossom,
    this.bootstrapEscrowPubkeys = const [],
    required this.hostrRelay,
    required this.rootstockConfig,
    this.autoWithdrawMinimumSats = 10000,
    KeyValueStorage? storage,
    NdkConfig? ndk,
    CustomLogger? logs,
  }) : keyValueStorage = storage ?? InMemoryKeyValueStorage(),
       storage = HostrSDKStorage.fromKeyValue(
         storage ?? InMemoryKeyValueStorage(),
       ),
       ndkConfig =
           ndk ??
           NdkConfig(
             eventVerifier: RustEventVerifier(),
             cache: MemCacheManager(),
             fetchedRangesEnabled: true,
             engine: NdkEngine.JIT,
             defaultQueryTimeout: Duration(seconds: 10),
             // We have to bootstrap our relay, which means NDK will immediately make connection attempt
             // If we do not provide bootstrap relays, queries without author param will not be sent to any relays
             bootstrapRelays: [hostrRelay],
             logLevel: LogLevel.warning,
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
