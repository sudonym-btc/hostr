import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

import 'secure_storage.dart';

@injectable
class NwcStorage {
  SecureStorage storage = getIt<SecureStorage>();
  CustomLogger logger = CustomLogger();

  Future<List<String>> get() async {
    var items = await storage.get('nwc');
    if (items == null || items.length == 0) {
      return [];
    }
    return items;
  }

  set(List<String> items) async {
    var key = NostrKeyPairs.generate();
    await storage.set('nwc', [key.private]);
  }

  wipe() {
    return storage.set('nwc', null);
  }
}
