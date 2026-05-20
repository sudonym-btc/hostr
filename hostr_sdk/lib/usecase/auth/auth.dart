import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart' show kNostrKindIdentityClaims;
import 'package:models/secp256k1.dart' show loadSecp256k1Backend;
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' as bip;

import '../../config.dart' show CoinlibEventSigner, HostrConfig;
import '../../injection.dart' show HostrScope, getIt;
import '../../util/coinlib_gift_wrap.dart' show clearNip44ConvKeyCache;
import '../../util/main.dart';
import '../deterministic_keys/deterministic_keys.dart';
import '../storage/storage.dart';
import 'auth_identity_resolver.dart';
import 'auth_models.dart';

export 'auth_models.dart';

String _shortHex(String? value) {
  if (value == null) return 'null';
  if (value.length <= 16) return value;
  return '${value.substring(0, 8)}...${value.substring(value.length - 8)}';
}

String _nostrEventDebugJson(Nip01Event event) {
  return jsonEncode(Nip01EventModel.fromEntity(event).toJson());
}

String _signEventDebugSummary(Nip01Event event) {
  final calculatedId = Nip01Utils.calculateId(event);
  return [
    'kind=${event.kind}',
    'pubkey=${_shortHex(event.pubKey)}',
    'createdAt=${event.createdAt}',
    'tags=${event.tags.length}',
    'contentLength=${event.content.length}',
    'id=${_shortHex(event.id)}',
    'calculated=${_shortHex(calculatedId)}',
    'idValid=${event.id == calculatedId}',
    'sigPresent=${event.sig != null}',
    if (event.sig != null) 'sig=${_shortHex(event.sig)}',
  ].join(' ');
}

@Singleton()
class Auth {
  static const _nip42AuthTimeout = Duration(seconds: 30);
  static const _nip42ChallengeTimeout = Duration(seconds: 5);
  final Ndk _ndk;
  final CustomLogger _logger;
  final AuthStorage _authStorage;
  final AuthIdentityResolver _identityResolver;
  final HostrScope _scope;
  final BehaviorSubject<AuthState> _authStateContoller =
      BehaviorSubject<AuthState>.seeded(AuthInitial());
  final BehaviorSubject<BunkerSessionState> _bunkerSessionController =
      BehaviorSubject<BunkerSessionState>.seeded(const BunkerSessionInactive());
  ValueStream<AuthState> get authState => _authStateContoller;
  ValueStream<BunkerSessionState> get bunkerSessionState =>
      _bunkerSessionController;
  AuthRecord? _authRecord;
  _Nip42AuthInFlight? _nip42AuthInFlight;

  Auth({
    required Ndk ndk,
    required AuthStorage authStorage,
    required CustomLogger logger,
    required AuthIdentityResolver identityResolver,
    HostrScope? scope,
  }) : _ndk = ndk,
       _authStorage = authStorage,
       _logger = logger,
       _identityResolver = identityResolver,
       _scope = scope ?? HostrScope(getIt);

  KeyPair? get activeKeyPair {
    final record = _authRecord;
    if (record == null) return null;
    return record.keyPair ?? _publicOnlyKeyPair(record.publicKeyHex);
  }

  String? get activePubkey =>
      _authRecord?.publicKeyHex ?? activeKeyPair?.publicKey;

  bool get isMnemonicBacked => _authRecord?.credentialType == 'mnemonic';
  bool get isBunkerBacked => _authRecord?.credentialType == 'bunker';
  bool get hasLocalPrivateKey => _authRecord?.keyPair?.privateKey != null;
  BunkerConnection? get activeBunkerConnection => _authRecord?.bunkerConnection;
  bool get needsBunkerRecovery =>
      _bunkerSessionController.value is BunkerSessionRecoveryRequired;
  T service<T extends Object>() => _scope<T>();

  String? get activeMnemonic => isMnemonicBacked ? _authRecord?.secret : null;

  int? get activeNostrAccountIndex => _authRecord?.nostrAccountIndex;

  int get storedMaxAccountIndex => _authRecord?.maxAccountIndex ?? -1;

