import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart' as bip;

import '../../util/custom_logger.dart';
import '../auth/auth.dart';
import '../deterministic_keys/deterministic_keys.dart';

/// A single cached trade-account entry mapping an HD account index to its
/// deterministic identifiers.
///
/// Entries can be **partial** (only [tradeId] populated) or **full** (all
/// fields populated).  Partial entries are created during lightweight scans
/// that only need tradeId lookups, and are promoted to full entries lazily
/// when salt / evmAddress are needed.
class TradeAccountEntry {
  final int accountIndex;
  final String tradeId;
  final String? salt;
  final String? evmAddress;

  const TradeAccountEntry({
    required this.accountIndex,
    required this.tradeId,
    this.salt,
    this.evmAddress,
  });

  /// Whether this entry has all fields populated.
  bool get isFull => salt != null && evmAddress != null;
}

/// Pure in-memory indexed cache for trade account derivations.
///
/// ## Problem
///
/// [TradeAccountAllocator] derives `(tradeId, salt, evmAddress)` from each
/// HD account index via cryptographic operations. Look-ups by `tradeId` or
/// `salt` previously required an O(N) linear scan — re-deriving keys for
/// every index from 0 to `maxAccountIndex` until a match was found.
///
/// ## Solution
///
/// On first access per pubkey, this cache eagerly derives **tradeIds only**
/// for indices `0..maxAccountIndex` (cheap — one HMAC-SHA256 per index).
/// Salt and evmAddress are derived lazily on demand via [ensureFullEntry]
/// or [put].  Indexed maps provide O(1) lookups by tradeId, salt, or
/// evmAddress.
///
/// The cache lives only in memory — derivation is deterministic from the
/// HD master key so it can always be rebuilt cheaply on app restart.
/// When a new trade index is reserved, [put] derives and indexes a single
/// new entry.
@singleton
class TradeAccountCache {
  final Auth _auth;
  final DeterministicKeys _hd;
  final CustomLogger _logger;

  /// Pubkey for which the in-memory cache is currently loaded.
  String? _loadedPubkey;

  /// Whether all entries have been fully promoted (salt + evmAddress).
  bool _fullyLoaded = false;

  // ── In-memory indices ───────────────────────────────────────────────

  /// accountIndex → entry
  final Map<int, TradeAccountEntry> _byIndex = {};

  /// tradeId → accountIndex
  final Map<String, int> _byTradeId = {};

  /// salt → accountIndex  (only populated for full entries)
  final Map<String, int> _bySalt = {};

  /// evmAddress (lowercase) → accountIndex  (only populated for full entries)
  final Map<String, int> _byEvmAddress = {};

  TradeAccountCache({
    required Auth auth,
    required DeterministicKeys hd,
    required CustomLogger logger,
  }) : _auth = auth,
       _hd = hd,
       _logger = logger.scope('trade-account-cache');

  // ══════════════════════════════════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════════════════════════════════

  /// Ensure the cache has **tradeIds** for all indices
  /// `0..storedMaxAccountIndex`.
  ///
  /// This is the lightweight initial load — only one derivation per index.
  /// Salt and evmAddress are NOT derived here; use [ensureLoaded] or
  /// [ensureFullEntry] for that.
  Future<void> ensureTradeIdsLoaded() async {
    final pubkey = _currentPubkey();
    if (pubkey == null) return;
    if (_loadedPubkey == pubkey) return;

    _clear();
    _loadedPubkey = pubkey;

    final maxAccountIndex = _auth.storedMaxAccountIndex;
    if (maxAccountIndex < 0) return;

    _logger.d('Deriving ${maxAccountIndex + 1} tradeIds');
    for (var i = 0; i <= maxAccountIndex; i++) {
      if (_byIndex.containsKey(i)) continue;
      final tradeId = await _hd.getTradeId(accountIndex: i);
      _indexPartialEntry(TradeAccountEntry(accountIndex: i, tradeId: tradeId));
    }
    _logger.d('TradeId cache ready: ${_byIndex.length} entries');
  }

  /// Ensure the cache is **fully** populated (tradeId + salt + evmAddress)
  /// for all indices `0..storedMaxAccountIndex`.
  ///
  /// Calls [ensureTradeIdsLoaded] first, then backfills salt and evmAddress
  /// for any partial entries.
  Future<void> ensureLoaded() async {
    await ensureTradeIdsLoaded();
    if (_fullyLoaded) return;

    final partial = _byIndex.values.where((e) => !e.isFull).toList();
    if (partial.isNotEmpty) {
      _logger.d('Backfilling ${partial.length} entries with salt + evmAddress');
      for (final entry in partial) {
        await _promoteEntry(entry.accountIndex);
      }
    }
    _fullyLoaded = true;
  }

