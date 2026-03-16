import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:models/bip341.dart' show loadBip341Backend;
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' as bip;

import '../../config.dart' show CoinlibEventSigner;
import '../../injection.dart';
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
  Ndk get ndk => _ndk;
  AuthStorage get authStorage => _authStorage;
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

  KeyPair? get activeKeyPair => _authRecord?.keyPair;

  bool get isMnemonicBacked => _authRecord?.credentialType == 'mnemonic';

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
    final record = await _identityResolver.prepareIdentity(input);
    await authStorage.set([jsonEncode(record.toJson())]);
    _setAuthenticated(record);
    ensureNdkAccountsMatch();
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
    await authStorage.wipe();
    await _loadActiveKeyPair();
    ensureNdkAccountsMatch();
    _syncAuthState();
  });

  Future<void> init() => _logger.span('init', () async {
    await loadBip341Backend();
    await _loadActiveKeyPair();
    ensureNdkAccountsMatch();
    _syncAuthState();
  });

  /// Returns whether there is an active key pair.
  Future<bool> isAuthenticated() => _logger.span('isAuthenticated', () async {
    await _loadActiveKeyPair();
    return activeKeyPair != null;
  });

  /// Restores NDK login using the stored key, if any.
  bool ensureNdkAccountsMatch() => _logger.spanSync(
    'ensureNdkAccountsMatch',
    () {
      if (activeKeyPair == null) {
        final pubkeys = ndk.accounts.accounts.keys.toList(growable: false);
        for (final pubkey in pubkeys) {
          ndk.accounts.removeAccount(pubkey: pubkey);
        }
      } else {
        final pubkey = activeKeyPair!.publicKey;
        final privkey = activeKeyPair!.privateKey!;
        final alreadyLoggedIn =
            ndk.accounts.accounts.containsKey(pubkey) ||
            ndk.accounts.getPublicKey() == pubkey;

        if (!alreadyLoggedIn) {
          _logger.i('Restoring NDK account for stored key');
          ndk.accounts.loginExternalSigner(
            signer: CoinlibEventSigner(privateKey: privkey, publicKey: pubkey),
          );
        }
      }

      return true;
    },
  );

  Future<void> _loadActiveKeyPair() =>
      _logger.span('_loadActiveKeyPair', () async {
        final stored = await authStorage.get();
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
    _emitAuthState(activeKeyPair != null ? const LoggedIn() : LoggedOut());
  }

  Future<void> updateMaxAccountIndex(int maxAccountIndex) async {
    final record = _authRecord;
    if (record == null || maxAccountIndex <= record.maxAccountIndex) {
      return;
    }

    final updated = record.copyWith(maxAccountIndex: maxAccountIndex);
    await authStorage.set([jsonEncode(updated.toJson())]);
    _authRecord = updated;
  }

  void _setAuthenticated(AuthRecord record) {
    if (record.keyPair == null) {
      throw StateError('Authenticated auth record must include a keyPair');
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
}

/// Abstract class representing the state of authentication.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
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
  const LoggedIn();
}
