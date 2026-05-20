import 'package:injectable/injectable.dart' hide Order;
import 'package:rxdart/rxdart.dart';
import 'package:sqlite3/common.dart';

import '../../util/custom_logger.dart';
import '../auth/auth.dart';
import 'hostr_user_config.dart';

/// Persistent, **typed** store for [HostrUserConfig].
///
/// Backed by the `config` table in the shared [AppDatabase] SQLite database.
/// Each field of [HostrUserConfig] maps to its own row in the table keyed by
/// `(pubkey, key)`, giving us:
///
///  * **Typed accessors** — no JSON serialisation round-trip; every field is
///    read/written individually with compile-time type safety.
///  * **Granular updates** — changing one field writes one row, not the whole
///    blob.
///  * **Queryability** — you can `SELECT * FROM config WHERE key = 'mode'`
///    across all users for analytics / debugging.
///
/// The in-memory [_cache] is loaded synchronously from SQLite on
/// [initialize] and kept in sync on every [update].
///
/// ### Adding a new config field
///
///  1. Add a field to [HostrUserConfig] with a default value.
///  2. Add a `static const _k...` key constant below.
///  3. Read it in [_loadFromDb] and write it in [_flush].
///
/// No SQL migration is needed — the generic `(pubkey, key, value)` schema
/// accommodates any number of keys.
@singleton
class UserConfigStore {
  // ── Config key constants ────────────────────────────────────────────────

  static const _kMode = 'mode';
  static const _kAutoWithdraw = 'auto_withdraw_enabled';

  // ── Dependencies ────────────────────────────────────────────────────────

  final CommonDatabase _db;
  final CustomLogger _logger;
  final Auth _auth;

  /// In-memory cache. Loaded via [initialize].
  HostrUserConfig? _cache;
  String? _loadedPubkey;

  /// Reactive stream of the current config. Seeded with
  /// [HostrUserConfig.defaults] and updated on every [update] call.
  final BehaviorSubject<HostrUserConfig> _subject = BehaviorSubject.seeded(
    HostrUserConfig.defaults,
  );

  UserConfigStore(this._db, this._logger, this._auth);

  // ── Public API ──────────────────────────────────────────────────────────

  /// Load the user config from SQLite. Idempotent per pubkey.
  Future<void> initialize() => _logger.span('initialize', () async {
    final pubkey = _currentPubkey();
    if (_cache != null && _loadedPubkey == pubkey) return;

    if (pubkey == null) {
      _cache = HostrUserConfig.defaults;
      _loadedPubkey = null;
      _subject.add(_cache!);
      return;
    }

    try {
      _cache = _loadFromDb(pubkey);
      _loadedPubkey = pubkey;
      _subject.add(_cache!);
      _logger.i('UserConfigStore loaded for $pubkey: $_cache');
    } catch (e) {
      _logger.e('Failed to load user config: $e');
      _cache = HostrUserConfig.defaults;
      _loadedPubkey = pubkey;
      _subject.add(_cache!);
    }
  });

  /// The current config. Triggers [initialize] if not yet loaded.
  Future<HostrUserConfig> get state async {
    await initialize();
    return _cache!;
  }

  /// Reactive stream of config changes. Always emits the current value
  /// first (BehaviorSubject).
  Stream<HostrUserConfig> get stream => _subject.stream;

  /// Replace the entire config. Persists to SQLite and notifies listeners.
  Future<void> update(HostrUserConfig config) =>
      _logger.span('update', () async {
        await initialize();
        _cache = config;
        _flush();
        _subject.add(config);
        _logger.d('UserConfigStore updated: $config');
      });

  /// Reset to defaults and wipe stored rows for the active user.
  Future<void> reset() => _logger.span('reset', () async {
    final pubkey = _currentPubkey();
    if (pubkey != null) {
      _db.execute('DELETE FROM config WHERE pubkey = ?', [pubkey]);
    }
    _cache = HostrUserConfig.defaults;
    _subject.add(_cache!);
    _logger.i('UserConfigStore reset to defaults');
  });

  /// Dispose the reactive stream. Call on app shutdown.
  Future<void> dispose() async {
    await _subject.close();
  }

  // ── Internal: typed read ────────────────────────────────────────────────

  HostrUserConfig _loadFromDb(String pubkey) {
    final rows = _db.select('SELECT key, value FROM config WHERE pubkey = ?', [
      pubkey,
    ]);

    if (rows.isEmpty) return HostrUserConfig.defaults;

    final map = {
      for (final r in rows) r['key'] as String: r['value'] as String,
    };

    return HostrUserConfig(
      mode: AppMode.fromString(map[_kMode]),
      autoWithdrawEnabled: (map[_kAutoWithdraw] ?? 'true') != 'false',
    );
  }

  // ── Internal: typed write ───────────────────────────────────────────────

  void _flush() {
    final pubkey = _loadedPubkey;
    if (pubkey == null || _cache == null) {
      _logger.w('UserConfigStore: skip flush — no active pubkey');
      return;
    }

    final config = _cache!;
    _put(pubkey, _kMode, config.mode.name);
    _put(pubkey, _kAutoWithdraw, config.autoWithdrawEnabled.toString());
  }

  void _put(String pubkey, String key, String value) {
    _db.execute(
      'INSERT OR REPLACE INTO config (pubkey, key, value) VALUES (?, ?, ?)',
      [pubkey, key, value],
    );
  }

  String? _currentPubkey() => _auth.activeKeyPair?.publicKey;
}
