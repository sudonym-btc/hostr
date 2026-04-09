import 'dart:convert';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:sqlite3/common.dart';

/// [Storage] implementation backed by the `state_cache` SQLite table.
///
/// Replaces the Hive-backed `_IsolatedHydratedStorage`.  All reads come
/// from the in-memory [_cache] (populated at construction), so
/// `HydratedCubit.fromJson` is never blocked on I/O.  Writes are
/// synchronously flushed to SQLite — the same behaviour as the old Hive
/// implementation.
///
/// The `state_cache` table is created by [AppDatabase._v1]; this class
/// only reads and writes rows.
class SqliteHydratedStorage implements Storage {
  final CommonDatabase _db;
  final Map<String, dynamic> _cache;

  SqliteHydratedStorage._(this._db, this._cache);

  /// Pre-loads every row into memory so subsequent [read] calls are instant.
  factory SqliteHydratedStorage(CommonDatabase db) {
    final rows = db.select('SELECT key, value FROM state_cache');
    final cache = <String, dynamic>{};
    for (final row in rows) {
      final key = row['key'] as String;
      final raw = row['value'] as String;
      try {
        cache[key] = jsonDecode(raw);
      } catch (_) {
        cache[key] = raw;
      }
    }
    return SqliteHydratedStorage._(db, cache);
  }

  @override
  dynamic read(String key) => _cache[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _cache[key] = value;
    _db.execute(
      'INSERT OR REPLACE INTO state_cache (key, value) VALUES (?, ?)',
      [key, jsonEncode(value)],
    );
  }

  @override
  Future<void> delete(String key) async {
    _cache.remove(key);
    _db.execute('DELETE FROM state_cache WHERE key = ?', [key]);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
    _db.execute('DELETE FROM state_cache');
  }

  @override
  Future<void> close() async {
    // No-op — the CommonDatabase lifetime is owned by AppDatabase.
  }
}
