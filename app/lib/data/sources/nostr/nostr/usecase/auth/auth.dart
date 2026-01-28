import 'package:hostr/export.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class Auth {
  final Ndk ndk;
  final CustomLogger _logger = CustomLogger();
  final KeyStorage keyStorage;
  final SecureStorage secureStorage;
  KeyPair? activeKeyPair;

  Auth({
    required this.ndk,
    required this.keyStorage,
    required this.secureStorage,
  });

  /// Generates a new key pair and stores it, clearing any previous keys.
  Future<void> signup() async {
    _logger.i('AuthService.signup');
    await logout();
    String key = await keyStorage.create();
    await signin(key);
  }

  /// Imports a private key (hex) or mnemonic and stores it.
  Future<void> signin(String input) async {
    _logger.i('AuthService.signin');
    final privateKey = _parseAndValidateKey(input);
    await keyStorage.set(privateKey);
    activeKeyPair = await keyStorage.getActiveKeyPair();
    // Setup NDK with the imported key
    final pubkey = activeKeyPair?.publicKey;
    if (pubkey != null) {
      ndk.accounts.loginPrivateKey(privkey: privateKey, pubkey: pubkey);
    }
  }

  /// Returns whether there is an active key pair.
  Future<bool> isAuthenticated() async {
    final keyPair = await keyStorage.getActiveKeyPair();
    return keyPair != null;
  }

  /// Restores NDK login using the stored key, if any.
  Future<bool> ensureNdkLoggedIn() async {
    final keyPair = await keyStorage.getActiveKeyPair();
    if (keyPair == null ||
        keyPair.publicKey == null ||
        keyPair.privateKey == null) {
      return false;
    }

    final pubkey = keyPair.publicKey!;
    final privkey = keyPair.privateKey!;
    final alreadyLoggedIn =
        ndk.accounts.accounts.containsKey(pubkey) ||
        ndk.accounts.getPublicKey() == pubkey;

    if (!alreadyLoggedIn) {
      _logger.i('Restoring NDK session for stored key');
      ndk.accounts.loginPrivateKey(privkey: privkey, pubkey: pubkey);
    }

    return true;
  }

  /// Wipes key storage and secure storage.
  Future<void> logout() async {
    _logger.i('AuthService.logout');
    await keyStorage.wipe();
    await secureStorage.wipe();
    ndk.accounts.accounts.forEach((pubkey, account) {
      ndk.accounts.removeAccount(pubkey: pubkey);
    });
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
