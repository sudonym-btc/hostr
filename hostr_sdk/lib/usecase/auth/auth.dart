import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:models/bip340.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

import '../../injection.dart';
import '../../util/main.dart';
import '../deterministic_keys/deterministic_keys.dart';
import '../storage/storage.dart';

@Singleton()
class Auth {
  final Ndk _ndk;
  final CustomLogger _logger;
  final AuthStorage _authStorage;
  static const _recordVersion = 1;
  Ndk get ndk => _ndk;
  AuthStorage get authStorage => _authStorage;
  final BehaviorSubject<AuthState> _authStateContoller =
      BehaviorSubject<AuthState>.seeded(AuthInitial());
  ValueStream<AuthState> get authState => _authStateContoller;
  KeyPair? activeKeyPair;
  ResolvedNostrIdentity? _activeIdentity;
  _AuthRecord? _authRecord;

  Auth({
    required Ndk ndk,
    required AuthStorage authStorage,
    required CustomLogger logger,
  }) : _ndk = ndk,
       _authStorage = authStorage,
       _logger = logger;

  ResolvedNostrIdentity? get activeIdentity => _activeIdentity;

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
    final record = _buildAuthRecord(input);
    await authStorage.set([jsonEncode(record.toJson())]);
    await _loadActiveKeyPair();
    ensureNdkAccountsMatch();
    _syncAuthState();
  });

  ResolvedNostrIdentity previewResolvedIdentity(
    String input, {
    int nostrAccountIndex = 0,
  }) => _logger.spanSync('previewResolvedIdentity', () {
    return _resolveIdentity(input, nostrAccountIndex: nostrAccountIndex);
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
  bool ensureNdkAccountsMatch() =>
      _logger.spanSync('ensureNdkAccountsMatch', () {
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
            ndk.accounts.loginPrivateKey(privkey: privkey, pubkey: pubkey);
          }
        }

        return true;
      });

  Future<void> _loadActiveKeyPair() =>
      _logger.span('_loadActiveKeyPair', () async {
        final stored = await authStorage.get();
        final record = _AuthRecord.fromStorage(stored);
        _authRecord = record;
        if (record == null) {
          activeKeyPair = null;
          _activeIdentity = null;
          return;
        }

        final resolved = _resolveIdentityFromRecord(record);
        _activeIdentity = resolved;
        activeKeyPair = Bip340.fromPrivateKey(resolved.privateKeyHex);
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

  DeterministicKeys get _deterministicKeys => getIt<DeterministicKeys>();

  /// Returns the BIP-44 derived EVM private key at [accountIndex].
  EthPrivateKey getActiveEvmKey({int accountIndex = 0}) {
    return _deterministicKeys.getActiveEvmKey(accountIndex: accountIndex);
  }

  /// Returns the EVM address at [accountIndex] without exposing the key.
  bip.EthereumAddress getEvmAddress({int accountIndex = 0}) {
    return _deterministicKeys.getEvmAddress(accountIndex: accountIndex);
  }

  /// Scans HD account indices 0..[maxScan] to find the one whose address
  /// matches [address]. Throws [StateError] if no match is found.
  int? tryFindEvmAccountIndex(bip.EthereumAddress address, {int maxScan = 20}) {
    return _deterministicKeys.tryFindEvmAccountIndex(address, maxScan: maxScan);
  }

  int findEvmAccountIndex(bip.EthereumAddress address, {int maxScan = 20}) =>
      _deterministicKeys.findEvmAccountIndex(address, maxScan: maxScan);

  /// Returns the 24-word synthetic mnemonic derived from the active Nostr
  /// private key. Paste this into MetaMask to see all derived EVM addresses.
  List<String> getEvmMnemonic() => _logger.spanSync('getEvmMnemonic', () {
    return _deterministicKeys.getEvmMnemonic();
  });

  String getTradeId({required int accountIndex}) =>
      _logger.spanSync('getTradeId', () {
        return _deterministicKeys.getTradeId(accountIndex: accountIndex);
      });

  String getTradeSalt({required int accountIndex}) =>
      _logger.spanSync('getTradeSalt', () {
        return _deterministicKeys.getTradeSalt(accountIndex: accountIndex);
      });

  Future<int> reserveNextTradeIndex() =>
      _deterministicKeys.reserveNextTradeIndex();

  int findTradeAccountIndexByTradeId(String tradeId, {int maxScan = 128}) =>
      _deterministicKeys.findTradeAccountIndexByTradeId(
        tradeId,
        maxScan: maxScan,
      );

  int? tryFindTradeAccountIndexByTradeId(String tradeId, {int maxScan = 128}) =>
      _deterministicKeys.tryFindTradeAccountIndexByTradeId(
        tradeId,
        maxScan: maxScan,
      );

  int findTradeAccountIndexBySalt(String salt, {int maxScan = 128}) =>
      _deterministicKeys.findTradeAccountIndexBySalt(salt, maxScan: maxScan);

  int? tryFindTradeAccountIndexBySalt(String salt, {int maxScan = 128}) =>
      _deterministicKeys.tryFindTradeAccountIndexBySalt(salt, maxScan: maxScan);

  List<int> getReservedTradeIndices() =>
      _deterministicKeys.getReservedTradeIndices();

  // ---------------------------------------------------------------------------

  void _syncAuthState() {
    _emitAuthState(activeKeyPair != null ? const LoggedIn() : LoggedOut());
  }

  void _emitAuthState(AuthState state) {
    if (_authStateContoller.value != state) {
      _authStateContoller.add(state);
    }
  }

  Future<void> dispose() async {
    await _authStateContoller.close();
  }

  _AuthRecord _buildAuthRecord(String input, {int nostrAccountIndex = 0}) {
    final trimmed = input.trim();
    final wordCount = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (wordCount == 12 || wordCount == 24) {
      final normalized = Mnemonic.fromSentence(
        trimmed,
        Language.english,
      ).sentence;
      return _AuthRecord(
        version: _recordVersion,
        credentialType: 'mnemonic',
        secret: normalized,
        nostrAccountIndex: nostrAccountIndex,
        maxAccountIndex: -1,
      );
    }

    final privateKey = _parseAndValidateKey(trimmed);
    return _AuthRecord(
      version: _recordVersion,
      credentialType: 'private_key',
      secret: privateKey,
      maxAccountIndex: -1,
    );
  }

  ResolvedNostrIdentity _resolveIdentity(
    String input, {
    int nostrAccountIndex = 0,
  }) => _logger.spanSync('_resolveIdentity', () {
    final trimmed = input.trim();
    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length == 12 || words.length == 24) {
      final normalized = Mnemonic.fromSentence(
        trimmed,
        Language.english,
      ).sentence;
      final privateKeyHex = deriveNostrPrivateKeyFromMnemonic(
        normalized,
        accountIndex: nostrAccountIndex,
      );
      final keyPair = Bip340.fromPrivateKey(privateKeyHex);
      return ResolvedNostrIdentity(
        privateKeyHex: privateKeyHex,
        publicKeyHex: keyPair.publicKey,
        sourceType: 'mnemonic',
        nostrAccountIndex: nostrAccountIndex,
      );
    }

    final privateKeyHex = _parseAndValidateKey(trimmed);
    final keyPair = Bip340.fromPrivateKey(privateKeyHex);
    return ResolvedNostrIdentity(
      privateKeyHex: privateKeyHex,
      publicKeyHex: keyPair.publicKey,
      sourceType: 'private_key',
    );
  });

  ResolvedNostrIdentity _resolveIdentityFromRecord(_AuthRecord record) {
    if (record.credentialType == 'mnemonic') {
      final privateKeyHex = deriveNostrPrivateKeyFromMnemonic(
        record.secret,
        accountIndex: record.nostrAccountIndex ?? 0,
      );
      final keyPair = Bip340.fromPrivateKey(privateKeyHex);
      return ResolvedNostrIdentity(
        privateKeyHex: privateKeyHex,
        publicKeyHex: keyPair.publicKey,
        sourceType: record.credentialType,
        nostrAccountIndex: record.nostrAccountIndex,
      );
    }

    final privateKeyHex = _parseAndValidateKey(record.secret);
    final keyPair = Bip340.fromPrivateKey(privateKeyHex);
    return ResolvedNostrIdentity(
      privateKeyHex: privateKeyHex,
      publicKeyHex: keyPair.publicKey,
      sourceType: record.credentialType,
      nostrAccountIndex: record.nostrAccountIndex,
    );
  }

  /// Validates and returns a 64-char hex private key.
  ///
  /// Accepts:
  /// - 64-char hex private key
  /// - nsec1… bech32-encoded private key
  String _parseAndValidateKey(
    String input,
  ) => _logger.spanSync('_parseAndValidateKey', () {
    final trimmed = input.trim();

    if (trimmed.length == 64 && _isHex(trimmed)) {
      return trimmed.toLowerCase();
    }

    if (trimmed.startsWith('nsec1')) {
      final decoded = Helpers.decodeBech32(trimmed);
      final hex = decoded[0];
      if (hex.isNotEmpty && hex.length == 64 && _isHex(hex)) {
        return hex.toLowerCase();
      }
      throw Exception('Invalid nsec key');
    }

    throw Exception(
      'Invalid key format. Expected mnemonic, nsec or 64-char hex private key',
    );
  });

  bool _isHex(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
  }
}

