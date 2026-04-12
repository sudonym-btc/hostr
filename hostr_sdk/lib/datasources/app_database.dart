import 'package:sqlite3/common.dart';

/// Central SQLite database wrapper with versioned schema migrations.
///
/// Owns the [CommonDatabase] handle and guarantees every table is created
/// and migrated **before** any DAO touches the database.
///
/// ## Migration strategy
///
/// SQLite stores a free integer in the file header accessible via
/// `PRAGMA user_version`.  On construction we compare that value against
/// [schemaVersion] and run each incremental `_vN()` step that hasn't been
/// applied yet.  The entire migration sequence is wrapped in a single
/// `BEGIN IMMEDIATE` transaction to make it atomic.
///
/// To add a migration:
///   1. Bump [schemaVersion].
///   2. Add a `_vN()` method with the DDL/DML.
///   3. Add `if (current < N) _vN();` to [_migrate].
///
/// Because each step uses `IF NOT EXISTS` / `IF EXISTS` guards, migrations
/// are idempotent — re-running one is a harmless no-op.
class AppDatabase {
  /// Current schema version.  Bump when adding a new migration step.
  static const schemaVersion = 2;

  /// The raw database handle.  Exposed so that existing DAOs
  /// (e.g. [OperationStateStore]) can keep accepting [CommonDatabase].
  final CommonDatabase db;

  AppDatabase(this.db) {
    db.execute('PRAGMA busy_timeout = 5000');
    _migrate();
  }

  // ── Migration runner ──────────────────────────────────────────────────

  void _migrate() {
    final current = db.select('PRAGMA user_version').first.values.first as int;

    if (current >= schemaVersion) return;

    db.execute('BEGIN IMMEDIATE');
    try {
      if (current < 1) _v1();
      if (current < 2) _v2();

      db.execute('PRAGMA user_version = $schemaVersion');
      db.execute('COMMIT');
    } catch (e) {
      try {
        db.execute('ROLLBACK');
      } catch (_) {}
      rethrow;
    }
  }

  // ── V1 — initial unified schema ──────────────────────────────────────

  void _v1() {
    // Operations (previously created by OperationStateStore)
    db.execute('''
      CREATE TABLE IF NOT EXISTS operations (
        pubkey      TEXT    NOT NULL,
        namespace   TEXT    NOT NULL,
        id          TEXT    NOT NULL,
        state       TEXT,
        is_terminal INTEGER NOT NULL DEFAULT 0,
        updated_at  TEXT,
        data        TEXT    NOT NULL,
        PRIMARY KEY (pubkey, namespace, id)
      )
    ''');

    // Typed user config — one row per (pubkey, key) pair.
    // Replaces the JSON-blob-in-KeyValueStorage approach.
    db.execute('''
      CREATE TABLE IF NOT EXISTS config (
        pubkey TEXT NOT NULL,
        key    TEXT NOT NULL,
        value  TEXT NOT NULL,
        PRIMARY KEY (pubkey, key)
      )
    ''');

    // Hydrated-bloc state cache — replaces Hive.
    db.execute('''
      CREATE TABLE IF NOT EXISTS state_cache (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── V2 — displayed notifications log ─────────────────────────────────

  void _v2() {
    // Generic log of notification IDs that have been shown at least once.
    // Used to suppress duplicate OS notifications across app restarts.
    db.execute('''
      CREATE TABLE IF NOT EXISTS displayed_notifications (
        id         TEXT PRIMARY KEY,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }
}
