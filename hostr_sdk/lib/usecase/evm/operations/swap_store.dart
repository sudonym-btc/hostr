import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../datasources/storage.dart';
import '../../../util/custom_logger.dart';
import '../../auth/auth.dart';
import 'swap_record.dart';

/// Persistent store for [SwapRecord]s.
///
/// Swap records are the lifeline for recovering from mid-swap crashes.
/// This store writes **synchronously** to the underlying [KeyValueStorage]
/// after every mutation to minimise the window during which data could be lost.
///
/// Records are keyed by their Boltz swap ID and stored as a JSON list under
/// a single storage key, namespaced per EVM address to support multiple wallets.
@singleton
class SwapStore {
  static const _storageKeyBase = 'pending_swaps';

  final KeyValueStorage _storage;
  final CustomLogger _logger;
  final Auth _auth;

  /// In-memory cache. Loaded lazily on first access.
  Map<String, SwapRecord>? _cache;
  String? _loadedPubkey;

  SwapStore(this._storage, this._logger, this._auth);

  // ── Public API ──────────────────────────────────────────────────────────

  /// Load all swap records from disk. Idempotent.
  Future<void> initialize() async {
    final pubkey = _currentPubkey();
    if (_cache != null && _loadedPubkey == pubkey) return;

    _cache = {};
    _loadedPubkey = pubkey;

    if (pubkey == null) {
      _logger.d('SwapStore initialize skipped: no active pubkey');
      return;
    }

    try {
      final raw = await _storage.read(_storageKeyFor(pubkey));
      if (raw == null) return;

      final String jsonStr = raw is String ? raw : raw.toString();
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;

      for (final entry in list) {
        if (entry is Map<String, dynamic>) {
          try {
            final record = SwapRecord.fromJson(entry);
            _cache![record.id] = record;
          } catch (e) {
            _logger.w('Skipping corrupt swap record: $e');
          }
        }
      }
      _logger.i(
        'SwapStore loaded ${_cache!.length} records for $pubkey '
        '(${_cache!.values.where((r) => r.needsRecovery).length} need recovery)',
      );
    } catch (e) {
      _logger.e('Failed to load swap records: $e');
      // Start fresh rather than crash — records for EVM swaps can be
      // recovered from contract event logs as a last resort.
      _cache = {};
    }
  }

  /// Persist or update a swap record. Writes to disk immediately.
  Future<void> save(SwapRecord record) async {
    await initialize();
    _cache![record.id] = record;
    await _flush();
    _logger.d('SwapStore saved ${record.id} (${record.status})');
  }

  /// Update a record's status and optional fields atomically.
  Future<SwapRecord?> updateStatus(
    String id,
    SwapRecordStatus newStatus, {
    String? resolutionTxHash,
    String? lastBoltzStatus,
    String? errorMessage,
    String? refundAddress,
    String? lockTxHash,
  }) async {
    await initialize();
    final existing = _cache![id];
    if (existing == null) {
      _logger.w('SwapStore: cannot update unknown record $id');
      return null;
    }
    final SwapRecord updated = switch (existing) {
      SwapInRecord r => r.copyWithStatus(
        newStatus,
        resolutionTxHash: resolutionTxHash,
        lastBoltzStatus: lastBoltzStatus,
        errorMessage: errorMessage,
        refundAddress: refundAddress,
      ),
      SwapOutRecord r => r.copyWithStatus(
        newStatus,
        resolutionTxHash: resolutionTxHash,
        lastBoltzStatus: lastBoltzStatus,
        errorMessage: errorMessage,
        lockTxHash: lockTxHash,
      ),
    };
    _cache![id] = updated;
    await _flush();
    _logger.d('SwapStore updated $id → $newStatus');
    return updated;
  }

  /// Get a single record by Boltz swap ID.
  Future<SwapRecord?> get(String id) async {
    await initialize();
    return _cache![id];
  }

  /// Get all records.
  Future<List<SwapRecord>> getAll() async {
    await initialize();
    return _cache!.values.toList();
  }

  /// Get all records that need recovery action (non-terminal, funds at risk).
  Future<List<SwapRecord>> getPendingRecovery() async {
    await initialize();
    return _cache!.values.where((r) => r.needsRecovery).toList();
  }

  /// Get all non-terminal records.
  Future<List<SwapRecord>> getActive() async {
    await initialize();
    return _cache!.values.where((r) => !r.isTerminal).toList();
  }

  /// Remove a record (only for completed/refunded cleanup).
  Future<void> remove(String id) async {
    await initialize();
    _cache!.remove(id);
    await _flush();
  }

  /// Remove all terminal records older than [age].
  Future<int> pruneOlderThan(Duration age) async {
    await initialize();
    final cutoff = DateTime.now().subtract(age);
    final toRemove = _cache!.values
        .where((r) => r.isTerminal && r.updatedAt.isBefore(cutoff))
        .map((r) => r.id)
        .toList();
    for (final id in toRemove) {
      _cache!.remove(id);
    }
    if (toRemove.isNotEmpty) await _flush();
    return toRemove.length;
  }

  // ── Internal ────────────────────────────────────────────────────────────

  Future<void> _flush() async {
    if (_loadedPubkey == null) {
      _logger.w('SwapStore: skip flush because no active pubkey');
      return;
    }
    final list = _cache!.values.map((r) => r.toJson()).toList();
    await _storage.write(_storageKeyFor(_loadedPubkey!), jsonEncode(list));
  }

  String? _currentPubkey() => _auth.activeKeyPair?.publicKey;

  String _storageKeyFor(String pubkey) => '$_storageKeyBase:$pubkey';
}
