# Storage Strategy

## Current State

| Mechanism                   | What it stores                                    | Platform support                                          |
| --------------------------- | ------------------------------------------------- | --------------------------------------------------------- |
| `flutter_secure_storage`    | Auth keys, NWC URIs                               | ✅ All (Keychain / KeyStore / libsecret / localStorage\*) |
| `sqlite3` (raw)             | Operations, swap states, user config, relay lists | ✅ All (native + WASM)                                    |
| `hydrated_bloc` + `hive_ce` | Cubit state snapshots                             | ✅ All                                                    |
| `shared_preferences`        | Background task stats (debug screen, read-only)   | ✅ All                                                    |

Four engines for persistence is three too many.

## Recommendation: Two Tiers

### Tier 1 — Secrets → Platform Secure Store

**Use `flutter_secure_storage` exclusively for small, high-entropy secrets:**

- Private keys / nsec
- NWC connection strings
- Auth tokens / session secrets

Nothing else. No JSON blobs, no lists, no config objects.

**Why not SQLCipher / encrypted SQLite?**
Platform secure stores (Keychain, Android KeyStore, libsecret) are hardware-backed where available, receive OS-level lock-screen protection, and survive app updates without migration. An encrypted DB is a weaker, self-managed alternative that adds a key-management bootstrapping problem (where do you store the DB encryption key?). Keep it simple: let the OS guard secrets.

### Tier 2 — Everything Else → SQLite

Move **all** non-secret persistence into a single SQLite database:

| Current engine                        | Data                     | Migration                  |
| ------------------------------------- | ------------------------ | -------------------------- |
| `shared_preferences`                  | Background stats (debug) | Read-only, kept for now ✅ |
| `hydrated_bloc` / Hive                | Cubit state JSON         | → `state_cache` table      |
| `flutter_secure_storage` (non-secret) | User config, mode        | → `config` table ✅        |
| `flutter_secure_storage` (non-secret) | Relay lists              | → `config` table ✅        |
| `flutter_secure_storage` (secret)     | NWC URIs                 | Stays in secure storage ✅ |
| `OperationStateStore`                 | Swap & operation states  | Already there ✅           |

**Why SQLite over everything else:**

- **One engine, all platforms.** Already proven in the codebase via WASM on web and native everywhere else.
- **Structured queries.** `shared_preferences` and Hive are opaque key-value bags; SQLite lets you query, index, migrate, and expire data.
- **Atomic transactions.** The CAS / `BEGIN IMMEDIATE` pattern in `OperationStateStore` already works; extend it to all mutable state.
- **Schema migrations.** A `user_version` pragma + idempotent `ALTER TABLE` scripts is simpler than Hive's adapter versioning.
- **Eliminates Hive.** Hive CE is a community fork with uncertain maintenance. One less dependency.
- **Eliminates shared_preferences.** One fewer plugin to initialise at startup.

### Why Not Move _Secrets_ Into SQLite Too?

Unifying on a single encrypted SQLite DB (via SQLCipher) sounds appealing but:

1. **Key bootstrap problem** — you need a key to open the DB. That key must live in the platform secure store anyway, so you still depend on `flutter_secure_storage`.
2. **Platform secure stores are better** — Keychain / KeyStore offer biometric gating, hardware isolation, and secure-enclave storage that no userspace DB can match.
3. **Attack surface** — a single encrypted DB is one decryption away from leaking everything. Keeping secrets in the OS store and config in plaintext SQLite means a compromised DB leaks only non-secret data.

Two tiers is the industry-standard pattern (see Signal, 1Password, any banking app).

## Target Schema (single DB)

