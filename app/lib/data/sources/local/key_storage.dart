import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

import 'secure_storage.dart';

@injectable
class KeyStorage {
  SecureStorage storage = getIt<SecureStorage>();
  CustomLogger logger = CustomLogger();

  Future<NostrKeyPairs?> getActiveKeyPair() async {
    var items = await storage.get('keys');
    if (items == null || items.length == 0) {
      return null;
    }
    return NostrKeyPairs(private: items[0]);
  }

  set(String item) async {
    var key = NostrKeyPairs.generate();
    await storage.set('keys', [key.private]);
    return item;
  }

  get() async {
    var items = await storage.get('keys');
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
    return storage.set('keys', null);
  }
}
