import 'package:models/secp256k1.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

import 'datasources/app_database.dart';
import 'datasources/app_database_platform.dart';
import 'datasources/storage.dart';
import 'usecase/calendar/calendar.dart';
import 'usecase/evm/config/evm_config.dart';
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
/// for Schnorr signing **and NIP-44 encryption/decryption** instead of the
/// pure-Dart `bip340` + `elliptic` packages.
///
/// NIP-44 conversation-key derivation uses [coinlibEncryptNip44] /
/// [coinlibDecryptNip44] which call `secp256k1_ec_pubkey_tweak_mul` via WASM
/// on web — significantly faster than `elliptic` for giftwrap operations.
///
/// NIP-04 legacy encrypt/decrypt are still delegated to [Bip340EventSigner]
/// as NIP-04 is deprecated and not on the hot path.
class CoinlibEventSigner implements EventSigner {
  CoinlibEventSigner({required this.privateKey, required this.publicKey})
    : _nip04Delegate = Bip340EventSigner(
        privateKey: privateKey,
        publicKey: publicKey,
      );

  final String? privateKey;
  final String publicKey;
  // Only kept for legacy NIP-04 encrypt/decrypt.
  final Bip340EventSigner _nip04Delegate;

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
      _nip04Delegate.decrypt(msg, destPubKey, id: id);

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) =>
      _nip04Delegate.encrypt(msg, destPubKey, id: id);

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) => _nip04Delegate.encryptNip44(
    plaintext: plaintext,
    recipientPubKey: recipientPubKey,
  );

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) => _nip04Delegate.decryptNip44(
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
    await _nip04Delegate.dispose();
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
  final EvmConfig evmConfig;
  final NdkConfig ndkConfig;
  final HostrSDKStorage storage;
  final KeyValueStorage keyValueStorage;
  final AppDatabase appDatabase;
  final CustomLogger logger;
  final Telemetry telemetry;
  final CalendarPort? calendarPort;
  final EventVerifier eventVerifier;

  /// Optional callback the SDK invokes to show OS notifications (swap
  /// progress, deposit confirmed, etc.).  When `null`, the SDK silently
  /// skips notification delivery — the operation still completes.
  final ShowNotification? showNotification;

  HostrConfig({
    required this.bootstrapRelays,
    required this.bootstrapBlossom,
    this.bootstrapEscrowPubkeys = const [],
    required this.hostrRelay,
    required this.evmConfig,
    this.calendarPort,
    this.showNotification,
    EventVerifier? eventVerifier,
    KeyValueStorage? storage,
    AppDatabase? appDatabase,
    NdkConfig? ndk,
    CustomLogger? logs,
    Telemetry? telemetry,
  }) : keyValueStorage = storage ?? InMemoryKeyValueStorage(),
       appDatabase = appDatabase ?? AppDatabase(openAppDb()),
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
