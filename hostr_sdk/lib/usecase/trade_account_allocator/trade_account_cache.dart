import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart' as bip;

import '../../util/custom_logger.dart';
import '../auth/auth.dart';
import '../deterministic_keys/deterministic_keys.dart';

/// A single cached trade-account entry mapping an HD account index to its
/// deterministic identifiers.
class TradeAccountEntry {
  final int accountIndex;
  final String tradeId;
  final String salt;
  final String evmAddress;

  const TradeAccountEntry({
    required this.accountIndex,
    required this.tradeId,
    required this.salt,
    required this.evmAddress,
  });
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
/// On first access per pubkey, this cache eagerly derives all entries for
/// indices `0..maxAccountIndex` and stores them in indexed maps for O(1)
/// lookups by tradeId, salt, or evmAddress.
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

  // ── In-memory indices ───────────────────────────────────────────────

  /// accountIndex → entry
  final Map<int, TradeAccountEntry> _byIndex = {};

  /// tradeId → accountIndex
  final Map<String, int> _byTradeId = {};

  /// salt → accountIndex
  final Map<String, int> _bySalt = {};

  /// evmAddress (lowercase) → accountIndex
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

  /// Ensure the cache is populated for the current user.
  ///
  /// Derives all entries for indices `0..storedMaxAccountIndex` on first
  /// call (or when the active pubkey changes). Subsequent calls for the
  /// same pubkey are no-ops.
  Future<void> ensureLoaded() async {
    final pubkey = _currentPubkey();
    if (pubkey == null) return;
    if (_loadedPubkey == pubkey) return;

    _clear();
    _loadedPubkey = pubkey;

    final maxAccountIndex = _auth.storedMaxAccountIndex;
    if (maxAccountIndex < 0) return;

    _logger.d('Deriving ${maxAccountIndex + 1} trade account entries');
    for (var i = 0; i <= maxAccountIndex; i++) {
      final entry = await _deriveEntry(i);
      _indexEntry(entry);
    }
    _logger.d('Cache ready: ${_byIndex.length} entries');
  }

  /// Look up an account index by trade ID. Returns `null` on miss.
  int? indexByTradeId(String tradeId) => _byTradeId[tradeId];

  /// Look up an account index by salt. Returns `null` on miss.
  int? indexBySalt(String salt) => _bySalt[salt];

  /// Look up an account index by EVM address. Returns `null` on miss.
  int? indexByEvmAddress(bip.EthereumAddress address) =>
      _byEvmAddress[address.eip55With0x.toLowerCase()];

  /// Get the cached entry for an account index. Returns `null` on miss.
  TradeAccountEntry? entryAt(int accountIndex) => _byIndex[accountIndex];

  /// All cached entries (read-only).
  Iterable<TradeAccountEntry> get entries => _byIndex.values;

  /// Number of cached entries.
  int get length => _byIndex.length;

  /// Whether [accountIndex] is already in the cache.
  bool containsIndex(int accountIndex) => _byIndex.containsKey(accountIndex);

  /// Derive and index a new entry for [accountIndex].
  ///
  /// Called by [TradeAccountAllocatorImpl.reserveNextTradeIndex] after
  /// choosing an index, so the cache stays in sync without a full reload.
  Future<TradeAccountEntry> put(int accountIndex) async {
    final entry = await _deriveEntry(accountIndex);
    _indexEntry(entry);
    return entry;
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
  }

  void _indexEntry(TradeAccountEntry entry) {
    _byIndex[entry.accountIndex] = entry;
    _byTradeId[entry.tradeId] = entry.accountIndex;
    _bySalt[entry.salt] = entry.accountIndex;
    _byEvmAddress[entry.evmAddress.toLowerCase()] = entry.accountIndex;
  }

  Future<TradeAccountEntry> _deriveEntry(int accountIndex) async {
    final tradeId = await _hd.getTradeId(accountIndex: accountIndex);
    final salt = await _hd.getTradeSalt(accountIndex: accountIndex);
    final evmAddress = await _hd.getEvmAddress(accountIndex: accountIndex);

    return TradeAccountEntry(
      accountIndex: accountIndex,
      tradeId: tradeId,
      salt: salt,
      evmAddress: evmAddress.eip55With0x,
    );
  }
}