  Future<void> ensureNip42AuthForHostrRelay({
    Duration timeout = _nip42AuthTimeout,
  }) {
    return _ensureNip42AuthAfterAccountReady(timeout: timeout, failOpen: false);
  }

  /// Generates a new mnemonic and stores it, clearing any previous keys.
  Future<void> signup() => _logger.span('signup', () async {
    _logger.i('AuthService.signup');
    await logout();
    final entropy = Helpers.getSecureRandomHex(32);
    final words = bip.entropyToMnemonic(
      Uint8List.fromList(hex.decode(entropy)),
    );
    await signin(words.join(' '));
  });

  /// Imports a private key (hex or nsec) or a mnemonic and stores it.
  Future<void> signin(String input) => _logger.span('signin', () async {
    _logger.i('AuthService.signin');
    if (_looksLikeBunkerUrl(input)) {
      await signinWithBunkerUrl(input);
      return;
    }
    final record = await _identityResolver.prepareIdentity(input);
    await _authStorage.set([jsonEncode(record.toJson())]);
    _setAuthenticated(record);
    await _ensureNdkAccountsMatchAsync();
    _syncAuthState();
    await _ensureNip42AuthAfterAccountReady();
  });

  Future<void> signinWithBunkerUrl(
    String bunkerUrl, {
    void Function(String challenge)? authCallback,
  }) => _logger.span('signinWithBunkerUrl', () async {
    _logger.i('AuthService.signinWithBunkerUrl');
    final bunkerConnection = await _ndk.bunkers.connectWithBunkerUrl(
      bunkerUrl.trim(),
      authCallback: authCallback,
    );
    if (bunkerConnection == null) {
      throw StateError('Bunker login was not completed');
    }

    final pubkey = await _upsertBunkerConnection(
      bunkerConnection,
      authCallback: authCallback,
      context: 'Bunker login',
    );
    await _storeBunkerAuthRecord(pubkey, bunkerConnection);
  });

  Future<void> signinWithNostrConnect(
    NostrConnect nostrConnect, {
    void Function(String challenge)? authCallback,
  }) => _logger.span('signinWithNostrConnect', () async {
    _logger.i('AuthService.signinWithNostrConnect');
    final bunkerConnection = await _ndk.bunkers.connectWithNostrConnect(
      nostrConnect,
      authCallback: authCallback,
    );
    if (bunkerConnection == null) {
      throw StateError('Nostr Connect login was not completed');
    }

    final pubkey = await _upsertBunkerConnection(
      bunkerConnection,
      authCallback: authCallback,
      context: 'Nostr Connect login',
    );
    await _storeBunkerAuthRecord(pubkey, bunkerConnection);
  });

  Future<void> signinWithBunkerConnection(
    BunkerConnection bunkerConnection, {
    void Function(String challenge)? authCallback,
  }) => _logger.span('signinWithBunkerConnection', () async {
    _logger.i('AuthService.signinWithBunkerConnection');
    final pubkey = await _upsertBunkerConnection(
      bunkerConnection,
      authCallback: authCallback,
      context: 'Bunker login',
    );
    await _storeBunkerAuthRecord(pubkey, bunkerConnection);
  });

  Future<String> _upsertBunkerConnection(
    BunkerConnection bunkerConnection, {
    void Function(String challenge)? authCallback,
    required String context,
  }) async {
    final signer = _ndk.bunkers.createSigner(
      bunkerConnection,
      authCallback: authCallback,
    );
    final pubkey = await signer.getPublicKeyAsync();
    if (pubkey.isEmpty) {
      await signer.dispose();
      throw StateError('$context did not yield a public key');
    }

    final existing = _ndk.accounts.accounts[pubkey];
    if (existing != null) {
      _logger.i('$context replacing existing bunker account for $pubkey');
      await existing.dispose();
      _ndk.accounts.removeAccount(pubkey: pubkey);
    }
    _ndk.accounts.addAccount(
      pubkey: pubkey,
      type: AccountType.externalSigner,
      signer: signer,
    );
    _ndk.accounts.switchAccount(pubkey: pubkey);
    return pubkey;
  }

