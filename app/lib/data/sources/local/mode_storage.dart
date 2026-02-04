import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

import 'secure_storage.dart';

@injectable
class ModeStorage {
  SecureStorage storage = getIt<SecureStorage>();
  CustomLogger logger = CustomLogger();

  Future<String> set(String item) async {
    await storage.set('mode', item);
    return item;
  }

  Future<String> get() async {
    var item = await storage.get('mode') as String?;
    if (item == null) {
      return 'guest';
    }
    return item;
  }

  Future<dynamic> wipe() {
    return storage.set('mode', null);
  }
}
