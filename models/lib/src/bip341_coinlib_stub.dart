import 'dart:typed_data';

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

Future<void> loadBip341Backend() async {}

void primeCoinlib() {}

CoinlibTweakedKeyPairResult? tweakKeyPairWithCoinlib({
  required String privateKey,
  required Uint8List tweak32,
}) {
  return null;
}

CoinlibTweakedPublicKeyResult? tweakPublicKeyWithCoinlib({
  required String publicKey,
  required Uint8List tweak32,
}) {
  return null;
}

String? untweakPublicKeyWithCoinlib({
  required String tweakedPublicKey,
  required bool tweakedPublicKeyParity,
  required Uint8List tweak32,
}) {
  return null;
}

bool? verifyTweakedPublicKeyWithCoinlib({
  required String publicKey,
  required Uint8List tweak32,
  required String tweakedPublicKey,
  required bool tweakedPublicKeyParity,
}) {
  return null;
}