  Future<void> _storeBunkerAuthRecord(
    String pubkey,
    BunkerConnection bunkerConnection,
  ) async {
    final record = AuthRecord(
      version: kCurrentAuthRecordVersion,
      credentialType: 'bunker',
      secret: '',
      publicKey: pubkey,
      maxAccountIndex: -1,
      bunkerConnection: bunkerConnection,
    );
    await _authStorage.set([jsonEncode(record.toJson())]);
    _setAuthenticated(record);
    await _ensureNdkAccountsMatchAsync();
    _syncAuthState();
    await _ensureNip42AuthAfterAccountReady();
  }

  Future<AuthRecord> previewResolvedIdentity(
    String input, {
    int nostrAccountIndex = 0,
  }) => _logger.span('previewResolvedIdentity', () async {
    return _identityResolver.resolveInput(
      input,
      nostrAccountIndex: nostrAccountIndex,
    );
  });

  /// Wipes key storage and secure storage.
  Future<void> logout() => _logger.span('logout', () async {
    _logger.i('AuthService.logout');
    clearNip44ConvKeyCache();
    await _authStorage.wipe();
    await _loadActiveKeyPair();
    await _ensureNdkAccountsMatchAsync();
    _syncAuthState();
  });

  Future<void> init() => _logger.span('init', () async {
    await loadSecp256k1Backend();
    await _loadActiveKeyPair();
    await _ensureNdkAccountsMatchAsync();
    _syncAuthState();
  });

  Future<void> _ensureNip42AuthAfterAccountReady({
    Duration timeout = _nip42AuthTimeout,
    bool failOpen = true,
  }) async {
    var account = _ndk.accounts.getLoggedAccount();
    if (account == null || !account.signer.canSign()) {
      final error = StateError(
        'Cannot NIP-42 authenticate Hostr relay without a signable account',
      );
      if (failOpen) return;
      throw error;
    }

    var inFlight = _nip42AuthInFlight;
    if (inFlight != null && inFlight.pubkey == account.pubkey) {
      return _awaitNip42Auth(inFlight.future, failOpen: failOpen);
    }

    // Same-account callers share a signer prompt; account switches must not.
    // A relay connection has one effective NIP-42 identity, so reusing an old
    // account's in-flight AUTH would make the next write fail author matching.
    if (inFlight != null) {
      await _awaitNip42Auth(inFlight.future, failOpen: true);
      account = _ndk.accounts.getLoggedAccount();
      if (account == null || !account.signer.canSign()) {
        final error = StateError(
          'Cannot NIP-42 authenticate Hostr relay without a signable account',
        );
        if (failOpen) return;
        throw error;
      }
      inFlight = _nip42AuthInFlight;
      if (inFlight != null && inFlight.pubkey == account.pubkey) {
        return _awaitNip42Auth(inFlight.future, failOpen: failOpen);
      }
    }

    final future = _runNip42AuthAfterAccountReady(account, timeout);
    final marker = _Nip42AuthInFlight(pubkey: account.pubkey, future: future);
    _nip42AuthInFlight = marker;

    try {
      await future;
    } catch (_) {
      if (!failOpen) rethrow;
    } finally {
      if (identical(_nip42AuthInFlight, marker)) {
        _nip42AuthInFlight = null;
      }
    }
  }

  Future<void> _awaitNip42Auth(
    Future<void> future, {
    required bool failOpen,
  }) async {
    try {
      await future;
    } catch (_) {
      if (!failOpen) rethrow;
    }
  }

  Future<void> _runNip42AuthAfterAccountReady(
    Account account,
    Duration timeout,
  ) async {
    if (!_scope.isRegistered<HostrConfig>()) return;

    final relays = _nip42AuthRelayTargets(_scope<HostrConfig>());
    if (relays.isEmpty) return;

    await Future.wait(
      relays.map(
        (relay) => _ensureNip42AuthOnRelay(
          relay: relay,
          account: account,
          timeout: timeout,
        ),
      ),
    );
  }

  List<String> _nip42AuthRelayTargets(HostrConfig config) {
    final primary = config.hostrRelay.trim();
    final candidates = primary.isNotEmpty
        ? [primary]
        : config.bootstrapRelays.map((relay) => relay.trim());

    return [
      ...{
        for (final relay in candidates)
          if (relay.isNotEmpty) relay,
      },
    ];
  }

