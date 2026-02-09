import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';

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
    return items.isEmpty
        ? null
        : Uri.parse(
            NostrWalletConnectUri.parseConnectionUri(items.first).toUri(),
          );
  }

  Future<void> set(List<String> items) async {
    await storage.set('nwc', items);
  }

  Future<void> wipe() async {
    return storage.set('nwc', null);
  }
}
