import 'package:ndk/ndk.dart';
import 'package:sqlite3/common.dart';

// import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';

import 'datasources/operations_database.dart';
import 'datasources/storage.dart';
import 'usecase/calendar/calendar.dart';
import 'util/custom_logger.dart';
import 'util/telemetry.dart';

/// Returns [RustEventVerifier] when the native library is available,
/// otherwise falls back to the pure-Dart [Bip340EventVerifier].
EventVerifier _defaultEventVerifier() {
  // try {
  //   return RustEventVerifier();
  // } catch (_) {
  return Bip340EventVerifier();
  // }
}

/// Test-only verifier that accepts every event immediately.
///
/// Useful for profiling whether time is being spent in NDK signature
/// verification versus downstream subscription handling.
class TrustAllEventVerifier implements EventVerifier {
  const TrustAllEventVerifier();

  @override
  Future<bool> verify(Nip01Event event) async => true;
}

/// Platform-agnostic notification callback.
///
/// Mirrors the signature of `FlutterLocalNotificationsPlugin.show()` so the
/// app layer can forward straight through, but keeps the SDK free of any
/// Flutter UI dependency.
typedef ShowNotification =
    Future<void> Function({
      required int id,
      String? title,
      String? body,
      String? payload,
    });

/// Optional bootstrap hook for selecting the active `cryptography` backend.
///
/// The Flutter app can set `Cryptography.instance` from
/// `package:cryptography_flutter` here while the SDK remains free of any
/// Flutter dependency.
typedef ConfigureCryptography = void Function();

class HostrConfig {
  final List<String> bootstrapRelays;
  final List<String> bootstrapBlossom;
  final List<String> bootstrapEscrowPubkeys;
  final String hostrRelay;
  final RootstockConfig rootstockConfig;
  final NdkConfig ndkConfig;
  final HostrSDKStorage storage;
  final KeyValueStorage keyValueStorage;
  final CommonDatabase operationsDb;
  final CustomLogger logger;
  final Telemetry telemetry;
  final CalendarPort? calendarPort;
  final EventVerifier eventVerifier;

  /// Optional callback the SDK invokes to show OS notifications (swap
  /// progress, deposit confirmed, etc.).  When `null`, the SDK silently
  /// skips notification delivery — the operation still completes.
  final ShowNotification? showNotification;

  /// Optional bootstrap hook for choosing the active `cryptography` backend
  /// before the SDK starts constructing services.
  final ConfigureCryptography? configureCryptography;

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
    this.calendarPort,
    this.showNotification,
    this.configureCryptography,
    EventVerifier? eventVerifier,
    KeyValueStorage? storage,
    CommonDatabase? operationsDb,
    NdkConfig? ndk,
    CustomLogger? logs,
    Telemetry? telemetry,
  }) : keyValueStorage = storage ?? InMemoryKeyValueStorage(),
       operationsDb = operationsDb ?? openOperationsDb(),
       storage = HostrSDKStorage.fromKeyValue(
         storage ?? InMemoryKeyValueStorage(),
       ),
       eventVerifier = eventVerifier ?? _defaultEventVerifier(),
       ndkConfig =
           ndk ??
           NdkConfig(
             eventVerifier: eventVerifier ?? _defaultEventVerifier(),
             cache: MemCacheManager(),
             fetchedRangesEnabled: true,
             engine: NdkEngine.JIT,
             defaultQueryTimeout: Duration(seconds: 10),
             // We have to bootstrap our relay, which means NDK will immediately make connection attempt
             // If we do not provide bootstrap relays, queries without author param will not be sent to any relays
             bootstrapRelays: [hostrRelay],
             logLevel: LogLevel.warning,
           ),
       logger = logs ?? CustomLogger(),
       telemetry =
           telemetry ??
           Telemetry(
             enableExport: true,
             otlpEndpoint: 'https://telemetry.hostr.development/v1/traces',
           ) {
    // Wire OTel into the global logger so every log call emits span events.
    CustomLogger.configure(telemetry: this.telemetry);
  }
}

abstract class EvmConfig {
  int get chainId;
  String get rpcUrl;
}

abstract class RootstockConfig extends EvmConfig {
  BoltzConfig get boltz;
  RifRelayConfig get rifRelay;
  RootstockSupportedContractsConfig get supportedContracts;
}

abstract class BoltzConfig {
  String get apiUrl;
  String get wsUrl => '${apiUrl.replaceFirst('http', 'ws')}/ws';
}

abstract class RifRelayConfig {
  String get url;
  String get callVerifier;
  String get deployVerifier;
  String get smartWalletFactoryAddress;
}

abstract class SupportedEscrowContractConfig {
  RifRelayConfig get rifRelay;
}

class DefaultSupportedEscrowContractConfig
    implements SupportedEscrowContractConfig {
  @override
  final RifRelayConfig rifRelay;

  DefaultSupportedEscrowContractConfig({required this.rifRelay});
}

abstract class RootstockSupportedContractsConfig {
  SupportedEscrowContractConfig get multiEscrow;

  SupportedEscrowContractConfig forContractName(String contractName);
}

class DefaultRootstockSupportedContractsConfig
    implements RootstockSupportedContractsConfig {
  @override
  final SupportedEscrowContractConfig multiEscrow;

  DefaultRootstockSupportedContractsConfig({required this.multiEscrow});

  @override
  SupportedEscrowContractConfig forContractName(String contractName) {
    switch (contractName) {
      case 'MultiEscrow':
        return multiEscrow;
    }

    throw StateError(
      'Unsupported Rootstock escrow contract config: $contractName',
    );
  }
}
