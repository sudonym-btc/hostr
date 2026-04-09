import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:sqlite3/common.dart';

import '../../config.dart';
import '../../datasources/storage.dart';
import '../auth/auth.dart';

abstract class StringListStorage {
  final Storage<List<String>> _storage;
  final List<String> _defaults;
  final Auth _auth;
  Storage<List<String>> get storage => _storage;
  List<String> get defaults => _defaults;
  Auth get auth => _auth;

  StringListStorage({
    required Storage<List<String>> storage,
    List<String> defaults = const [],
    required Auth auth,
  }) : _storage = storage,
       _defaults = defaults,
       _auth = auth;

  String? _currentUserKey() => auth.getActiveKey().publicKey;

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

/// SQLite-backed relay storage.
///
/// Stores the user's relay list as a JSON array in the `config` table under
/// the key `'relays'`.  Relay URLs are **not** secret, so there is no reason
/// to keep them behind `flutter_secure_storage`.
@singleton
class RelayStorage {
  static const _configKey = 'relays';

  final CommonDatabase _db;
  final List<String> _defaults;
  final Auth _auth;

  RelayStorage(CommonDatabase db, HostrConfig config, Auth auth)
    : _db = db,
      _defaults = config.bootstrapRelays,
      _auth = auth;

  String? _currentPubkey() => _auth.activeKeyPair?.publicKey;

  Future<List<String>> get() async {
    final pubkey = _currentPubkey();
    if (pubkey == null) return [..._defaults];

    final rows = _db.select(
      'SELECT value FROM config WHERE pubkey = ? AND key = ?',
      [pubkey, _configKey],
    );

    if (rows.isEmpty) return [..._defaults];

    try {
      final decoded = jsonDecode(rows.first['value'] as String);
      if (decoded is List && decoded.isNotEmpty) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [..._defaults];
  }

  Future<void> set(List<String> items) async {
    final pubkey = _currentPubkey();
    if (pubkey == null) return;

    _db.execute(
      'INSERT OR REPLACE INTO config (pubkey, key, value) VALUES (?, ?, ?)',
      [pubkey, _configKey, jsonEncode(items)],
    );
  }

  Future<void> add(String item) async {
    final items = await get();
    if (!items.contains(item)) {
      items.add(item);
      await set(items);
    }
  }

  Future<void> remove(String item) async {
    final items = await get();
    items.remove(item);
    await set(items);
  }

  Future<void> wipe() async {
    final pubkey = _currentPubkey();
    if (pubkey == null) return;

    _db.execute('DELETE FROM config WHERE pubkey = ? AND key = ?', [
      pubkey,
      _configKey,
    ]);
  }
}

/// NWC connection strings contain secrets (`nostr+walletconnect://` URIs with
/// embedded keys).  These **must** remain in the platform secure store.
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
