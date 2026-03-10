import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqlite3/common.dart';

import '../../../util/custom_logger.dart';
import '../../auth/auth.dart';

// ─────────────────────────────────────────────────────────────────────────
// § Result types for atomic CAS operations
// ─────────────────────────────────────────────────────────────────────────

/// Outcome of an atomic CAS claim attempt.
enum CasOutcome { claimed, busyBackoff, raceForward }

/// Result of [OperationStateStore.atomicClaim].
class CasClaimResult {
  final CasOutcome outcome;

  /// Persisted JSON for the caller to sync from on [CasOutcome.raceForward].
  final Map<String, dynamic>? persistedJson;

  /// Age of the busy state on [CasOutcome.busyBackoff] (for logging).
  final Duration? busyAge;

  const CasClaimResult._(this.outcome, {this.persistedJson, this.busyAge});

  static const claimed = CasClaimResult._(CasOutcome.claimed);

  const CasClaimResult.busyBackoff({required Duration age})
    : this._(CasOutcome.busyBackoff, busyAge: age);

  const CasClaimResult.raceForward([Map<String, dynamic>? json])
    : this._(CasOutcome.raceForward, persistedJson: json);
}

/// Result of [OperationStateStore.writeIfOwned].
class WriteIfOwnedResult {
  final bool written;

  /// Persisted JSON for sync if the write was rejected.
  final Map<String, dynamic>? persistedJson;

  const WriteIfOwnedResult._(this.written, [this.persistedJson]);

  static const success = WriteIfOwnedResult._(true);

  const WriteIfOwnedResult.rejected(Map<String, dynamic>? json)
    : this._(false, json);
}

// ─────────────────────────────────────────────────────────────────────────
// § OperationStateStore — SQLite-backed
// ─────────────────────────────────────────────────────────────────────────

/// SQLite-backed persistent store for serialisable cubit states.
///
/// Replaces the old JSON-in-KeyValueStorage approach with a proper
/// relational backend.  Every mutating multi-statement operation runs
/// inside a `BEGIN IMMEDIATE` transaction, which acquires an exclusive
/// write lock on the database file.  This eliminates all cross-isolate
/// race conditions — no application-level locks are needed.
///
/// The [CommonDatabase] is accepted from outside (injected via
/// [HostrConfig]).  The SDK only imports `package:sqlite3/common.dart`
/// (the cross-platform interface), so the host app can use either the
/// native FFI implementation or the WASM implementation for web.
///
/// Table schema: `operations(pubkey, namespace, id, state, is_terminal,
/// updated_at, data)` with composite PK `(pubkey, namespace, id)`.
/// The `data` column holds the full JSON blob for backwards-compatible
/// round-tripping.  The extracted columns (`state`, `is_terminal`,
/// `updated_at`) enable efficient CAS queries without parsing JSON.
@singleton
class OperationStateStore {
  final CommonDatabase _db;
  final CustomLogger _logger;
  final Auth _auth;

  /// Fires on every mutation so listeners (e.g. AutoWithdrawService) can
  /// re-check their gates.
  final PublishSubject<void> _onChanged = PublishSubject();