```sql
CREATE TABLE IF NOT EXISTS operations (
  pubkey      TEXT    NOT NULL,
  namespace   TEXT    NOT NULL,
  id          TEXT    NOT NULL,
  state       TEXT,
  is_terminal INTEGER NOT NULL DEFAULT 0,
  updated_at  TEXT,
  data        TEXT    NOT NULL,
  PRIMARY KEY (pubkey, namespace, id)
);

CREATE TABLE IF NOT EXISTS config (
  pubkey TEXT NOT NULL,
  key    TEXT NOT NULL,
  value  TEXT NOT NULL,
  PRIMARY KEY (pubkey, key)
);

CREATE TABLE IF NOT EXISTS state_cache (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

All three tables live in the same `hostr.db` file, managed by `AppDatabase`.

---

## AppDatabase & Migration System

### How it works

`AppDatabase` (`hostr_sdk/lib/datasources/app_database.dart`) wraps the raw `CommonDatabase` handle and runs versioned schema migrations on construction using SQLite's built-in `PRAGMA user_version`.

```
┌────────────────────────────────────────────────────────┐
│  openAppDb()                 (platform-specific open)  │
│       ↓  CommonDatabase                                │
│  AppDatabase(rawDb)          (runs migrations)         │
│       ↓  AppDatabase                                   │
│  HostrConfig(appDatabase:…)  (injected into SDK DI)    │
│       ↓                                                │
│  OperationStateStore / UserConfigStore / etc.           │
└────────────────────────────────────────────────────────┘
```

### PRAGMA user_version

SQLite stores a single integer in the database file header, readable/writable via:

```sql
PRAGMA user_version;          -- read  (returns 0 for a fresh DB)
PRAGMA user_version = 1;      -- write
```

This integer persists across connections and costs zero overhead — it's just a 4-byte field in the file header. No extra table, no row locks.

### Migration runner

On construction, `AppDatabase` compares the stored version against its `schemaVersion` constant and runs each `_vN()` step that hasn't been applied yet, inside a single `BEGIN IMMEDIATE` transaction:

```dart
void _migrate() {
  final current = db.select('PRAGMA user_version').first.values.first as int;
  if (current >= schemaVersion) return;          // already up-to-date

  db.execute('BEGIN IMMEDIATE');
  try {
    if (current < 1) _v1();                      // initial schema
    // if (current < 2) _v2();                   // future migration
    db.execute('PRAGMA user_version = $schemaVersion');
    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK');                       // atomic: all-or-nothing
    rethrow;
  }
}
```

### Adding a new migration

1. **Bump `schemaVersion`** (e.g. `1 → 2`).
2. **Add a `_v2()` method** with the DDL/DML:
   ```dart
   void _v2() {
     db.execute('ALTER TABLE config ADD COLUMN expires_at TEXT');
   }
   ```
3. **Add the gate** in `_migrate()`:
   ```dart
   if (current < 2) _v2();
   ```

Because each step uses `IF NOT EXISTS` / `IF EXISTS` guards, migrations are idempotent — re-running one is harmless. The `BEGIN IMMEDIATE` transaction ensures atomicity across all steps.

### Migration rules

| Rule                                     | Why                                                                |
| ---------------------------------------- | ------------------------------------------------------------------ |
| Never remove or rename a `_vN()` method  | Users on older versions must run all steps sequentially            |
| Use `IF NOT EXISTS` / `IF EXISTS` guards | Makes each step idempotent (safe to re-run)                        |
| Keep steps small and focused             | Easier to reason about, easier to test                             |
| Never modify an existing `_vN()`         | Already-migrated databases won't re-run it; put fixes in `_v(N+1)` |
| Test by opening a fresh DB               | `PRAGMA user_version` starts at 0 → all steps run                  |

---

## Typed User Config

### Problem with JSON blobs

The old `UserConfigStore` serialised the entire `HostrUserConfig` as a single JSON string in `KeyValueStorage`. This meant:

- No type safety at the storage boundary — a malformed string silently breaks config
- Changing one field rewrites the entire blob
- No way to query config values across users without parsing JSON

### Solution: one row per field

The `config` table stores `(pubkey, key, value)`. Each field of `HostrUserConfig` maps to its own key constant:

```dart
static const _kMode = 'mode';
static const _kAutoWithdraw = 'auto_withdraw_enabled';
```

**Reading** — `SELECT key, value FROM config WHERE pubkey = ?` returns all rows for the user, which are assembled into a typed `HostrUserConfig`:

```dart
HostrUserConfig _loadFromDb(String pubkey) {
  final rows = _db.select(
    'SELECT key, value FROM config WHERE pubkey = ?', [pubkey],
  );
  final map = {for (final r in rows) r['key'] as String: r['value'] as String};

  return HostrUserConfig(
    mode: AppMode.fromString(map[_kMode]),
    autoWithdrawEnabled: (map[_kAutoWithdraw] ?? 'true') != 'false',
  );
}
```

**Writing** — each field is written individually:

```dart
void _flush() {
  _put(pubkey, _kMode, config.mode.name);
  _put(pubkey, _kAutoWithdraw, config.autoWithdrawEnabled.toString());
}
```

### Adding a new config field

1. Add the field to `HostrUserConfig` with a default value.
2. Add a `static const _k...` key constant in `UserConfigStore`.
3. Read it in `_loadFromDb` with a sensible fallback.
4. Write it in `_flush`.

**No SQL migration is needed** — the generic `(pubkey, key, value)` schema accommodates any number of keys. Missing rows resolve to the default value in Dart. This gives us the flexibility of a JSON blob with the queryability and type safety of structured storage.

### Type conversion reference

| Dart type  | Stored as            | Read pattern                                   |
| ---------- | -------------------- | ---------------------------------------------- |
| `String`   | Raw string           | `map[key] ?? defaultValue`                     |
| `bool`     | `'true'` / `'false'` | `(map[key] ?? 'true') != 'false'`              |
| `int`      | `'42'`               | `int.tryParse(map[key] ?? '') ?? defaultValue` |
| `enum`     | `.name`              | `EnumType.fromString(map[key])`                |
| `DateTime` | ISO 8601             | `DateTime.tryParse(map[key] ?? '')`            |

---

## SqliteHydratedStorage (Hive replacement)

`SqliteHydratedStorage` (`app/lib/setup/sqlite_hydrated_storage.dart`) implements hydrated_bloc's `Storage` interface backed by the `state_cache` table. It pre-loads all rows into an in-memory `Map` on construction so that `HydratedCubit.fromJson` reads are instant. Writes flush synchronously to SQLite — identical behaviour to the old Hive implementation, but with zero extra dependencies.

---

## Migration Path

1. ~~**Add `AppDatabase` wrapper**~~ ✅ Done
2. ~~**Move `UserConfigStore` to SQLite**~~ ✅ Done
3. ~~**Replace `HydratedStorage` with `SqliteHydratedStorage`**~~ ✅ Done
4. ~~**Move `RelayStorage` to SQLite**~~ ✅ Done — stores relay list as JSON in `config` table.
5. **`NwcStorage` stays in `flutter_secure_storage`** — NWC URIs contain embedded private keys.
6. ~~**Remove `shared_preferences` for env persistence**~~ ✅ Done — env is now threaded through Workmanager `inputData` instead of persisted to `SharedPreferences`. The package is retained only for the debug Background Tasks screen which reads Workmanager's own internal stats.
7. **Audit `SecureKeyValueStorage`** — ensure only actual secrets remain (auth keys, NWC URIs).
8. **Remove `hive_ce`** from `pubspec.yaml` + delete `setup/hydrated_storage.dart`.

## TL;DR

|            | Secrets                           | Everything else                          |
| ---------- | --------------------------------- | ---------------------------------------- |
| **Engine** | `flutter_secure_storage`          | SQLite (`sqlite3` / WASM)                |
| **Scope**  | Private keys, NWC strings, tokens | Config, state, relays, caches            |
| **Why**    | OS-backed, hardware-isolated      | Queryable, transactional, one dependency |
