import 'package:hostr/core/main.dart';
import 'package:injectable/injectable.dart';

import '../nostr/nostr/usecase/nwc/nwc.dart';
import 'secure_storage.dart';

@singleton
class NwcStorage {
  final SecureStorage storage;
  final CustomLogger logger = CustomLogger();

  NwcStorage(this.storage);

  Future<List> get() async {
    var items = await storage.get('nwc');
    if (items == null || items.length == 0) {
      return [];
    }
    return items;
  }

  Future<Uri?> getUri() async {
    var items = await get();
    return items.isEmpty ? null : parseNwc(items.first);
  }

  Future<void> set(List<String> items) async {
    await storage.set('nwc', items);
  }

  Future<void> wipe() async {
    return storage.set('nwc', null);
  }
}
