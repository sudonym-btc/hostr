import 'dart:convert';

import 'package:bip340/bip340.dart' as bip340;
import 'package:crypto/crypto.dart' as crypto;
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:pointycastle/ecc/api.dart';

class Bip340 {
  /// [message] is a hex string
  /// [privateKey] is a  32-bytes hex encoded string
  /// returns a hex string
  static String sign(String message, String privateKey) {
    final aux = Helpers.getSecureRandomHex(32);
    return bip340.sign(privateKey, message, aux);
  }

  /// [message] is a hex string
  /// [signature] is a hex string
  /// [publicKey] is a 32-bytes hex-encoded string
  /// true if the signature is valid otherwise false
  static bool verify(String message, String signature, String? publicKey) {
    if (publicKey == null) return false;
    return bip340.verify(publicKey, message, signature);
  }

  /// [privateKey] is a 32-bytes hex-encoded string
  /// returns the public key in form of 32-bytes hex-encoded string
  static String getPublicKey(String privateKey) {
    return bip340.getPublicKey(privateKey);
  }

  /// generates a new private key with a secure random generator
  static KeyPair generatePrivateKey() {
    final privKey = Helpers.getSecureRandomHex(32);
    return fromPrivateKey(privKey);
  }

  static KeyPair fromPrivateKey(String privateKey) {
    final pubKey = getPublicKey(privateKey);

    final privKeyHr = Helpers.encodeBech32(privateKey, 'nsec');
    final pubKeyHr = Helpers.encodeBech32(pubKey, 'npub');

    return KeyPair(privateKey, pubKey, privKeyHr, pubKeyHr);
  }
}

final BigInt _secp256k1Order = BigInt.parse(
  'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
  radix: 16,
);
final BigInt _secp256k1Prime = BigInt.parse(
  'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F',
  radix: 16,
);
final ECDomainParameters _secp256k1 = ECDomainParameters('secp256k1');

KeyPair saltedKey({
  required String key,
  required String salt,
}) {
  final parentScalar = BigInt.parse(key, radix: 16);
  if (parentScalar <= BigInt.zero || parentScalar >= _secp256k1Order) {
    throw StateError('Active private key is outside secp256k1 scalar range');
  }

  final tweak = _deriveTweakFromSalt(salt);

  final derived = (parentScalar + tweak) % _secp256k1Order;
  if (derived == BigInt.zero) {
    throw StateError(
      'Derived private key is zero; refusing to derive salted key',
    );
  }

  return Bip340.fromPrivateKey(derived.toRadixString(16).padLeft(64, '0'));
}

bool verifyPubKeyWithTeak({
  required String pubKey,
  required String salt,
  required String pubKeyWithTeak,
}) {
  final tweak = _deriveTweakFromSalt(salt);

  final baseEven = _xOnlyPubKeyToEvenPoint(pubKey);
  final tweakPoint = (_secp256k1.G * tweak)!;

  final baseOdd = _secp256k1.curve.createPoint(
    baseEven.x!.toBigInteger()!,
    _secp256k1Prime - baseEven.y!.toBigInteger()!,
  );

  final evenTweaked = (baseEven + tweakPoint)!;
  final oddTweaked = (baseOdd + tweakPoint)!;

  if (evenTweaked.isInfinity || oddTweaked.isInfinity) {
    return false;
  }

  final expectedEvenX =
      evenTweaked.x!.toBigInteger()!.toRadixString(16).padLeft(64, '0');
  final expectedOddX =
      oddTweaked.x!.toBigInteger()!.toRadixString(16).padLeft(64, '0');

  final candidate = pubKeyWithTeak.toLowerCase();
  return candidate == expectedEvenX || candidate == expectedOddX;
}

BigInt _deriveTweakFromSalt(String salt) {
  final tweakMaterial = utf8.encode(salt);
  final tweakDigest = crypto.sha256.convert(tweakMaterial);
  final tweak =
      BigInt.parse(tweakDigest.toString(), radix: 16) % _secp256k1Order;

  if (tweak == BigInt.zero) {
    throw StateError('Derived tweak is zero; refusing to derive salted key');
  }
  return tweak;
}

ECPoint _xOnlyPubKeyToEvenPoint(String pubKey) {
  final x = BigInt.parse(pubKey, radix: 16);
  if (x >= _secp256k1Prime) {
    throw StateError('Public key x-coordinate is out of secp256k1 field range');
  }

  final ySquared =
      (x.modPow(BigInt.from(3), _secp256k1Prime) + BigInt.from(7)) %
          _secp256k1Prime;
  final y = ySquared.modPow(
    (_secp256k1Prime + BigInt.one) ~/ BigInt.from(4),
    _secp256k1Prime,
  );

  if (y.modPow(BigInt.two, _secp256k1Prime) != ySquared) {
    throw StateError('Public key x-coordinate is not on secp256k1 curve');
  }

  final evenY = y.isEven ? y : _secp256k1Prime - y;
  return _secp256k1.curve.createPoint(x, evenY);
}
