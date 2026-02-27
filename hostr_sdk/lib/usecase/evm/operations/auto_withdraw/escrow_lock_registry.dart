import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../datasources/storage.dart';
import '../../../../util/bitcoin_amount.dart';
import '../../../../util/custom_logger.dart';
import '../../../auth/auth.dart';
import 'escrow_lock.dart';

/// Persistent registry that tracks escrow operations currently using (or about
/// to use) the on-chain balance.
///
/// Follows the same persistence pattern as [SwapStore]: records are stored as a
/// JSON list under a single [KeyValueStorage] key, with an in-memory cache that
/// is lazily loaded on first access and flushed to disk after every mutation.
///
/// Persisted to disk so a background worker can read locks even when the
/// foreground app is not active.
@singleton
class EscrowLockRegistry {
  static const _storageKeyBase = 'escrow_locks';

  final KeyValueStorage _storage;
  final CustomLogger _logger;
  final Auth _auth;

  /// In-memory cache. Loaded lazily on first access via [initialize].
  Map<String, EscrowLock>? _cache;
  String? _loadedPubkey;

  /// Emits `true` whenever at least one lock is held, `false` otherwise.
  final BehaviorSubject<bool> _hasActiveLocksSubject = BehaviorSubject.seeded(
    false,
  );

  EscrowLockRegistry(this._storage, this._logger, this._auth);

  // ── Public API ──────────────────────────────────────────────────────────