class ResolvedNostrIdentity extends Equatable {
  final String privateKeyHex;
  final String publicKeyHex;
  final String sourceType;
  final int? nostrAccountIndex;

  const ResolvedNostrIdentity({
    required this.privateKeyHex,
    required this.publicKeyHex,
    required this.sourceType,
    this.nostrAccountIndex,
  });

  @override
  List<Object?> get props => [
    privateKeyHex,
    publicKeyHex,
    sourceType,
    nostrAccountIndex,
  ];
}

class _AuthRecord {
  final int version;
  final String credentialType;
  final String secret;
  final int? nostrAccountIndex;
  final int maxAccountIndex;

  const _AuthRecord({
    required this.version,
    required this.credentialType,
    required this.secret,
    this.nostrAccountIndex,
    this.maxAccountIndex = -1,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'credentialType': credentialType,
    'secret': secret,
    if (nostrAccountIndex != null) 'nostrAccountIndex': nostrAccountIndex,
    'maxAccountIndex': maxAccountIndex,
  };

  static _AuthRecord? fromStorage(List<String> raw) {
    if (raw.isEmpty) return null;
    final first = raw.first;
    try {
      final decoded = jsonDecode(first);
      if (decoded is Map<String, dynamic>) {
        final reserved =
            (decoded['reservedTradeIndices'] as List<dynamic>? ?? const [])
                .map((e) => e as int)
                .toList(growable: false);
        final maxAccountIndex =
            decoded['maxAccountIndex'] as int? ??
            (reserved.isEmpty ? -1 : reserved.reduce((a, b) => a > b ? a : b));
        return _AuthRecord(
          version: decoded['version'] as int? ?? 1,
          credentialType: decoded['credentialType'] as String? ?? 'private_key',
          secret: decoded['secret'] as String,
          nostrAccountIndex: decoded['nostrAccountIndex'] as int?,
          maxAccountIndex: maxAccountIndex,
        );
      }
    } catch (_) {
      // fall through to raw-key migration below
    }

    return _AuthRecord(
      version: 1,
      credentialType: 'private_key',
      secret: first,
      maxAccountIndex: -1,
    );
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
