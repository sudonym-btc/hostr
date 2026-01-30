import 'dart:async';

import 'package:convert/convert.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
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
    print('STORED PRIVATE KEY: ${items[0]}');
    KeyPair fetched = Bip340.fromPrivateKey(items[0]);
    print('KEYPAIR PRIV: ${fetched.privateKey}');
    print('KEYPAIR PUB: ${fetched.publicKey}');

    // Verify by deriving public key from private
    KeyPair verify = Bip340.fromPrivateKey(fetched.privateKey!);
    print('VERIFY PUB: ${verify.publicKey}');
    print('PUBKEYS MATCH: ${fetched.publicKey == verify.publicKey}');

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
