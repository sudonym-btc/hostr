import 'dart:async';
import 'dart:typed_data';

import 'package:coinlib/coinlib.dart';
import 'package:convert/convert.dart';

class CoinlibTweakedKeyPairResult {
  const CoinlibTweakedKeyPairResult({
    required this.privateKeyHex,
    required this.publicKeyHex,
    required this.parity,
  });

  final String privateKeyHex;
  final String publicKeyHex;
  final bool parity;
}

class CoinlibTweakedPublicKeyResult {
  const CoinlibTweakedPublicKeyResult({
    required this.publicKeyHex,
    required this.parity,
  });

  final String publicKeyHex;
  final bool parity;
}

Future<void>? _loadFuture;
bool _isLoaded = false;

Future<void> loadBip341Backend() async {
  primeCoinlib();
  await _loadFuture;
}

void primeCoinlib() {
  _loadFuture ??= loadCoinlib().then((_) {
    _isLoaded = true;
  });
}

CoinlibTweakedKeyPairResult? tweakKeyPairWithCoinlib({
  required String privateKey,
  required Uint8List tweak32,
}) {
  if (!_isLoaded) return null;

  final tweakedKey = ECPrivateKey.fromHex(privateKey).xonly.tweak(tweak32);
  if (tweakedKey == null) {
    throw StateError('Tweaked private key is zero; refusing to derive key');
  }

  return CoinlibTweakedKeyPairResult(
    privateKeyHex: hex.encode(tweakedKey.data),
    publicKeyHex: tweakedKey.pubkey.xhex,
    parity: !tweakedKey.pubkey.yIsEven,
  );
}

CoinlibTweakedPublicKeyResult? tweakPublicKeyWithCoinlib({
  required String publicKey,
  required Uint8List tweak32,
}) {
  if (!_isLoaded) return null;

  final tweakedKey = ECPublicKey.fromXOnlyHex(publicKey).tweak(tweak32);
  if (tweakedKey == null) {
    throw StateError('Tweaked public key is at infinity');
  }

  return CoinlibTweakedPublicKeyResult(
    publicKeyHex: tweakedKey.xhex,
    parity: !tweakedKey.yIsEven,
  );
}

String? untweakPublicKeyWithCoinlib({
  required String tweakedPublicKey,
  required bool tweakedPublicKeyParity,
  required Uint8List tweak32,
}) {
  if (!_isLoaded) return null;

  final untweakedKey = ECPublicKey.fromHex(
    '${tweakedPublicKeyParity ? '03' : '02'}$tweakedPublicKey',
  ).tweak(_negateScalar(tweak32));

  if (untweakedKey == null || !untweakedKey.yIsEven) {
    return null;
  }

  return untweakedKey.xhex;
}

bool? verifyTweakedPublicKeyWithCoinlib({
  required String publicKey,
  required Uint8List tweak32,
  required String tweakedPublicKey,
  required bool tweakedPublicKeyParity,
}) {
  if (!_isLoaded) return null;

  final tweaked = tweakPublicKeyWithCoinlib(
    publicKey: publicKey,
    tweak32: tweak32,
  );

  return tweaked != null &&
      tweaked.publicKeyHex == tweakedPublicKey.toLowerCase() &&
      tweaked.parity == tweakedPublicKeyParity;
}

Uint8List _negateScalar(Uint8List tweak32) {
  final tweak = BigInt.parse(hex.encode(tweak32), radix: 16);
  final negated = (_secp256k1Order - tweak) % _secp256k1Order;
  return _scalarToBytes(negated);
}

Uint8List _scalarToBytes(BigInt value) {
  final bytes = Uint8List(32);
  var remaining = value;
  for (var i = 31; i >= 0; i--) {
    bytes[i] = (remaining & BigInt.from(0xff)).toInt();
    remaining >>= 8;
  }
  return bytes;
}

final BigInt _secp256k1Order = BigInt.parse(
  'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
  radix: 16,
);
