import 'dart:async';
import 'dart:typed_data';

import 'package:coinlib/coinlib.dart';
import 'package:convert/convert.dart';

import 'bip340.dart';
import 'src/secp256k1_loader_stub.dart'
    if (dart.library.io) 'src/secp256k1_loader_io.dart';

typedef Secp256k1Loader = Future<void> Function();

Secp256k1Loader? _loaderOverride;
String? _loaderOverrideLabel;
Future<void>? _loadFuture;
Object? _lastLoadError;
bool _fastBackendLoaded = false;

void setSecp256k1LoaderOverride(
  Secp256k1Loader? overrideLoader, {
  String? label,
}) {
  _loaderOverride = overrideLoader;
  _loaderOverrideLabel = label;
  _loadFuture = null;
  _lastLoadError = null;
  _fastBackendLoaded = false;
}

Object? getSecp256k1LoadError() => _lastLoadError;

bool isFastSecp256k1BackendLoaded() => _fastBackendLoaded;

String describeSecp256k1Backend() {
  final attemptedBackend =
      _loaderOverrideLabel ?? 'coinlib.loadCoinlib (bundled)';

  if (_fastBackendLoaded) {
    return 'fast backend: $attemptedBackend';
  }

  if (_lastLoadError != null) {
    return 'pure-dart fallback: Bip340.verify() '
        '(fast backend failed via $attemptedBackend: $_lastLoadError)';
  }

  return 'pending fast backend load via $attemptedBackend';
}

Future<void> loadSecp256k1Backend() async {
  await (_loadFuture ??= _attemptFastBackendLoad());
}

void primeSecp256k1Backend() {
  unawaited(loadSecp256k1Backend());
}

Future<bool> verifySchnorrSignature({
  required String publicKey,
  required String message,
  required String signature,
}) async {
  await loadSecp256k1Backend();

  if (_fastBackendLoaded) {
    try {
      final schnorrSignature = SchnorrSignature.fromHex(signature);
      final schnorrPublicKey = ECPublicKey.fromXOnlyHex(publicKey);
      return schnorrSignature.verify(schnorrPublicKey, hexToBytes(message));
    } catch (_) {
      // Fall through to the pure-Dart verifier below.
    }
  }

  return Bip340.verify(message, signature, publicKey);
}

bool verifySchnorrSignatureSync({
  required String publicKey,
  required String message,
  required String signature,
}) {
  if (_fastBackendLoaded) {
    try {
      final schnorrSignature = SchnorrSignature.fromHex(signature);
      final schnorrPublicKey = ECPublicKey.fromXOnlyHex(publicKey);
      return schnorrSignature.verify(schnorrPublicKey, hexToBytes(message));
    } catch (_) {
      // Fall through to the pure-Dart verifier below.
    }
  }

  return Bip340.verify(message, signature, publicKey);
}

/// Signs a [message] (hex-encoded event id) with a [privateKey] (32-byte hex)
/// using BIP-340 Schnorr signatures.
///
/// Uses the fast native secp256k1 backend when loaded, otherwise falls back to
/// the pure-Dart `Bip340.sign()` implementation.
String signSchnorr({
  required String privateKey,
  required String message,
}) {
  if (_fastBackendLoaded) {
    try {
      final privKey = ECPrivateKey.fromHex(privateKey);
      final sig = SchnorrSignature.sign(privKey, hexToBytes(message));
      return bytesToHex(sig.data);
    } catch (_) {
      // Fall through to the pure-Dart signer below.
    }
  }

  return Bip340.sign(message, privateKey);
}

class Secp256k1TweakedKeyPairResult {
  const Secp256k1TweakedKeyPairResult({
    required this.privateKeyHex,
    required this.publicKeyHex,
    required this.parity,
  });

  final String privateKeyHex;
  final String publicKeyHex;
  final bool parity;
}

class Secp256k1TweakedPublicKeyResult {
  const Secp256k1TweakedPublicKeyResult({
    required this.publicKeyHex,
    required this.parity,
  });

  final String publicKeyHex;
  final bool parity;
}

Secp256k1TweakedKeyPairResult? tweakKeyPairWithFastSecp256k1({
  required String privateKey,
  required Uint8List tweak32,
}) {
  if (!_fastBackendLoaded) return null;

  final tweakedKey = ECPrivateKey.fromHex(privateKey).xonly.tweak(tweak32);
  if (tweakedKey == null) {
    throw StateError('Tweaked private key is zero; refusing to derive key');
  }

  return Secp256k1TweakedKeyPairResult(
    privateKeyHex: hex.encode(tweakedKey.data),
    publicKeyHex: tweakedKey.pubkey.xhex,
    parity: !tweakedKey.pubkey.yIsEven,
  );
}

Secp256k1TweakedPublicKeyResult? tweakPublicKeyWithFastSecp256k1({
  required String publicKey,
  required Uint8List tweak32,
}) {
  if (!_fastBackendLoaded) return null;

  final tweakedKey = ECPublicKey.fromXOnlyHex(publicKey).tweak(tweak32);
  if (tweakedKey == null) {
    throw StateError('Tweaked public key is at infinity');
  }

  return Secp256k1TweakedPublicKeyResult(
    publicKeyHex: tweakedKey.xhex,
    parity: !tweakedKey.yIsEven,
  );
}

String? untweakPublicKeyWithFastSecp256k1({
  required String tweakedPublicKey,
  required bool tweakedPublicKeyParity,
  required Uint8List tweak32,
}) {
  if (!_fastBackendLoaded) return null;

  final untweakedKey = ECPublicKey.fromHex(
    '${tweakedPublicKeyParity ? '03' : '02'}$tweakedPublicKey',
  ).tweak(_negateScalar(tweak32));

  if (untweakedKey == null || !untweakedKey.yIsEven) {
    return null;
  }

  return untweakedKey.xhex;
}

bool? verifyTweakedPublicKeyWithFastSecp256k1({
  required String publicKey,
  required Uint8List tweak32,
  required String tweakedPublicKey,
  required bool tweakedPublicKeyParity,
}) {
  if (!_fastBackendLoaded) return null;

  final tweaked = tweakPublicKeyWithFastSecp256k1(
    publicKey: publicKey,
    tweak32: tweak32,
  );

  return tweaked != null &&
      tweaked.publicKeyHex == tweakedPublicKey.toLowerCase() &&
      tweaked.parity == tweakedPublicKeyParity;
}

Future<void> _attemptFastBackendLoad() async {
  try {
    if (_loaderOverride == null) {
      await prepareBundledSecp256k1BinaryIfNeeded();
    }
    await (_loaderOverride ?? loadCoinlib)();
    _fastBackendLoaded = true;
  } catch (error) {
    _lastLoadError = error;
    _fastBackendLoaded = false;
  }
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
