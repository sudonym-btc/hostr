import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:pointycastle/ecc/api.dart';

final BigInt _secp256k1Order = BigInt.parse(
  'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
  radix: 16,
);
final BigInt _secp256k1Prime = BigInt.parse(
  'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F',
  radix: 16,
);
final ECDomainParameters _secp256k1 = ECDomainParameters('secp256k1');

class Bip341TweakedPublicKey {
  const Bip341TweakedPublicKey({
    required this.publicKey,
    required this.parity,
  });

  /// 32-byte x-only pubkey, lowercase hex.
  final String publicKey;

  /// `true` when the tweaked point has an odd Y coordinate.
  final bool parity;
}

class Bip341TweakedKeyPair {
  const Bip341TweakedKeyPair({
    required this.keyPair,
    required this.parity,
  });

  final KeyPair keyPair;
  final bool parity;

  String get publicKey => keyPair.publicKey;
  String? get privateKey => keyPair.privateKey;
}

/// Tweaks a private key using a BIP341-style additive tweak derived from [salt].
///
/// The returned keypair is normalized for BIP340 Schnorr signing, while [parity]
/// captures the Y parity of the actual tweaked point before x-only reduction.
Bip341TweakedKeyPair tweakKeyPair({
  required String privateKey,
  required String salt,
}) {
  final parentScalar = _parseScalar(privateKey);
  final canonicalParentScalar = _normalizeScalarToEvenY(parentScalar);
  final basePoint = (_secp256k1.G * canonicalParentScalar)!;
  final tweak = _deriveTweakFromSalt(salt);
  final tweakPoint = (_secp256k1.G * tweak)!;
  final tweakedPoint = (basePoint + tweakPoint)!;

  if (tweakedPoint.isInfinity) {
    throw StateError('Tweaked public key is at infinity');
  }

  final rawScalar = (canonicalParentScalar + tweak) % _secp256k1Order;
  if (rawScalar == BigInt.zero) {
    throw StateError('Tweaked private key is zero; refusing to derive key');
  }

  final parity = tweakedPoint.y!.toBigInteger()!.isOdd;
  final signingScalar = parity ? _secp256k1Order - rawScalar : rawScalar;
  final signingKey = Bip340.fromPrivateKey(
    signingScalar.toRadixString(16).padLeft(64, '0'),
  );

  return Bip341TweakedKeyPair(keyPair: signingKey, parity: parity);
}

/// Tweaks an x-only public key using a BIP341-style additive tweak derived from
/// [salt], returning the tweaked x-only key and its Y parity bit.
Bip341TweakedPublicKey tweakPublicKey({
  required String publicKey,
  required String salt,
}) {
  final basePoint = _xOnlyPubKeyToPoint(publicKey, oddY: false);
  final tweak = _deriveTweakFromSalt(salt);
  final tweakPoint = (_secp256k1.G * tweak)!;
  final tweakedPoint = (basePoint + tweakPoint)!;

  if (tweakedPoint.isInfinity) {
    throw StateError('Tweaked public key is at infinity');
  }

  return Bip341TweakedPublicKey(
    publicKey: _pointToXOnlyHex(tweakedPoint),
    parity: tweakedPoint.y!.toBigInteger()!.isOdd,
  );
}

/// Reconstructs the original x-only public key from the tweaked x-only pubkey,
/// the tweaked pubkey parity, and the original [salt].
String? untweakPublicKey({
  required String tweakedPublicKey,
  required bool tweakedPublicKeyParity,
  required String salt,
}) {
  final tweak = _deriveTweakFromSalt(salt);
  final tweakPoint = (_secp256k1.G * tweak)!;
  final tweakedPoint = _xOnlyPubKeyToPoint(
    tweakedPublicKey,
    oddY: tweakedPublicKeyParity,
  );

  final basePoint = (tweakedPoint - tweakPoint)!;
  if (basePoint.isInfinity) return null;
  if (basePoint.y!.toBigInteger()!.isOdd) return null;

  return _pointToXOnlyHex(basePoint);
}

bool verifyTweakedPublicKey({
  required String publicKey,
  required String salt,
  required String tweakedPublicKey,
  required bool tweakedPublicKeyParity,
}) {
  final tweaked = tweakPublicKey(publicKey: publicKey, salt: salt);
  return tweaked.publicKey == tweakedPublicKey.toLowerCase() &&
      tweaked.parity == tweakedPublicKeyParity;
}

BigInt _parseScalar(String privateKey) {
  final scalar = BigInt.parse(privateKey, radix: 16);
  if (scalar <= BigInt.zero || scalar >= _secp256k1Order) {
    throw StateError('Private key scalar is outside secp256k1 scalar range');
  }
  return scalar;
}

BigInt _normalizeScalarToEvenY(BigInt scalar) {
  final point = (_secp256k1.G * scalar)!;
  final y = point.y!.toBigInteger()!;
  return y.isEven ? scalar : _secp256k1Order - scalar;
}

BigInt _deriveTweakFromSalt(String salt) {
  final tweakMaterial = utf8.encode(salt);
  final tweakDigest = crypto.sha256.convert(tweakMaterial);
  final tweak =
      BigInt.parse(tweakDigest.toString(), radix: 16) % _secp256k1Order;

  if (tweak == BigInt.zero) {
    throw StateError('Derived tweak is zero; refusing to derive tweaked key');
  }

  return tweak;
}

ECPoint _xOnlyPubKeyToPoint(String pubKey, {required bool oddY}) {
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

  final resolvedY = y.isOdd == oddY ? y : _secp256k1Prime - y;
  return _secp256k1.curve.createPoint(x, resolvedY);
}

String _pointToXOnlyHex(ECPoint point) {
  return point.x!.toBigInteger()!.toRadixString(16).padLeft(64, '0');
}
