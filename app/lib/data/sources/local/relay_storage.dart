import 'package:hostr/config/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import 'secure_storage.dart';

@injectable
class RelayStorage {
  SecureStorage storage = getIt<SecureStorage>();
  CustomLogger logger = CustomLogger();
  Config config = getIt<Config>();

  Future<List<String>> get() async {
    var items = await storage.get('relays');
    if (items == null || items.length == 0) {
      return [...config.relays];
    }
    return List<String>.from(items);
  }

  Future<void> set(List<String> items) async {
    await storage.set('relays', items);
  }

  Future<void> add(String item) async {
    var items = await get();
    if (!items.contains(item)) {
      items.add(item);
      await set(items);
    }
  }

  Future<void> remove(String item) async {
    var items = await get();
    items.remove(item);
    await set(items);
  }

  Future<void> wipe() {
    return storage.set('relays', null);
  }
}