  /// Look up an account index by trade ID. Returns `null` on miss.
  int? indexByTradeId(String tradeId) => _byTradeId[tradeId];

  /// Look up an account index by salt. Returns `null` on miss.
  ///
  /// Only finds entries that have been fully derived (via [ensureLoaded],
  /// [put], or [ensureFullEntry]).
  int? indexBySalt(String salt) => _bySalt[salt];

  /// Look up an account index by EVM address. Returns `null` on miss.
  ///
  /// Only finds entries that have been fully derived.
  int? indexByEvmAddress(bip.EthereumAddress address) =>
      _byEvmAddress[address.eip55With0x.toLowerCase()];

  /// Get the cached entry for an account index. Returns `null` on miss.
  TradeAccountEntry? entryAt(int accountIndex) => _byIndex[accountIndex];

  /// All cached entries (read-only).
  Iterable<TradeAccountEntry> get entries => _byIndex.values;

  /// Number of cached entries.
  int get length => _byIndex.length;

  /// Whether [accountIndex] is already in the cache (partial or full).
  bool containsIndex(int accountIndex) => _byIndex.containsKey(accountIndex);

  /// Insert a **partial** entry (tradeId only) into the cache.
  ///
  /// Use this during lightweight scans that only need tradeId matching.
  /// The entry can be promoted to full later via [ensureFullEntry] or [put].
  void putTradeIdOnly(int accountIndex, String tradeId) {
    if (_byIndex.containsKey(accountIndex)) return; // already cached
    _indexPartialEntry(
      TradeAccountEntry(accountIndex: accountIndex, tradeId: tradeId),
    );
  }

  /// Ensure the entry at [accountIndex] is fully populated.
  ///
  /// If the entry is partial, derives salt + evmAddress and promotes it.
  /// If absent, derives everything from scratch.
  /// Returns the full entry.
  Future<TradeAccountEntry> ensureFullEntry(int accountIndex) async {
    final existing = _byIndex[accountIndex];
    if (existing != null && existing.isFull) return existing;
    return _promoteEntry(accountIndex);
  }

  /// Derive and index a **full** entry for [accountIndex].
  ///
  /// Called by [TradeAccountAllocatorImpl.reserveNextTradeIndex] after
  /// choosing an index, so the cache stays in sync without a full reload.
  Future<TradeAccountEntry> put(int accountIndex) async {
    return _promoteEntry(accountIndex);
  }

  /// Clear the in-memory cache. Useful on logout.
  void clear() => _clear();

  // ══════════════════════════════════════════════════════════════════════
  // Private helpers
  // ══════════════════════════════════════════════════════════════════════

  String? _currentPubkey() => _auth.activeKeyPair?.publicKey;

  void _clear() {
    _byIndex.clear();
    _byTradeId.clear();
    _bySalt.clear();
    _byEvmAddress.clear();
    _loadedPubkey = null;
    _fullyLoaded = false;
  }

  /// Index a partial entry (tradeId only).
  void _indexPartialEntry(TradeAccountEntry entry) {
    _byIndex[entry.accountIndex] = entry;
    _byTradeId[entry.tradeId] = entry.accountIndex;
  }

  /// Index a full entry (all fields).
  void _indexFullEntry(TradeAccountEntry entry) {
    _byIndex[entry.accountIndex] = entry;
    _byTradeId[entry.tradeId] = entry.accountIndex;
    if (entry.salt != null) _bySalt[entry.salt!] = entry.accountIndex;
    if (entry.evmAddress != null) {
      _byEvmAddress[entry.evmAddress!.toLowerCase()] = entry.accountIndex;
    }
  }

  /// Promote a partial (or absent) entry to a full entry by deriving
  /// any missing fields.
  Future<TradeAccountEntry> _promoteEntry(int accountIndex) async {
    final existing = _byIndex[accountIndex];
    final tradeId =
        existing?.tradeId ?? await _hd.getTradeId(accountIndex: accountIndex);
    final salt =
        existing?.salt ?? await _hd.getTradeSalt(accountIndex: accountIndex);
    final evmAddress =
        existing?.evmAddress ??
        (await _hd.getEvmAddress(accountIndex: accountIndex)).eip55With0x;

    final entry = TradeAccountEntry(
      accountIndex: accountIndex,
      tradeId: tradeId,
      salt: salt,
      evmAddress: evmAddress,
    );
    _indexFullEntry(entry);
    return entry;
  }
}
