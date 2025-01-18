import 'package:bip39/bip39.dart';
import 'package:dart_bip32_bip44/dart_bip32_bip44.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import 'secure_storage.dart';

@singleton
class KeyStorage {
  CustomLogger logger = CustomLogger();
  NostrKeyPairs? keyPair;

  Future<NostrKeyPairs?> getActiveKeyPair() async {
    if (keyPair != null) {
      return keyPair;
    }
    var items = await getIt<SecureStorage>().get('keys');
    if (items == null || items.length == 0) {
      return null;
    }
    NostrKeyPairs fetched = NostrKeyPairs(private: items[0]);
    keyPair = fetched;
    return fetched;
  }

  NostrKeyPairs? getActiveKeyPairSync() {
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
    var key = NostrKeyPairs.generate();
    return set(key.private);
  }

  wipe() {
    keyPair = null;
    return getIt<SecureStorage>().set('keys', null);
  }
}

/// Returns BIP32 Root Key account 0 for ETH chain
EthPrivateKey getEthCredentials(String seedHex) {
  String mnemonic = entropyToMnemonic(
      seedHex); // SeedHex is the entropy, need to convert to mnemonic and back to seed to get full-length entropy to seed chain
  String seed = mnemonicToSeedHex(mnemonic);

  // print("SeedHex: ${seedHex.length}, Seed: ${seed.length}"); // SeedHex: 64, Seed: 128

  Chain c = Chain.seed(seed);
  ExtendedKey key = c.forPath(ETH_PRIV_PATH);
  return EthPrivateKey.fromHex(key.privateKeyHex());
}
