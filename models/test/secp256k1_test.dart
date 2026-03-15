import 'package:models/bip340.dart';
import 'package:models/secp256k1.dart';
import 'package:test/test.dart';

void main() {
  group('secp256k1 engine', () {
    tearDown(() {
      setSecp256k1LoaderOverride(null);
    });

    test('verifySchnorrSignature falls back to pure Dart when fast load fails', () async {
      setSecp256k1LoaderOverride(() async {
        throw StateError('native backend unavailable');
      });

      final keyPair = Bip340.generatePrivateKey();
      const message = '0000000000000000000000000000000000000000000000000000000000000001';
      final signature = Bip340.sign(message, keyPair.privateKey!);

      expect(
        await verifySchnorrSignature(
          publicKey: keyPair.publicKey,
          message: message,
          signature: signature,
        ),
        isTrue,
      );
      expect(isFastSecp256k1BackendLoaded(), isFalse);
      expect(getSecp256k1LoadError(), isNotNull);
    });
  });
}