  Future<void> _ensureNip42AuthOnRelay({
    required String relay,
    required Account account,
    required Duration timeout,
  }) async {
    await _ndk.relays.ensureAuthenticated(
      relayUrl: relay,
      account: account,
      timeout: timeout,
      challengeTimeout: _nip42ChallengeTimeout,
    );
    _logger.d('NIP-42 relay auth completed for $relay');
  }

  /// Returns whether there is an active key pair.
  Future<bool> isAuthenticated() => _logger.span('isAuthenticated', () async {
    await _loadActiveKeyPair();
    return activePubkey != null;
  });

  /// Best-effort compatibility wrapper for older call sites/tests.
  bool ensureNdkAccountsMatch() {
    unawaited(_ensureNdkAccountsMatchAsync());
    return true;
  }

  Future<bool> retryBunkerSessionRestore() async {
    final restored = await _ensureNdkAccountsMatchAsync(
      forceBunkerRestore: true,
    );
    if (restored) {
      _syncAuthState(force: true);
      unawaited(_ensureNip42AuthAfterAccountReady());
    }
    return restored;
  }

  Future<void> markBunkerSessionRecoveryRequired(Object error) async {
    final activePubkey = this.activePubkey;
    if (activePubkey == null || activePubkey.isEmpty || !isBunkerBacked) {
      return;
    }
    await _disposeAndRemoveNdkAccount(activePubkey);
    _emitBunkerSessionState(
      BunkerSessionRecoveryRequired(
        pubkey: activePubkey,
        message: _bunkerRecoveryMessage(error),
      ),
    );
  }

  Future<bool> _ensureNdkAccountsMatchAsync({
    bool forceBunkerRestore = false,
  }) => _logger.span('ensureNdkAccountsMatch', () async {
    final activePubkey = this.activePubkey;
    if (activePubkey == null) {
      _emitBunkerSessionState(const BunkerSessionInactive());
      await _disposeAllNdkAccounts();
    } else {
      await _disposeNdkAccountsExcept(activePubkey);
      final loggedPubkey = _ndk.accounts.getPublicKey();
      if (!forceBunkerRestore && loggedPubkey == activePubkey) {
        if (isBunkerBacked) {
          _emitBunkerSessionState(BunkerSessionReady(pubkey: activePubkey));
        } else {
          _emitBunkerSessionState(const BunkerSessionInactive());
        }
        return true;
      }

      if (!forceBunkerRestore &&
          _ndk.accounts.accounts.containsKey(activePubkey)) {
        _logger.i('Switching NDK account to stored pubkey');
        _ndk.accounts.switchAccount(pubkey: activePubkey);
      } else if (hasLocalPrivateKey) {
        _emitBunkerSessionState(const BunkerSessionInactive());
        final privkey = _authRecord!.keyPair!.privateKey!;
        _logger.i('Restoring NDK account for stored key');
        _ndk.accounts.loginExternalSigner(
          signer: CoinlibEventSigner(
            privateKey: privkey,
            publicKey: activePubkey,
          ),
        );
      } else if (_authRecord?.bunkerConnection != null) {
        return _restoreBunkerSession(activePubkey);
      }
    }

    return true;
  });

  Future<bool> _restoreBunkerSession(String activePubkey) async {
    _logger.i('Restoring NDK bunker session');
    _emitBunkerSessionState(BunkerSessionRestoring(pubkey: activePubkey));

    await _disposeAndRemoveNdkAccount(activePubkey);

    final signer = _ndk.bunkers.createSigner(_authRecord!.bunkerConnection!);
    try {
      final restoredPubkey = await signer.getPublicKeyAsync().timeout(
        const Duration(seconds: 5),
      );

      if (restoredPubkey != activePubkey) {
        throw StateError(
          'Bunker restored $restoredPubkey instead of $activePubkey',
        );
      }

      if (_ndk.accounts.accounts.containsKey(activePubkey)) {
        await _disposeAndRemoveNdkAccount(activePubkey);
      }
      _ndk.accounts.loginExternalSigner(signer: signer);
      _emitBunkerSessionState(BunkerSessionReady(pubkey: activePubkey));
      return true;
    } catch (e) {
      await signer.dispose();
      _logger.w('Bunker session restore requires user recovery: $e');
      _emitBunkerSessionState(
        BunkerSessionRecoveryRequired(
          pubkey: activePubkey,
          message: _bunkerRecoveryMessage(e),
        ),
      );
      return false;
    }
  }

