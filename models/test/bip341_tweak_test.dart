import 'package:models/bip340.dart';
import 'package:models/bip341.dart';
import 'package:test/test.dart';

void main() {
  group('bip341 tweaking', () {
    test('tweakKeyPair and untweakPublicKey round-trip a regression case', () {
      final base = Bip340.fromPrivateKey('1'.padLeft(64, '0'));
      const salt = 'salt-0';

      final tweaked = tweakKeyPair(
        privateKey: base.privateKey!,
        salt: salt,
      );

      final untweaked = untweakPublicKey(
        tweakedPublicKey: tweaked.publicKey,
        tweakedPublicKeyParity: tweaked.parity,
        salt: salt,
      );

      expect(untweaked, base.publicKey);
    });

    test('tweakPublicKey matches tweakKeyPair output and parity', () {
      final base = Bip340.fromPrivateKey(
        'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      );
      const salt = 'public-key-match';

      final tweakedPrivate = tweakKeyPair(
        privateKey: base.privateKey!,
        salt: salt,
      );
      final tweakedPublic = tweakPublicKey(
        publicKey: base.publicKey,
        salt: salt,
      );

      expect(tweakedPublic.publicKey, tweakedPrivate.publicKey);
      expect(tweakedPublic.parity, tweakedPrivate.parity);
    });

    test('round-trips multiple salts for the same base key', () {
      final base = Bip340.fromPrivateKey(
        '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      );

      for (var i = 0; i < 32; i++) {
        final salt = 'roundtrip-salt-$i';
        final tweaked = tweakKeyPair(
          privateKey: base.privateKey!,
          salt: salt,
        );

        final untweaked = untweakPublicKey(
          tweakedPublicKey: tweaked.publicKey,
          tweakedPublicKeyParity: tweaked.parity,
          salt: salt,
        );

        expect(untweaked, base.publicKey, reason: 'failed for $salt');
      }
    });

    test('verifyTweakedPublicKey validates key and parity', () {
      final base = Bip340.fromPrivateKey(
        'f'.padLeft(64, '0'),
      );
      const salt = 'verify-case';
      final tweaked = tweakPublicKey(publicKey: base.publicKey, salt: salt);

      expect(
        verifyTweakedPublicKey(
          publicKey: base.publicKey,
          salt: salt,
          tweakedPublicKey: tweaked.publicKey,
          tweakedPublicKeyParity: tweaked.parity,
        ),
        isTrue,
      );

      expect(
        verifyTweakedPublicKey(
          publicKey: base.publicKey,
          salt: salt,
          tweakedPublicKey: tweaked.publicKey,
          tweakedPublicKeyParity: !tweaked.parity,
        ),
        isFalse,
      );
    });

    test('wrong parity does not recover the base public key', () {
      final base = Bip340.fromPrivateKey(
        '42'.padLeft(64, '0'),
      );
      const salt = 'wrong-parity';
      final tweaked = tweakKeyPair(privateKey: base.privateKey!, salt: salt);

      final untweaked = untweakPublicKey(
        tweakedPublicKey: tweaked.publicKey,
        tweakedPublicKeyParity: !tweaked.parity,
        salt: salt,
      );

      expect(untweaked, isNot(base.publicKey));
    });
  });
}
