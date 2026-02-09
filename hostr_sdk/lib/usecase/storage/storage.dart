import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/datasources/storage.dart';
import 'package:injectable/injectable.dart';

import '../auth/auth.dart';

abstract class StringListStorage {
  final Storage<List<String>> storage;
  final List<String> defaults;
  final Auth auth;

  StringListStorage({
    required this.storage,
    this.defaults = const [],
    required this.auth,
  });

  String? _currentUserKey() => auth.activeKeyPair?.publicKey;

  String _prefix(String pubkey) => '$pubkey:';

  List<String> _stripForUser(List<String> items, String pubkey) {
    final prefix = _prefix(pubkey);
    return items
        .where((item) => item.startsWith(prefix))
        .map((item) => item.substring(prefix.length))
        .toList();
  }

  List<String> _withoutUser(List<String> items, String pubkey) {
    final prefix = _prefix(pubkey);
    return items.where((item) => !item.startsWith(prefix)).toList();
  }

  Future<List<String>> get() async {
    final items = await storage.read() ?? <String>[];
    final pubkey = _currentUserKey();
    if (pubkey == null) {
      return [...defaults];
    }

    final scoped = _stripForUser(items, pubkey);
    return scoped.isEmpty ? [...defaults] : scoped;
  }

  Future<void> set(List<String> items) async {
    final pubkey = _currentUserKey();
    if (pubkey == null) {
      return;
    }

    final existing = await storage.read() ?? <String>[];
    final withoutUser = _withoutUser(existing, pubkey);
    final prefixed = items.map((item) => '${_prefix(pubkey)}$item').toList();
    await storage.save([...withoutUser, ...prefixed]);
  }

  Future<void> add(String item) async {
    final items = await get();
    if (!items.contains(item)) {
      items.add(item);
      await set(items);
    }
  }

  Future<void> remove(String item) async {
    final pubkey = _currentUserKey();
    if (pubkey == null) {
      return;
    }

    final existing = await storage.read() ?? <String>[];
    final prefix = _prefix(pubkey);
    final target = '$prefix$item';
    final updated = existing.where((value) => value != target).toList();
    await storage.save(updated);
  }

  Future<void> wipe() async {
    await storage.wipe();
  }
}

@singleton
class RelayStorage extends StringListStorage {
  RelayStorage(HostrConfig config, Auth auth)
    : super(
        storage: config.storage.relays,
        defaults: config.bootstrapRelays,
        auth: auth,
      );
}

@singleton
class NwcStorage extends StringListStorage {
  NwcStorage(HostrConfig config, Auth auth)
    : super(storage: config.storage.nwc, auth: auth);
}

@singleton
class AuthStorage {
  final Storage<List<String>> storage;

  AuthStorage(HostrConfig config) : storage = config.storage.auth;

  Future<List<String>> get() async {
    return await storage.read() ?? <String>[];
  }

  Future<void> set(List<String> items) async {
    await storage.save(items);
  }

  Future<void> add(String item) async {
    final items = await get();
    if (!items.contains(item)) {
      items.add(item);
      await set(items);
    }
  }

  Future<void> remove(String item) async {
    final existing = await storage.read() ?? <String>[];
    final updated = existing.where((value) => value != item).toList();
    await storage.save(updated);
  }

  Future<void> wipe() async {
    await storage.wipe();
  }
}
