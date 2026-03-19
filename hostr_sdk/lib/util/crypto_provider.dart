import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// Pluggable crypto backend so that hostr_sdk doesn't depend on any
/// Flutter-only package (like `webcrypto`).
///
/// The Flutter app should supply a [CryptoProvider] backed by `webcrypto`
/// (native/WASM, fast on mobile & web).  Server-side Dart consumers can
/// use the built-in [DartCryptoProvider] which delegates to the pure-Dart
/// `crypto` package.
abstract class CryptoProvider {
  /// HMAC-SHA-256.
  Future<Uint8List> hmacSha256(List<int> key, List<int> data);

  /// SHA-256 digest.
  Future<Uint8List> sha256(List<int> data);

  /// PBKDF2 using HMAC-SHA-512.
  Future<Uint8List> pbkdf2HmacSha512({
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int bits,
  });
}

// ---------------------------------------------------------------------------
// Global provider (defaults to pure-Dart implementation)
// ---------------------------------------------------------------------------

CryptoProvider _cryptoProvider = DartCryptoProvider();

/// The active [CryptoProvider].
///
/// Defaults to [DartCryptoProvider].  Flutter apps should call
/// [setCryptoProvider] early in bootstrap with a `webcrypto`-backed
/// implementation for better performance on mobile / web.
CryptoProvider get cryptoProvider => _cryptoProvider;

/// Replace the global [CryptoProvider].
void setCryptoProvider(CryptoProvider provider) {
  _cryptoProvider = provider;
}

// ---------------------------------------------------------------------------
// Pure-Dart implementation (uses package:crypto, no Flutter dependency)
// ---------------------------------------------------------------------------

/// [CryptoProvider] backed by the pure-Dart `crypto` package.
///
/// Suitable for server-side Dart (e.g. the escrow daemon) and tests.
/// Performance is adequate for occasional key-derivation but slower than
/// native/WASM on mobile and web — use a `webcrypto`-backed provider there.
class DartCryptoProvider implements CryptoProvider {
  @override
  Future<Uint8List> hmacSha256(List<int> key, List<int> data) async {
    final hmac = crypto.Hmac(crypto.sha256, key);
    return Uint8List.fromList(hmac.convert(data).bytes);
  }

  @override
  Future<Uint8List> sha256(List<int> data) async {
    return Uint8List.fromList(crypto.sha256.convert(data).bytes);
  }

  @override
  Future<Uint8List> pbkdf2HmacSha512({
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int bits,
  }) async {
    final length = bits ~/ 8;
    final hmac = crypto.Hmac(crypto.sha512, password);
    final result = <int>[];
    var block = 1;

    while (result.length < length) {
      // U_1 = PRF(password, salt ‖ INT_32_BE(block))
      final saltBlock = Uint8List(salt.length + 4);
      saltBlock.setAll(0, salt);
      saltBlock[salt.length + 0] = (block >> 24) & 0xff;
      saltBlock[salt.length + 1] = (block >> 16) & 0xff;
      saltBlock[salt.length + 2] = (block >> 8) & 0xff;
      saltBlock[salt.length + 3] = block & 0xff;

      var u = Uint8List.fromList(hmac.convert(saltBlock).bytes);
      final xor = Uint8List.fromList(u);

      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < xor.length; j++) {
          xor[j] ^= u[j];
        }
      }

      result.addAll(xor);
      block++;
    }

    return Uint8List.fromList(result.sublist(0, length));
  }
}
