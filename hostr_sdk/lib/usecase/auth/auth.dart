import 'dart:async';

import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:convert/convert.dart' as convert;
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:models/bip340.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web3dart/web3dart.dart';

import '../../util/main.dart';
import '../storage/storage.dart';

@Singleton()
class Auth {
  final Ndk ndk;
  final CustomLogger _logger;
  final AuthStorage authStorage;
  final BehaviorSubject<AuthState> _authStateContoller =
      BehaviorSubject<AuthState>.seeded(AuthInitial());
  ValueStream<AuthState> get authState => _authStateContoller;
  KeyPair? activeKeyPair;

  Auth({
    required this.ndk,
    required this.authStorage,
    required CustomLogger logger,
  }) : _logger = logger;

  /// Generates a new key pair and stores it, clearing any previous keys.
  Future<void> signup() async {
    _logger.i('AuthService.signup');
    await logout();
    await signin(Bip340.generatePrivateKey().privateKey!);
  }

  /// Imports a private key (hex) or mnemonic and stores it.
  Future<void> signin(String input) async {
    _logger.i('AuthService.signin');
    final privateKey = _parseAndValidateKey(input);
    await authStorage.set([privateKey]);
    await _loadActiveKeyPair();
    ensureNdkAccountsMatch();
    _syncAuthState();
  }

  /// Wipes key storage and secure storage.
  Future<void> logout() async {
    _logger.i('AuthService.logout');
    await authStorage.wipe();
    _loadActiveKeyPair();
    _syncAuthState();
  }

  Future<void> init() async {
    await _loadActiveKeyPair();
    ensureNdkAccountsMatch();
    _syncAuthState();
  }

  /// Returns whether there is an active key pair.
  Future<bool> isAuthenticated() async {
    await _loadActiveKeyPair();
    return activeKeyPair != null;
  }

  /// Restores NDK login using the stored key, if any.
  bool ensureNdkAccountsMatch() {
    if (activeKeyPair == null) {
      ndk.accounts.accounts.forEach((pubkey, account) {
        ndk.accounts.removeAccount(pubkey: pubkey);
      });
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
  }

  Future<void> _loadActiveKeyPair() async {
    final privateKey = await authStorage.get();
    activeKeyPair = privateKey.isEmpty
        ? null
        : Bip340.fromPrivateKey(privateKey[0]);
  }

  KeyPair getActiveKey() {
    if (activeKeyPair == null) {
      throw Exception('No active key pair');
    }
    return activeKeyPair!;
  }

  EthPrivateKey getActiveEvmKey() {
    return EthPrivateKey.fromHex(getActiveKey().privateKey!);
  }

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

  /// Validates and returns a private key hex string.
  ///
  /// Accepts:
  /// - 64-char hex private key
  /// - nsec1… bech32-encoded private key
  /// - 12 or 24 word BIP-39 mnemonic
  String _parseAndValidateKey(String input) {
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

    // Mnemonic (12 or 24 words)
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length == 12 || words.length == 24) {
      try {
        final mnemonic = Mnemonic.fromSentence(trimmed, Language.english);
        final hex = convert.hex.encode(mnemonic.entropy);
        if (hex.length == 64 && _isHex(hex)) {
          return hex;
        }
      } catch (_) {}
      throw Exception('Invalid mnemonic phrase');
    }

    throw Exception(
      'Invalid key format. Expected nsec, 64-char hex, or 12/24-word mnemonic',
    );
  }

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
