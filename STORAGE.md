# Storage Strategy

## Current State

| Mechanism                   | What it stores                                     | Platform support                                          |
| --------------------------- | -------------------------------------------------- | --------------------------------------------------------- |
| `flutter_secure_storage`    | Auth keys, NWC URIs, relay lists, user config JSON | ✅ All (Keychain / KeyStore / libsecret / localStorage\*) |
| `sqlite3` (raw)             | Operation & swap states (`OperationStateStore`)    | ✅ All (native + WASM)                                    |
| `hydrated_bloc` + `hive_ce` | Cubit state snapshots                              | ✅ All                                                    |
| `shared_preferences`        | Environment string, background task stats          | ✅ All                                                    |

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

| Current engine                        | Data                           | Migration                        |
| ------------------------------------- | ------------------------------ | -------------------------------- |
| `shared_preferences`                  | Environment, background stats  | → `config` table                 |
| `hydrated_bloc` / Hive                | Cubit state JSON               | → `state_cache` table            |
| `flutter_secure_storage` (non-secret) | Relay lists, user config, mode | → `user_config` / `relay` tables |
| `OperationStateStore`                 | Swap & operation states        | Already there ✅                 |

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
-- Existing
CREATE TABLE IF NOT EXISTS operations ( … );  -- no change

-- New
CREATE TABLE IF NOT EXISTS config (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS state_cache (
  pubkey TEXT NOT NULL,
  key    TEXT NOT NULL,
  json   TEXT NOT NULL,
  PRIMARY KEY (pubkey, key)
);
```

Open the same DB file that `OperationStateStore` already opens. Wrap it behind a thin `AppDatabase` class that owns the `CommonDatabase` handle, runs migrations on open, and hands out domain-specific DAOs.

## Migration Path

1. **Add `AppDatabase` wrapper** around the existing `CommonDatabase` open logic. Run `PRAGMA user_version` migrations on open.
2. **Move `UserConfigStore`** from `SecureKeyValueStorage` → `config` table. On first run, read the old secure-storage keys and insert them, then delete the old keys.
3. **Move `RelayStorage` / `NwcStorage`** non-secret list data → `config` or dedicated tables.
4. **Replace `HydratedStorage`** with a custom `Storage` impl backed by `state_cache`. Remove `hive_ce`.
5. **Remove `shared_preferences`** — migrate `hostr.env` to `config` table.
6. **Audit `SecureKeyValueStorage`** — ensure only actual secrets remain.

Each step is independently shippable. No backward compatibility needed, so old keys/boxes can be deleted after one-way migration.

## TL;DR

|            | Secrets                           | Everything else                          |
| ---------- | --------------------------------- | ---------------------------------------- |
| **Engine** | `flutter_secure_storage`          | SQLite (`sqlite3` / WASM)                |
| **Scope**  | Private keys, NWC strings, tokens | Config, state, relays, caches            |
| **Why**    | OS-backed, hardware-isolated      | Queryable, transactional, one dependency |