  Future<void> _disposeAllNdkAccounts() async {
    final pubkeys = _ndk.accounts.accounts.keys.toList(growable: false);
    for (final pubkey in pubkeys) {
      await _disposeAndRemoveNdkAccount(pubkey);
    }
  }

  Future<void> _disposeNdkAccountsExcept(String activePubkey) async {
    final stalePubkeys = _ndk.accounts.accounts.keys
        .where((pubkey) => pubkey != activePubkey)
        .toList(growable: false);
    for (final pubkey in stalePubkeys) {
      await _disposeAndRemoveNdkAccount(pubkey);
    }
  }

  Future<void> _disposeAndRemoveNdkAccount(String pubkey) async {
    final account = _ndk.accounts.accounts[pubkey];
    if (account == null) return;
    _ndk.accounts.removeAccount(pubkey: pubkey);
    try {
      await account.dispose();
    } catch (error) {
      _logger.w('Failed to dispose NDK account $pubkey: $error');
    }
  }

  Future<void> _loadActiveKeyPair() =>
      _logger.span('_loadActiveKeyPair', () async {
        final stored = await _authStorage.get();
        final record = AuthRecord.fromStorage(stored);
        _authRecord = record;
        if (record == null) {
          _clearAuthenticated();
          return;
        }

        final resolvedRecord = await _identityResolver.resolveRecord(record);
        _setAuthenticated(resolvedRecord);
      });

  KeyPair getActiveKey() {
    if (activeKeyPair == null) {
      throw Exception('No active key pair');
    }
    return activeKeyPair!;
  }

  Future<Nip01Event> signEvent(
    Nip01Event event,
  ) => _logger.span('signEvent', () async {
    final activePubkey = this.activePubkey;
    if (activePubkey == null) {
      throw StateError('No active signer');
    }
    if (event.pubKey != activePubkey) {
      throw StateError(
        'Cannot sign event for ${event.pubKey} with active key $activePubkey',
      );
    }

    _logger.d('signEvent input: ${_signEventDebugSummary(event)}');
    _logIdentityClaimEventJson('signEvent input event', event);

    final eventToSign = event.id.isEmpty
        ? event.copyWith(id: Nip01Utils.calculateId(event))
        : event;
    if (!identical(eventToSign, event)) {
      _logger.d(
        'signEvent normalized input id: ${_signEventDebugSummary(eventToSign)}',
      );
      _logIdentityClaimEventJson(
        'signEvent normalized input event',
        eventToSign,
      );
    }

    late final Nip01Event signed;
    if (_ndk.accounts.getPublicKey() == event.pubKey) {
      _logger.d(
        'signEvent using NDK account signer for ${_shortHex(event.pubKey)} '
        'credentialType=${_authRecord?.credentialType ?? 'unknown'} '
        'bunkerBacked=$isBunkerBacked localPrivateKey=$hasLocalPrivateKey',
      );
      signed = await _ndk.accounts.sign(eventToSign);
    } else {
      final keyPair = activeKeyPair;
      final privateKey = keyPair?.privateKey;
      if (privateKey == null || privateKey.isEmpty) {
        throw StateError('No active local or bunker signer');
      }

      _logger.d(
        'signEvent using local Coinlib signer for ${_shortHex(keyPair!.publicKey)}',
      );
      signed = await CoinlibEventSigner(
        privateKey: privateKey,
        publicKey: keyPair.publicKey,
      ).sign(eventToSign);
    }

    _logger.d('signEvent output: ${_signEventDebugSummary(signed)}');
    _logIdentityClaimEventJson('signEvent output event', signed);

    final recalculatedId = Nip01Utils.calculateId(signed);
    if (signed.id != recalculatedId) {
      _logger.w(
        'signEvent output has invalid id: '
        'kind=${signed.kind} id=${_shortHex(signed.id)} '
        'calculated=${_shortHex(recalculatedId)} '
        'sigPresent=${signed.sig != null}',
      );
    }
    return signed;
  });

