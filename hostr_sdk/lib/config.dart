import 'package:marketplace_evm/funds_monitor_ports.dart';

import 'package:marketplace_evm/ports.dart';

import 'package:marketplace_models/secp256k1.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

import 'datasources/app_database.dart';
import 'datasources/app_database_platform.dart';
import 'datasources/storage.dart';
import 'usecase/calendar/calendar.dart';
import 'package:marketplace_evm/usecase/evm/config/evm_config.dart';
import 'util/coinlib_gift_wrap.dart';
import 'package:marketplace_evm/util/custom_logger.dart';
import 'package:marketplace_evm/util/telemetry.dart';

EventVerifier _defaultEventVerifier() {
  return CoinlibVerifier();
}

LocalEventSignerFactory _defaultEventSignerFactory() {
  return const CoinlibEventSignerFactory();
}

/// Fast secp256k1-backed BIP-340 verifier.
///
/// This uses the shared `marketplace_models` secp256k1 engine, which can use a fast
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
/// Uses the shared `marketplace_models` secp256k1 engine (native/WASM via coinlib)
/// for Schnorr signing and the configured crypto provider for the NIP-44
/// fast paths instead of the pure-Dart `bip340` + `elliptic` packages.
///
/// On web, the Flutter crypto provider delegates NIP-44 conversation-key
/// derivation and ChaCha20 payload encryption/decryption to noble JS through
/// `web/nostr_crypto.js`, which is significantly faster than the Dart debug
/// crypto stack for giftwrap operations.
///
/// Direct message encryption uses NIP-44.
class CoinlibEventSigner extends EventSigner {
  CoinlibEventSigner({required this.privateKey, required this.publicKey});

  final String? privateKey;
  final String publicKey;

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
      Future.error(UnsupportedError('Use decryptNip44 for direct messages'));

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) =>
      Future.error(UnsupportedError('Use encryptNip44 for direct messages'));

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    if (privateKey == null || privateKey!.isEmpty) return null;
    return coinlibEncryptNip44(plaintext, privateKey!, recipientPubKey);
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    if (privateKey == null || privateKey!.isEmpty) return null;
    return coinlibDecryptNip44(ciphertext, privateKey!, senderPubKey);
  }

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
    await _pendingRequestsController.close();
  }
}

class CoinlibEventSignerFactory implements LocalEventSignerFactory {
  const CoinlibEventSignerFactory();

  static const _keyFactory = Bip340EventSignerFactory();

  @override
  EventSigner create({String? privateKey, String? publicKey}) {
    final resolvedPublicKey =
        publicKey ?? (privateKey == null ? null : derivePublicKey(privateKey));
    if (resolvedPublicKey == null) {
      throw ArgumentError('Either publicKey or privateKey must be provided');
    }
    return CoinlibEventSigner(
      privateKey: privateKey,
      publicKey: resolvedPublicKey,
    );
  }

  @override
  String derivePublicKey(String privateKey) {
    return _keyFactory.derivePublicKey(privateKey);
  }

  @override
  (String, String) generateKeyPair() {
    return _keyFactory.generateKeyPair();
  }

  @override
  EventSigner createWithNewKeyPair() {
    final (privateKey, publicKey) = generateKeyPair();
    return create(privateKey: privateKey, publicKey: publicKey);
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

class HostrConfig implements EvmDriverConfig, EvmFundsConfig {
  static const _developmentRelay = 'wss://relay.hostr.development';

  final List<String> bootstrapRelays;
  final List<String> bootstrapBlossom;
  @override
  final List<String> bootstrapEscrowPubkeys;
  final String hostrRelay;
  @override
  final EvmConfig evmConfig;
  final NdkConfig ndkConfig;
  final HostrSDKStorage storage;
  final KeyValueStorage keyValueStorage;
  final AppDatabase appDatabase;
  final CustomLogger logger;
  final Telemetry telemetry;
  final CalendarPort? calendarPort;
  final EventVerifier eventVerifier;
  final LocalEventSignerFactory eventSignerFactory;
  final bool syncAccountSeedRemotely;

  static List<String> _ndkBootstrapRelays({
    required String hostrRelay,
    required List<String> bootstrapRelays,
  }) {
    final relays = hostrRelay.isNotEmpty ? [hostrRelay] : bootstrapRelays;
    return [
      ...{
        for (final relay in relays)
          if (relay.isNotEmpty) relay,
      },
    ];
  }

  static List<String> _ndkIgnoreRelays(String hostrRelay) {
    if (hostrRelay == _developmentRelay) return const [];
    // Temporary guard: prod NIP-65 data was polluted with the development
    // relay. The better fix is to remove that relay from the NIP-65 event.
    return const [_developmentRelay];
  }

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
    this.syncAccountSeedRemotely = true,
    EventVerifier? eventVerifier,
    LocalEventSignerFactory? eventSignerFactory,
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
       eventSignerFactory = eventSignerFactory ?? _defaultEventSignerFactory(),
       ndkConfig =
           ndk ??
           NdkConfig(
             eventVerifier: eventVerifier ?? _defaultEventVerifier(),
             eventSignerFactory:
                 eventSignerFactory ?? _defaultEventSignerFactory(),
             cache: MemCacheManager(),
             fetchedRangesEnabled: true,
             engine: NdkEngine.JIT,
             defaultQueryTimeout: Duration(seconds: 10),
             // NDK eagerly opens sockets for every bootstrap relay and owns
             // their reconnect loops. Keep that eager pool to the canonical
             // Hostr relay; other configured relays remain available for
             // explicit discovery, payments, and user relay management.
             bootstrapRelays: _ndkBootstrapRelays(
               hostrRelay: hostrRelay,
               bootstrapRelays: bootstrapRelays,
             ),
             ignoreRelays: _ndkIgnoreRelays(hostrRelay),
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

  HostrConfig copyWith({
    KeyValueStorage? storage,
    AppDatabase? appDatabase,
    NdkConfig? ndk,
    CustomLogger? logs,
    Telemetry? telemetry,
    CalendarPort? calendarPort,
    ShowNotification? showNotification,
    bool? syncAccountSeedRemotely,
  }) {
    return HostrConfig(
      bootstrapRelays: bootstrapRelays,
      bootstrapBlossom: bootstrapBlossom,
      bootstrapEscrowPubkeys: bootstrapEscrowPubkeys,
      hostrRelay: hostrRelay,
      evmConfig: evmConfig,
      eventVerifier: eventVerifier,
      eventSignerFactory: eventSignerFactory,
      storage: storage ?? keyValueStorage,
      appDatabase: appDatabase ?? this.appDatabase,
      ndk: ndk ?? ndkConfig,
      logs: logs ?? logger,
      telemetry: telemetry ?? this.telemetry,
      calendarPort: calendarPort ?? this.calendarPort,
      showNotification: showNotification ?? this.showNotification,
      syncAccountSeedRemotely:
          syncAccountSeedRemotely ?? this.syncAccountSeedRemotely,
    );
  }
}
