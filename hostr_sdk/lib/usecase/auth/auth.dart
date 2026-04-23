import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:models/secp256k1.dart' show loadSecp256k1Backend;
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' as bip;

import '../../config.dart' show CoinlibEventSigner;
import '../../injection.dart';
import '../../util/coinlib_gift_wrap.dart' show clearNip44ConvKeyCache;
import '../../util/main.dart';
import '../deterministic_keys/deterministic_keys.dart';
import '../storage/storage.dart';
import 'auth_identity_resolver.dart';
import 'auth_models.dart';

export 'auth_models.dart';

@Singleton()
class Auth {
  final Ndk _ndk;
  final CustomLogger _logger;
  final AuthStorage _authStorage;
  final AuthIdentityResolver _identityResolver;
  final BehaviorSubject<AuthState> _authStateContoller =
      BehaviorSubject<AuthState>.seeded(AuthInitial());
  ValueStream<AuthState> get authState => _authStateContoller;
  AuthRecord? _authRecord;

  Auth({
    required Ndk ndk,
    required AuthStorage authStorage,
    required CustomLogger logger,
    required AuthIdentityResolver identityResolver,
  }) : _ndk = ndk,
       _authStorage = authStorage,
       _logger = logger,
       _identityResolver = identityResolver;

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

  String? get activeMnemonic => isMnemonicBacked ? _authRecord?.secret : null;

  int? get activeNostrAccountIndex => _authRecord?.nostrAccountIndex;

  int get storedMaxAccountIndex => _authRecord?.maxAccountIndex ?? -1;

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
  });

  Future<void> signinWithBunkerUrl(
    String bunkerUrl, {
    void Function(String challenge)? authCallback,
  }) => _logger.span('signinWithBunkerUrl', () async {
    _logger.i('AuthService.signinWithBunkerUrl');
    final bunkerConnection = await _ndk.accounts.loginWithBunkerUrl(
      bunkerUrl: bunkerUrl.trim(),
      bunkers: _ndk.bunkers,
      authCallback: authCallback,
    );
    if (bunkerConnection == null) {
      throw StateError('Bunker login was not completed');
    }

    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null || pubkey.isEmpty) {
      throw StateError('Bunker login did not yield a public key');
    }

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
  });

  Future<void> signinWithNostrConnect(
    NostrConnect nostrConnect, {
    void Function(String challenge)? authCallback,
  }) => _logger.span('signinWithNostrConnect', () async {
    _logger.i('AuthService.signinWithNostrConnect');
    final bunkerConnection = await _ndk.accounts.loginWithNostrConnect(
      nostrConnect: nostrConnect,
      bunkers: _ndk.bunkers,
      authCallback: authCallback,
    );
    if (bunkerConnection == null) {
      throw StateError('Nostr Connect login was not completed');
    }

    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null || pubkey.isEmpty) {
      throw StateError('Nostr Connect login did not yield a public key');
    }

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
  });

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

  Future<bool> _ensureNdkAccountsMatchAsync() =>
      _logger.span('ensureNdkAccountsMatch', () async {
        final activePubkey = this.activePubkey;
        if (activePubkey == null) {
          final pubkeys = _ndk.accounts.accounts.keys.toList(growable: false);
          for (final pubkey in pubkeys) {
            _ndk.accounts.removeAccount(pubkey: pubkey);
          }
        } else {
          final loggedPubkey = _ndk.accounts.getPublicKey();
          if (loggedPubkey == activePubkey) {
            return true;
          }

          if (_ndk.accounts.accounts.containsKey(activePubkey)) {
            _logger.i('Switching NDK account to stored pubkey');
            _ndk.accounts.switchAccount(pubkey: activePubkey);
          } else if (hasLocalPrivateKey) {
            final privkey = _authRecord!.keyPair!.privateKey!;
            _logger.i('Restoring NDK account for stored key');
            _ndk.accounts.loginExternalSigner(
              signer: CoinlibEventSigner(
                privateKey: privkey,
                publicKey: activePubkey,
              ),
            );
          } else if (_authRecord?.bunkerConnection != null) {
            _logger.i('Restoring NDK bunker session');
            await _ndk.accounts.loginWithBunkerConnection(
              connection: _authRecord!.bunkerConnection!,
              bunkers: _ndk.bunkers,
            );
          }
        }

        return true;
      });

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

  // ---------------------------------------------------------------------------
  // HD wallet – EVM key derivation
  // ---------------------------------------------------------------------------

  DeterministicKeys get hd => getIt<DeterministicKeys>();

  // ---------------------------------------------------------------------------

  void _syncAuthState() {
    final activePubkey = this.activePubkey;
    _emitAuthState(activePubkey != null ? LoggedIn(activePubkey) : LoggedOut());
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

  void _emitAuthState(AuthState state) {
    if (_authStateContoller.value != state) {
      _authStateContoller.add(state);
    }
  }

  Future<void> dispose() async {
    await _authStateContoller.close();
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
