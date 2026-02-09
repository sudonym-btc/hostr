import 'dart:async';

import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

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
    return Bip340.fromPrivateKey(items[0]);
  }

  KeyPair? getActiveKeyPairSync() {
    return keyPair;
  }

  Future<String> set(String item) async {
    await getIt<SecureStorage>().set('keys', [item]);
    return item;
  }

  Future<dynamic> get() async {
    var items = await getIt<SecureStorage>().get('keys');
    if (items == null || items.length == 0) {
      return [];
    }
    return items;
  }

  KeyPair create() {
    var key = Bip340.generatePrivateKey();
    return key;
  }

  Future<dynamic> wipe() {
    keyPair = null;
    return getIt<SecureStorage>().set('keys', null);
  }
}
