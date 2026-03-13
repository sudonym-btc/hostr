import 'dart:async';
import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:models/bip340.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

import '../../util/main.dart';
import '../storage/storage.dart';

@Singleton()
class Auth {
  final Ndk _ndk;
  final CustomLogger _logger;
  final AuthStorage _authStorage;
  Ndk get ndk => _ndk;
  AuthStorage get authStorage => _authStorage;
  final BehaviorSubject<AuthState> _authStateContoller =
      BehaviorSubject<AuthState>.seeded(AuthInitial());
  ValueStream<AuthState> get authState => _authStateContoller;
  KeyPair? activeKeyPair;

  Auth({
    required Ndk ndk,
    required AuthStorage authStorage,
    required CustomLogger logger,
  }) : _ndk = ndk,
       _authStorage = authStorage,
       _logger = logger;

  /// Generates a new key pair and stores it, clearing any previous keys.
  Future<void> signup() => _logger.span('signup', () async {
    _logger.i('AuthService.signup');
    await logout();
    await signin(Bip340.generatePrivateKey().privateKey!);
  });

  /// Imports a private key (hex or nsec) and stores it.
  Future<void> signin(String input) => _logger.span('signin', () async {
    _logger.i('AuthService.signin');
    final privateKey = _parseAndValidateKey(input);
    await authStorage.set([privateKey]);
    await _loadActiveKeyPair();
    ensureNdkAccountsMatch();
    _syncAuthState();
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
        final privateKey = await authStorage.get();
        activeKeyPair = privateKey.isEmpty
            ? null
            : Bip340.fromPrivateKey(privateKey[0]);
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

  /// Returns the BIP-44 derived EVM private key at [accountIndex].
  ///
  /// Derivation: nsec bytes → BIP-39 mnemonic (entropy-to-words) →
  ///   PBKDF2 seed → BIP-32 master → m/44'/60'/0'/0/{accountIndex}
  ///
  /// This is MetaMask-compatible: pasting [getEvmMnemonic] into MetaMask
  /// will show the same addresses.
  EthPrivateKey getActiveEvmKey({int accountIndex = 0}) {
    return _deriveEvmKey(accountIndex);
  }

  /// Returns the EVM address at [accountIndex] without exposing the key.
  bip.EthereumAddress getEvmAddress({int accountIndex = 0}) {
    return _deriveEvmKey(accountIndex).address;
  }

  /// Scans HD account indices 0..[maxScan] to find the one whose address
  /// matches [address]. Throws [StateError] if no match is found.
  int findEvmAccountIndex(bip.EthereumAddress address, {int maxScan = 20}) =>
      _logger.spanSync('findEvmAccountIndex', () {
        for (var i = 0; i < maxScan; i++) {
          final derived = getEvmAddress(accountIndex: i);
          if (derived == address) return i;
        }
        throw StateError(
          'No HD account index (0..$maxScan) matches address '
          '${address.eip55With0x}',
        );
      });

  /// Returns the 24-word BIP-39 mnemonic derived from the Nostr private key
  /// entropy. Paste this into MetaMask to see all derived EVM addresses.
  List<String> getEvmMnemonic() => _logger.spanSync('getEvmMnemonic', () {
    final nsecHex = getActiveKey().privateKey!;
    final entropy = Uint8List.fromList(convert.hex.decode(nsecHex));
    return bip.entropyToMnemonic(entropy);
  });

  /// Derives the EVM private key at [accountIndex] from the Nostr key.
  EthPrivateKey _deriveEvmKey(int accountIndex) {
    return deriveEvmKey(getActiveKey().privateKey!, accountIndex: accountIndex);
  }

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

  /// Validates and returns a 64-char hex private key.
  ///
  /// Accepts:
  /// - 64-char hex private key
  /// - nsec1… bech32-encoded private key
  String _parseAndValidateKey(String input) =>
      _logger.spanSync('_parseAndValidateKey', () {
        final trimmed = input.trim();

        // Raw hex
        if (trimmed.length == 64 && _isHex(trimmed)) {
          return trimmed;
        }

        // nsec bech32
        if (trimmed.startsWith('nsec1')) {
          final decoded = Helpers.decodeBech32(trimmed);
          final hex = decoded[0];
          if (hex.isNotEmpty && hex.length == 64 && _isHex(hex)) {
            return hex;
          }
          throw Exception('Invalid nsec key');
        }

        throw Exception(
          'Invalid key format. Expected nsec or 64-char hex private key',
        );
      });

  bool _isHex(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
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
