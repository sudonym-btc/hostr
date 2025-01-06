import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
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
    return items;
  }

  set(List<String> items) async {
    await storage.set('relays', items);
  }

  wipe() {
    return storage.set('relays', null);
  }
}
