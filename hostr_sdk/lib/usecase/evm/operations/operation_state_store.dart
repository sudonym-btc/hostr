import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../datasources/storage.dart';
import '../../../util/custom_logger.dart';
import '../../auth/auth.dart';

/// Generic persistent store for serialisable cubit states.
///
/// Replaces the specialised `SwapStore` and `EscrowLockRegistry` with a single
/// namespace-based store. Each in-flight operation writes its JSON state on
/// every `Cubit.emit` and recovery services read those states on app start.
///
/// Storage key pattern: `ops:<pubkey>:<namespace>` → JSON list of objects.
/// Each object **must** contain an `'id'` key.
@singleton
class OperationStateStore {
  static const _storageKeyBase = 'ops';

  final KeyValueStorage _storage;
  final CustomLogger _logger;
  final Auth _auth;

  /// Per-namespace in-memory caches, lazily loaded.
  final Map<String, Map<String, Map<String, dynamic>>> _caches = {};
  String? _loadedPubkey;

  /// Fires on every mutation so listeners (e.g. AutoWithdrawService) can
  /// re-check their gates.
  final PublishSubject<void> _onChanged = PublishSubject();

  OperationStateStore(this._storage, this._logger, this._auth);

  // ── Public API ──────────────────────────────────────────────────────────

  /// Ensure the [namespace] cache is loaded from disk. Idempotent.
  Future<void> initialize(String namespace) async {
    final pubkey = _currentPubkey();
    if (_loadedPubkey != pubkey) {
      _caches.clear();
      _loadedPubkey = pubkey;
    }
    if (_caches.containsKey(namespace)) return;
    _caches[namespace] = {};
    if (pubkey == null) return;

    try {
      final raw = await _storage.read(_storageKeyFor(pubkey, namespace));
      if (raw == null) return;
      final String jsonStr = raw is String ? raw : raw.toString();
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      for (final entry in list) {
        if (entry is Map<String, dynamic>) {
          final id = entry['id'] as String?;
          if (id != null) _caches[namespace]![id] = entry;
        }
      }
      _logger.d(
        'OperationStateStore loaded ${_caches[namespace]!.length} '
        'entries for $namespace',
      );
    } catch (e) {
      _logger.e('OperationStateStore: failed to load $namespace: $e');
      _caches[namespace] = {};
    }
  }

  /// Write (upsert) a state. [json] **must** contain an `'id'` key.
  Future<void> write(
    String namespace,
    String id,
    Map<String, dynamic> json,
  ) async {
    await initialize(namespace);
    _caches[namespace]![id] = json;
    await _flush(namespace);
    _onChanged.add(null);
  }

  /// Read a single entry by [id].
  Future<Map<String, dynamic>?> read(String namespace, String id) async {
    await initialize(namespace);
    return _caches[namespace]?[id];
  }

  /// Read all entries for a [namespace].
  Future<List<Map<String, dynamic>>> readAll(String namespace) async {
    await initialize(namespace);
    return _caches[namespace]?.values.toList() ?? [];
  }

  /// Remove a single entry.
  Future<void> remove(String namespace, String id) async {
    await initialize(namespace);
    _caches[namespace]?.remove(id);
    await _flush(namespace);
    _onChanged.add(null);
  }

  /// Whether any entries in [namespace] have `'isTerminal'` != `true`.
  Future<bool> hasNonTerminal(String namespace) async {
    await initialize(namespace);
    final entries = _caches[namespace] ?? {};
    return entries.values.any((e) => e['isTerminal'] != true);
  }

  /// Fires whenever any write/remove occurs.
  Stream<void> get onChanged => _onChanged.stream;

  /// Remove terminal entries older than [age].
  Future<int> pruneTerminal(String namespace, Duration age) async {
    await initialize(namespace);
    final cutoff = DateTime.now().subtract(age);
    final cache = _caches[namespace] ?? {};
    final toRemove = <String>[];
    for (final entry in cache.entries) {
      if (entry.value['isTerminal'] == true) {
        final updatedAt = entry.value['updatedAt'] as String?;
        if (updatedAt != null) {
          final dt = DateTime.tryParse(updatedAt);
          if (dt != null && dt.isBefore(cutoff)) {
            toRemove.add(entry.key);
          }
        }
      }
    }
    for (final id in toRemove) {
      cache.remove(id);
    }
    if (toRemove.isNotEmpty) await _flush(namespace);
    return toRemove.length;
  }

  void dispose() => _onChanged.close();

  // ── Internal ────────────────────────────────────────────────────────────

  Future<void> _flush(String namespace) async {
    final pubkey = _loadedPubkey;
    if (pubkey == null) return;
    final list = _caches[namespace]?.values.toList() ?? [];
    await _storage.write(_storageKeyFor(pubkey, namespace), jsonEncode(list));
  }

  String? _currentPubkey() => _auth.activeKeyPair?.publicKey;

  String _storageKeyFor(String pubkey, String namespace) =>
      '$_storageKeyBase:$pubkey:$namespace';
}