  OperationStateStore(this._db, CustomLogger logger, this._auth)
    : _logger = logger.scope('op-store') {
    // Wait up to 5 s for a concurrent writer (another isolate) to finish.
    _db.execute('PRAGMA busy_timeout = 5000');
    _db.execute('''
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
  }

  // ── Public CRUD ─────────────────────────────────────────────────────

  /// Write (upsert) a state. [json] **must** contain an `'id'` key.
  Future<void> write(String namespace, String id, Map<String, dynamic> json) =>
      _logger.span('write', () async {
        final pubkey = _currentPubkey();
        if (pubkey == null) return;

        _db.execute(
          '''INSERT OR REPLACE INTO operations
             (pubkey, namespace, id, state, is_terminal, updated_at, data)
             VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [
            pubkey,
            namespace,
            id,
            json['state'] as String?,
            json['isTerminal'] == true ? 1 : 0,
            json['updatedAt'] as String?,
            jsonEncode(json),
          ],
        );
        _onChanged.add(null);
      });

  /// Read a single entry by [id].
  Future<Map<String, dynamic>?> read(String namespace, String id) =>
      _logger.span('read', () async {
        final pubkey = _currentPubkey();
        if (pubkey == null) return null;

        try {
          final rows = _db.select(
            'SELECT data FROM operations '
            'WHERE pubkey = ? AND namespace = ? AND id = ?',
            [pubkey, namespace, id],
          );
          if (rows.isEmpty) return null;
          return jsonDecode(rows.first['data'] as String)
              as Map<String, dynamic>;
        } catch (e) {
          _logger.e('OperationStateStore: failed to read $namespace/$id: $e');
          return null;
        }
      });

  /// Read all entries for a [namespace].
  Future<List<Map<String, dynamic>>> readAll(String namespace) => _logger.span(
    'readAll',
    () async {
      final pubkey = _currentPubkey();
      if (pubkey == null) return [];

      try {
        final rows = _db.select(
          'SELECT data FROM operations WHERE pubkey = ? AND namespace = ?',
          [pubkey, namespace],
        );
        return rows
            .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
            .toList();
      } catch (e) {
        _logger.e('OperationStateStore: failed to readAll $namespace: $e');
        return [];
      }
    },
  );

  /// Remove a single entry.
  Future<void> remove(String namespace, String id) =>
      _logger.span('remove', () async {
        final pubkey = _currentPubkey();
        if (pubkey == null) return;

        _db.execute(
          'DELETE FROM operations '
          'WHERE pubkey = ? AND namespace = ? AND id = ?',
          [pubkey, namespace, id],
        );
        _onChanged.add(null);
      });

  /// Whether any entries in [namespace] have `is_terminal = 0`.
  Future<bool> hasNonTerminal(String namespace) =>
      _logger.span('hasNonTerminal', () async {
        final pubkey = _currentPubkey();
        if (pubkey == null) return false;

        final rows = _db.select(
          'SELECT 1 FROM operations '
          'WHERE pubkey = ? AND namespace = ? AND is_terminal = 0 '
          'LIMIT 1',
          [pubkey, namespace],
        );
        return rows.isNotEmpty;
      });

  /// Fires whenever any write/remove occurs.
  Stream<void> get onChanged => _onChanged.stream;

  /// Remove terminal entries older than [age].
  Future<int> pruneTerminal(String namespace, Duration age) =>
      _logger.span('pruneTerminal', () async {
        final pubkey = _currentPubkey();
        if (pubkey == null) return 0;

        final cutoff = DateTime.now().subtract(age).toIso8601String();
        _db.execute(
          '''DELETE FROM operations
             WHERE pubkey = ? AND namespace = ?
               AND is_terminal = 1
               AND updated_at IS NOT NULL
               AND updated_at < ?''',
          [pubkey, namespace, cutoff],
        );
        return _db.updatedRows;
      });

  // ── Atomic CAS operations ──────────────────────────────────────────

  /// Atomically claim a state transition.
  ///
  /// Runs inside `BEGIN IMMEDIATE` which acquires the database write lock,
  /// guaranteeing no other connection (including another Dart isolate) can
  /// modify the row between our SELECT and UPDATE.
  ///
  /// Returns [CasClaimResult.claimed] if the busy state was written,
  /// [CasClaimResult.busyBackoff] if another process owns the step,
  /// or [CasClaimResult.raceForward] if the state already moved past us.
  CasClaimResult atomicClaim({
    required String namespace,
    required String id,
    required Set<String> allowedStates,
    required String busyStateName,
    required Map<String, dynamic> busyStateJson,
    required Duration staleTimeout,
  }) {
    final pubkey = _currentPubkey();
    if (pubkey == null) return CasClaimResult.claimed;

    _db.execute('BEGIN IMMEDIATE');
    try {
      final rows = _db.select(
        'SELECT state, updated_at, data FROM operations '
        'WHERE pubkey = ? AND namespace = ? AND id = ?',
        [pubkey, namespace, id],
      );

      if (rows.isEmpty) {
        _db.execute('COMMIT');
        return CasClaimResult.claimed;
      }

      final row = rows.first;
      final persistedState = row['state'] as String?;
      final data = row['data'] as String;

      if (persistedState == null) {
        _db.execute('COMMIT');
        return const CasClaimResult.raceForward();
      }

      // ── Check: is the persisted state in the allowed set? ─────────
      if (!allowedStates.contains(persistedState)) {
        final json = _tryDecode(data);
        _db.execute('COMMIT');
        return CasClaimResult.raceForward(json);
      }

      // ── Check: if persisted state IS the busy state, is it stale? ─
      if (persistedState == busyStateName && staleTimeout > Duration.zero) {
        final updatedAtStr = row['updated_at'] as String?;
        final updatedAt = updatedAtStr != null
            ? DateTime.tryParse(updatedAtStr)
            : null;
        if (updatedAt != null) {
          final age = DateTime.now().difference(updatedAt);
          if (age < staleTimeout) {
            _db.execute('COMMIT');
            return CasClaimResult.busyBackoff(age: age);
          }
          // Stale — fall through to claim/reclaim.
        }
      }

      // ── Claim: write busy state ───────────────────────────────────
      final busyData = jsonEncode(busyStateJson);
      final now =
          busyStateJson['updatedAt'] as String? ??
          DateTime.now().toIso8601String();

      _db.execute(
        '''UPDATE operations
           SET state = ?, is_terminal = 0, updated_at = ?, data = ?
           WHERE pubkey = ? AND namespace = ? AND id = ?''',
        [busyStateName, now, busyData, pubkey, namespace, id],
      );

      _db.execute('COMMIT');
      _onChanged.add(null);
      return CasClaimResult.claimed;
    } catch (e) {
      try {
        _db.execute('ROLLBACK');
      } catch (_) {}
      rethrow;
    }
  }

  /// Atomically write [json] only if the current state matches
  /// [expectedState].
  ///
  /// Runs inside `BEGIN IMMEDIATE` so no other connection can interleave
  /// between the check and the write.
  ///
  /// Returns [WriteIfOwnedResult.success] if written, or
  /// [WriteIfOwnedResult.rejected] with the current persisted JSON
  /// so the caller can sync its Cubit state.
  WriteIfOwnedResult writeIfOwned({
    required String namespace,
    required String id,
    required String expectedState,
    required Map<String, dynamic> json,
  }) {
    final pubkey = _currentPubkey();
    if (pubkey == null) return WriteIfOwnedResult.success;

    _db.execute('BEGIN IMMEDIATE');
    try {
      final rows = _db.select(
        'SELECT state, data FROM operations '
        'WHERE pubkey = ? AND namespace = ? AND id = ?',
        [pubkey, namespace, id],
      );

      if (rows.isEmpty) {
        // Entry doesn't exist — insert it.
        _db.execute(
          '''INSERT INTO operations
             (pubkey, namespace, id, state, is_terminal, updated_at, data)
             VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [
            pubkey,
            namespace,
            id,
            json['state'] as String?,
            json['isTerminal'] == true ? 1 : 0,
            json['updatedAt'] as String?,
            jsonEncode(json),
          ],
        );
        _db.execute('COMMIT');
        _onChanged.add(null);
        return WriteIfOwnedResult.success;
      }

      final currentState = rows.first['state'] as String?;
      if (currentState != null && currentState != expectedState) {
        final persistedJson = _tryDecode(rows.first['data'] as String);
        _db.execute('COMMIT');
        return WriteIfOwnedResult.rejected(persistedJson);
      }

      // State matches — update.
      _db.execute(
        '''UPDATE operations
           SET state = ?, is_terminal = ?, updated_at = ?, data = ?
           WHERE pubkey = ? AND namespace = ? AND id = ?''',
        [
          json['state'] as String?,
          json['isTerminal'] == true ? 1 : 0,
          json['updatedAt'] as String?,
          jsonEncode(json),
          pubkey,
          namespace,
          id,
        ],
      );
      _db.execute('COMMIT');
      _onChanged.add(null);
      return WriteIfOwnedResult.success;
    } catch (e) {
      try {
        _db.execute('ROLLBACK');
      } catch (_) {}
      rethrow;
    }
  }

  void dispose() => _onChanged.close();

  // ── Internal ────────────────────────────────────────────────────────

  String? _currentPubkey() => _auth.activeKeyPair?.publicKey;

  Map<String, dynamic>? _tryDecode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
