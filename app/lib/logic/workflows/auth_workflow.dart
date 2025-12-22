import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

/// Workflow handling authentication flows (signup and signin).
/// Signup: key generation → storage → NDK setup
/// Signin: key import → validation → storage → NDK setup
@injectable
class AuthWorkflow {
  final KeyStorage _keyStorage;
  final SecureStorage _secureStorage;
  final CustomLogger _logger = CustomLogger();

  AuthWorkflow({
    required KeyStorage keyStorage,
    required SecureStorage secureStorage,
    required Ndk ndk,
  }) : _keyStorage = keyStorage,
       _secureStorage = secureStorage;

  /// Executes signup flow: generates new keys and stores them.
  Future<void> signup() async {
    _logger.i('Starting signup flow');

    try {
      // Clear any existing keys first
      await logout();

      // Generate and store new key pair
      await _keyStorage.create();

      _logger.i('Signup completed successfully');
    } catch (e) {
      _logger.e('Signup failed: $e');
      rethrow;
    }
  }

  /// Executes signin flow: imports and validates key, then stores it.
  Future<void> signin(String input) async {
    _logger.i('Starting signin flow');

    try {
      // Import key from private key hex or mnemonic
      final privateKey = await _parseAndValidateKey(input);

      // Store the private key
      await _keyStorage.set(privateKey);

      _logger.i('Signin completed successfully');
    } catch (e) {
      _logger.e('Signin failed: $e');
      rethrow;
    }
  }

  /// Checks if user is authenticated by verifying stored keys.
  Future<bool> isAuthenticated() async {
    final keyPair = await _keyStorage.getActiveKeyPair();
    return keyPair != null;
  }

  /// Logs out user by wiping stored keys and secure storage.
  Future<void> logout() async {
    _logger.i('Starting logout flow');

    try {
      await _keyStorage.wipe();
      await _secureStorage.wipe();

      _logger.i('Logout completed successfully');
    } catch (e) {
      _logger.e('Logout failed: $e');
      rethrow;
    }
  }

  /// Parses input as either private key hex or mnemonic and returns KeyPair.
  Future<String> _parseAndValidateKey(String input) async {
    // Try as private key hex first
    if (input.length == 64 && _isHex(input)) {
      _logger.d('Parsing as private key hex');
      return input;
    }

    // Try as mnemonic (BIP39)
    final words = input.trim().split(RegExp(r'\s+'));
    if (words.length == 12 || words.length == 24) {
      _logger.d('Parsing as BIP39 mnemonic');
      // TODO: Implement BIP39 mnemonic parsing
      throw UnimplementedError('Mnemonic import not yet implemented');
    }

    throw Exception(
      'Invalid key format. Expected 64-char hex or 12/24-word mnemonic',
    );
  }

  bool _isHex(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
  }

  /// Gets the current user's public key if authenticated.
  Future<String?> getCurrentPubkey() async {
    final keyPair = await _keyStorage.getActiveKeyPair();
    return keyPair?.publicKey;
  }
}