  void _logIdentityClaimEventJson(String label, Nip01Event event) {
    if (event.kind != kNostrKindIdentityClaims) return;
    _logger.d('$label JSON: ${_nostrEventDebugJson(event)}');
  }

  // ---------------------------------------------------------------------------
  // HD wallet – EVM key derivation
  // ---------------------------------------------------------------------------

  DeterministicKeys get hd => _scope<DeterministicKeys>();

  // ---------------------------------------------------------------------------

  void _syncAuthState({bool force = false}) {
    final activePubkey = this.activePubkey;
    _emitAuthState(
      activePubkey != null ? LoggedIn(activePubkey) : LoggedOut(),
      force: force,
    );
  }

  Future<void> updateMaxAccountIndex(int maxAccountIndex) async {
    final record = _authRecord;
    if (record == null || maxAccountIndex <= record.maxAccountIndex) {
      return;
    }

    final updated = record.copyWith(maxAccountIndex: maxAccountIndex);
    await _authStorage.set([jsonEncode(updated.toJson())]);
    _authRecord = updated;
  }

  void _setAuthenticated(AuthRecord record) {
    if (record.publicKeyHex == null || record.publicKeyHex!.isEmpty) {
      throw StateError('Authenticated auth record must include a public key');
    }
    _authRecord = record;
  }

  void _clearAuthenticated() {
    _authRecord = null;
  }

  void _emitAuthState(AuthState state, {bool force = false}) {
    if (force || _authStateContoller.value != state) {
      _authStateContoller.add(state);
    }
  }

  void _emitBunkerSessionState(BunkerSessionState state) {
    if (_bunkerSessionController.value != state) {
      _bunkerSessionController.add(state);
    }
  }

  String _bunkerRecoveryMessage(Object error) {
    if (error is TimeoutException) {
      return 'The remote signer did not respond. It may be offline, locked, or the session may have been ended.';
    }
    return error.toString();
  }

  Future<void> dispose() async {
    await _disposeAllNdkAccounts();
    await _authStateContoller.close();
    await _bunkerSessionController.close();
  }

  bool _looksLikeBunkerUrl(String input) {
    final trimmed = input.trim();
    return trimmed.startsWith('bunker://');
  }

  KeyPair? _publicOnlyKeyPair(String? pubkey) {
    if (pubkey == null || pubkey.isEmpty) return null;
    return KeyPair.justPublicKey(pubkey);
  }
}

class _Nip42AuthInFlight {
  final String pubkey;
  final Future<void> future;

  const _Nip42AuthInFlight({required this.pubkey, required this.future});
}

sealed class BunkerSessionState extends Equatable {
  const BunkerSessionState();

  @override
  List<Object?> get props => [];
}

class BunkerSessionInactive extends BunkerSessionState {
  const BunkerSessionInactive();
}

class BunkerSessionRestoring extends BunkerSessionState {
  final String pubkey;

  const BunkerSessionRestoring({required this.pubkey});

  @override
  List<Object?> get props => [pubkey];
}

class BunkerSessionReady extends BunkerSessionState {
  final String pubkey;

  const BunkerSessionReady({required this.pubkey});

  @override
  List<Object?> get props => [pubkey];
}

class BunkerSessionRecoveryRequired extends BunkerSessionState {
  final String pubkey;
  final String message;

  const BunkerSessionRecoveryRequired({
    required this.pubkey,
    required this.message,
  });

  @override
  List<Object?> get props => [pubkey, message];
}

/// Abstract class representing the state of authentication.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state of authentication.
class AuthInitial extends AuthState {}

/// State representing a logged-out user.
class LoggedOut extends AuthState {}

/// State representing a progress in authentication.
// class Progress extends AuthState {
//   Stream<DelegationProgress> progress;
//   Progress(this.progress);
// }

/// State representing a logged-in user.
class LoggedIn extends AuthState {
  final String? pubkey;

  const LoggedIn([this.pubkey]);

  @override
  List<Object?> get props => [pubkey];
}