  /// Load all lock records from disk. Idempotent.
  Future<void> initialize() async {
    final pubkey = _currentPubkey();
    if (_cache != null && _loadedPubkey == pubkey) return;

    _cache = {};
    _loadedPubkey = pubkey;

    if (pubkey == null) {
      _hasActiveLocksSubject.add(false);
      _logger.d('EscrowLockRegistry initialize skipped: no active pubkey');
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
            final lock = EscrowLock.fromJson(entry);
            _cache![lock.tradeId] = lock;
          } catch (e) {
            _logger.w('Skipping corrupt escrow lock record: $e');
          }
        }
      }
      _hasActiveLocksSubject.add(_cache!.isNotEmpty);
      _logger.i(
        'EscrowLockRegistry loaded ${_cache!.length} lock(s) for $pubkey',
      );
    } catch (e) {
      _logger.e('Failed to load escrow locks: $e');
      _cache = {};
    }
  }

  /// Acquire a lock for an escrow fund operation.
  ///
  /// All contract parameters are persisted so that a background worker can
  /// reconstruct a [ContractFundEscrowParams] and complete the deposit if the
  /// foreground app is killed after the swap-in but before the deposit tx.
  ///
  /// Returns the created [EscrowLock] handle. Call [release] with the same
  /// [tradeId] when the operation completes (success or failure).
  ///
  /// If a lock for [tradeId] already exists it is **replaced** (idempotent
  /// re-acquire).
  Future<EscrowLock> acquire({
    required String tradeId,
    required BitcoinAmount reservedAmount,
    required String sellerEvmAddress,
    required String arbiterEvmAddress,
    required String contractAddress,
    required int chainId,
    required int unlockAt,
  }) async {
    await initialize();
    final lock = EscrowLock(
      tradeId: tradeId,
      reservedAmountWei: reservedAmount.getInWei,
      acquiredAt: DateTime.now(),
      status: EscrowLockStatus.swapping,
      sellerEvmAddress: sellerEvmAddress,
      arbiterEvmAddress: arbiterEvmAddress,
      contractAddress: contractAddress,
      chainId: chainId,
      unlockAt: unlockAt,
    );
    _cache![tradeId] = lock;
    await _flush();
    _hasActiveLocksSubject.add(true);
    _logger.i(
      'EscrowLock acquired for $tradeId '
      '(reserved ${reservedAmount.getInSats} sats)',
    );
    return lock;
  }

  /// Transition a lock to a new [status], optionally recording a
  /// [depositTxHash].
  ///
  /// No-op if no lock exists for [tradeId].
  Future<void> updateStatus(
    String tradeId, {
    required EscrowLockStatus status,
    String? depositTxHash,
  }) async {
    await initialize();
    final existing = _cache![tradeId];
    if (existing == null) {
      _logger.w(
        'EscrowLockRegistry: cannot update status for unknown $tradeId',
      );
      return;
    }
    _cache![tradeId] = existing.copyWith(
      status: status,
      depositTxHash: depositTxHash,
    );
    await _flush();
    _logger.d(
      'EscrowLock $tradeId status → ${status.name}'
      '${depositTxHash != null ? ' (tx: $depositTxHash)' : ''}',
    );
  }

  /// Returns all locks whose status indicates the deposit can be resumed.
  Future<List<EscrowLock>> getResumable() async {
    await initialize();
    return _cache!.values.where((l) => l.canResumeDeposit).toList();
  }

  /// Release a previously acquired lock.
  ///
  /// No-op if no lock exists for [tradeId] (safe to call in `finally` blocks).
  Future<void> release(String tradeId) async {
    await initialize();
    final removed = _cache!.remove(tradeId);
    if (removed == null) {
      _logger.d('EscrowLockRegistry: no lock to release for $tradeId');
      return;
    }
    await _flush();
    _hasActiveLocksSubject.add(_cache!.isNotEmpty);
    _logger.i('EscrowLock released for $tradeId');
  }

  /// Whether any escrow operations currently hold a lock.
  Future<bool> get hasActiveLocks async {
    await initialize();
    return _cache!.isNotEmpty;
  }

  /// Total amount currently reserved across all active locks.
  Future<BitcoinAmount> get totalReservedAmount async {
    await initialize();
    if (_cache!.isEmpty) return BitcoinAmount.zero();
    final total = _cache!.values.fold<BigInt>(
      BigInt.zero,
      (sum, lock) => sum + lock.reservedAmountWei,
    );
    return BitcoinAmount.inWei(total);
  }

  /// Stream that fires whenever the lock set changes.
  /// Emits `true` when at least one lock is held, `false` otherwise.
  Stream<bool> get hasActiveLocksStream => _hasActiveLocksSubject.stream;

  /// All currently held lock trade IDs (for debugging / logging).
  Future<Set<String>> get activeTradeIds async {
    await initialize();
    return _cache!.keys.toSet();
  }

  /// Get all currently held locks.
  Future<List<EscrowLock>> getAll() async {
    await initialize();
    return _cache!.values.toList();
  }

  /// Get a single lock by trade ID, or `null` if none exists.
  Future<EscrowLock?> get(String tradeId) async {
    await initialize();
    return _cache![tradeId];
  }

  /// Remove all locks older than [age]. Useful for cleaning up stale locks
  /// left behind by crashes.
  Future<int> pruneOlderThan(Duration age) async {
    await initialize();
    final cutoff = DateTime.now().subtract(age);
    final stale = _cache!.values
        .where((lock) => lock.acquiredAt.isBefore(cutoff))
        .map((lock) => lock.tradeId)
        .toList();
    for (final id in stale) {
      _cache!.remove(id);
    }
    if (stale.isNotEmpty) {
      await _flush();
      _hasActiveLocksSubject.add(_cache!.isNotEmpty);
      _logger.w('Pruned ${stale.length} stale escrow lock(s)');
    }
    return stale.length;
  }

  /// Dispose resources. Call when the service is being torn down.
  void dispose() {
    _hasActiveLocksSubject.close();
  }

  // ── Internal ────────────────────────────────────────────────────────────

  Future<void> _flush() async {
    if (_loadedPubkey == null) {
      _logger.w('EscrowLockRegistry: skip flush because no active pubkey');
      return;
    }
    final list = _cache!.values.map((l) => l.toJson()).toList();
    await _storage.write(_storageKeyFor(_loadedPubkey!), jsonEncode(list));
  }

  String? _currentPubkey() => _auth.activeKeyPair?.publicKey;

  String _storageKeyFor(String pubkey) => '$_storageKeyBase:$pubkey';
}
