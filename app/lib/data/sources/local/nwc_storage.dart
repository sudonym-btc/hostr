import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/nwc.dart';
import 'package:injectable/injectable.dart';

import 'secure_storage.dart';

@injectable
class NwcStorage {
  SecureStorage storage = getIt<SecureStorage>();
  CustomLogger logger = CustomLogger();

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

  set(List<String> items) async {
    await storage.set('nwc', items);
  }

  wipe() {
    return storage.set('nwc', null);
  }
}
