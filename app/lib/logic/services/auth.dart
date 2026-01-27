import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

/// Domain-level authentication service.
/// Encapsulates signup/signin/logout and key management without UI concerns.
@lazySingleton
class AuthService {
  final KeyStorage _keyStorage;
  final SecureStorage _secureStorage;
  final CustomLogger _logger = CustomLogger();
  final Ndk _ndk;

  AuthService({
    required KeyStorage keyStorage,
    required SecureStorage secureStorage,
    required Ndk ndk,
  }) : _keyStorage = keyStorage,
       _secureStorage = secureStorage,
       _ndk = ndk;

  /// Generates a new key pair and stores it, clearing any previous keys.
  Future<void> signup() async {
    _logger.i('AuthService.signup');
    await logout();
    await _keyStorage.create();
    await signin((await _keyStorage.getActiveKeyPair())!.privateKey!);
  }

  /// Imports a private key (hex) or mnemonic and stores it.
  Future<void> signin(String input) async {
    _logger.i('AuthService.signin');
    final privateKey = _parseAndValidateKey(input);
    await _keyStorage.set(privateKey);

    // Setup NDK with the imported key
    final pubkey = await getCurrentPubkey();
    if (pubkey != null) {
      _ndk.accounts.loginPrivateKey(privkey: privateKey, pubkey: pubkey);
    }
  }

  /// Returns whether there is an active key pair.
  Future<bool> isAuthenticated() async {
    final keyPair = await _keyStorage.getActiveKeyPair();
    return keyPair != null;
  }

  /// Restores NDK login using the stored key, if any.
  Future<bool> ensureNdkLoggedIn() async {
    final keyPair = await _keyStorage.getActiveKeyPair();
    if (keyPair == null ||
        keyPair.publicKey == null ||
        keyPair.privateKey == null) {
      return false;
    }

    final pubkey = keyPair.publicKey!;
    final privkey = keyPair.privateKey!;
    final alreadyLoggedIn =
        _ndk.accounts.accounts.containsKey(pubkey) ||
        _ndk.accounts.getPublicKey() == pubkey;

    if (!alreadyLoggedIn) {
      _logger.i('Restoring NDK session for stored key');
      _ndk.accounts.loginPrivateKey(privkey: privkey, pubkey: pubkey);
    }

    return true;
  }

  /// Wipes key storage and secure storage.
  Future<void> logout() async {
    _logger.i('AuthService.logout');
    await _keyStorage.wipe();
    await _secureStorage.wipe();
    _ndk.accounts.accounts.forEach((pubkey, account) {
      _ndk.accounts.removeAccount(pubkey: pubkey);
    });
  }

  /// Returns the current public key if present.
  Future<String?> getCurrentPubkey() async {
    final keyPair = await _keyStorage.getActiveKeyPair();
    return keyPair?.publicKey;
  }

  /// Validates and returns a private key hex string.
  String _parseAndValidateKey(String input) {
    final trimmed = input.trim();
    if (trimmed.length == 64 && _isHex(trimmed)) {
      return trimmed;
    }

    // Mnemonic support can be added here when available.
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length == 12 || words.length == 24) {
      throw UnimplementedError('Mnemonic import not yet implemented');
    }

    throw Exception(
      'Invalid key format. Expected 64-char hex or 12/24-word mnemonic',
    );
  }

  bool _isHex(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
  }
}
