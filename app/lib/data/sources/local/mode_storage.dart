import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
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
