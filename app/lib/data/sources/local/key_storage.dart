import 'dart:async';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import 'secure_storage.dart';

@singleton
class KeyStorage {
  CustomLogger logger = CustomLogger();
  KeyPair? keyPair;

  Future<KeyPair?> getActiveKeyPair() async {
    if (keyPair != null) {
      return keyPair;
    }
    var items = await getIt<SecureStorage>().get('keys');
    if (items == null || items.length == 0) {
      return null;
    }
    KeyPair fetched = Bip340.fromPrivateKey(items[0]);
    keyPair = fetched;
    return fetched;
  }

  KeyPair? getActiveKeyPairSync() {
    return keyPair;
  }

  set(String item) async {
    await getIt<SecureStorage>().set('keys', [item]);
    return item;
  }

  get() async {
    var items = await getIt<SecureStorage>().get('keys');
    if (items == null || items.length == 0) {
      return [];
    }
    return items;
  }

  create() {
    var key = Bip340.generatePrivateKey();
    return key;
  }

  wipe() {
    keyPair = null;
    return getIt<SecureStorage>().set('keys', null);
  }
}

EthPrivateKey getEthCredentials(String nostrPrivateKey) {
  return EthPrivateKey.fromHex(hex.encode(hex.decode(nostrPrivateKey)));
}

EthereumAddress getEthAddressFromPublicKey(String bip340PublicKey) {
  final ecCurve = ECCurve_secp256k1();
  Uint8List publicKeyBytes = Uint8List.fromList(hex.decode(bip340PublicKey));

  // Ensure the public key is in the correct format
  if (publicKeyBytes.length == 32) {
    // Add the 0x02 prefix for compressed public key
    publicKeyBytes = Uint8List.fromList([0x02] + publicKeyBytes);
  } else if (publicKeyBytes.length == 64) {
    // Add the 0x04 prefix for uncompressed public key
    publicKeyBytes = Uint8List.fromList([0x04] + publicKeyBytes);
  }

  // Decode the public key
  final ecPoint = ecCurve.curve.decodePoint(publicKeyBytes);
  final uncompressedPublicKey = ecPoint!
      .getEncoded(false)
      .sublist(1); // Remove the prefix byte

  // Generate Ethereum address from the uncompressed public key
  return EthereumAddress.fromPublicKey(PublicKey(uncompressedPublicKey));
}
