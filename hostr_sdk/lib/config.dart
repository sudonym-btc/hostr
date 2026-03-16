import 'package:models/secp256k1.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqlite3/common.dart';

import 'datasources/operations_database.dart';
import 'datasources/storage.dart';
import 'usecase/calendar/calendar.dart';
import 'util/custom_logger.dart';
import 'util/telemetry.dart';

EventVerifier _defaultEventVerifier() {
  return CoinlibVerifier();
}

/// Fast secp256k1-backed BIP-340 verifier.
///
/// This uses the shared `models` secp256k1 engine, which can use a fast
/// backend when available and otherwise falls back to the pure-Dart verifier.
class CoinlibVerifier implements EventVerifier {
  CoinlibVerifier();

  @override
  Future<bool> verify(Nip01Event event) async {
    if (event.sig == null) {
      return false;
    }

    if (!Nip01Utils.isIdValid(event)) {
      return false;
    }

    return verifySchnorrSignature(
      publicKey: event.pubKey,
      message: event.id,
      signature: event.sig!,
    );
  }
}

/// Fast secp256k1-backed BIP-340 event signer.
///
/// Uses the shared `models` secp256k1 engine (native/WASM via coinlib)
/// for Schnorr signing instead of the pure-Dart `bip340` package.
///
/// NIP-04 and NIP-44 encrypt/decrypt are delegated to the default NDK
/// [Bip340EventSigner] because they are not on the hot path.
class CoinlibEventSigner implements EventSigner {
  CoinlibEventSigner({required this.privateKey, required this.publicKey})
    : _delegate = Bip340EventSigner(
        privateKey: privateKey,
        publicKey: publicKey,
      );

  final String? privateKey;
  final String publicKey;
  final Bip340EventSigner _delegate;

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    if (privateKey == null || privateKey!.isEmpty) {
      throw Exception('Private key is required for signing');
    }
    final sig = signSchnorr(privateKey: privateKey!, message: event.id);
    return event.copyWith(sig: sig);
  }

  @override
  String getPublicKey() => publicKey;

  @override
  bool canSign() => privateKey != null && privateKey!.isNotEmpty;

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) =>
      _delegate.decrypt(msg, destPubKey, id: id);

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) =>
      _delegate.encrypt(msg, destPubKey, id: id);

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) => _delegate.encryptNip44(
    plaintext: plaintext,
    recipientPubKey: recipientPubKey,
  );

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) => _delegate.decryptNip44(
    ciphertext: ciphertext,
    senderPubKey: senderPubKey,
  );

  final _pendingRequestsController =
      BehaviorSubject<List<PendingSignerRequest>>.seeded([]);

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      _pendingRequestsController.stream;

  @override
  List<PendingSignerRequest> get pendingRequests => [];

  @override
  bool cancelRequest(String requestId) => false;

  @override
  Future<void> dispose() async {
    await _delegate.dispose();
    await _pendingRequestsController.close();
  }
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
