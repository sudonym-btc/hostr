import 'dart:typed_data';

import 'package:hostr_sdk/hostr_sdk.dart' show CryptoProvider;
import 'package:webcrypto/webcrypto.dart' as wc;

/// [CryptoProvider] backed by the `webcrypto` package which delegates to
/// platform-native crypto (Web Crypto API on web, BoringSSL/CommonCrypto on
/// mobile).  Much faster than the pure-Dart implementation for hot paths
/// like PBKDF2.
class FlutterCryptoProvider implements CryptoProvider {
  @override
  Future<Uint8List> hmacSha256(List<int> key, List<int> data) async {
    final hmacKey = await wc.HmacSecretKey.importRawKey(
      Uint8List.fromList(key),
      wc.Hash.sha256,
    );
    final mac = await hmacKey.signBytes(Uint8List.fromList(data));
    return Uint8List.fromList(mac);
  }

  @override
  Future<Uint8List> sha256(List<int> data) async {
    final hash = await wc.Hash.sha256.digestBytes(Uint8List.fromList(data));
    return Uint8List.fromList(hash);
  }

  @override
  Future<Uint8List> pbkdf2HmacSha512({
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int bits,
  }) async {
    final key = await wc.Pbkdf2SecretKey.importRawKey(password);
    final derived = await key.deriveBits(
      bits,
      wc.Hash.sha512,
      salt,
      iterations,
    );
    return Uint8List.fromList(derived);
  }
}
