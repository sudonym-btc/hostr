import 'dart:async';

import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../util/custom_logger.dart';
import '../../../util/stream_status.dart';
import 'evm_balance_types.dart';
import 'evm_chain.dart';
import 'rpc_batch_builder.dart';

/// ERC-20 Transfer event topic0: keccak256("Transfer(address,address,uint256)")
const _transferEventTopic =
    '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

/// Monitors native and ERC-20 balances for a dynamic set of addresses on
/// a single [EvmChain].
///
/// ## Design
///
/// - **Native balances**: polled per block for tracked addresses only.
///   On each (coalesced) block tick, inspects the block's transactions
///   to determine which tracked addresses are "dirty", then re-fetches
///   only those. Falls back to a full refresh for the first tick or when
///   the block-fetch fails.
///
/// - **ERC-20 balances**: event-driven via `Transfer` logs. An initial
///   `balanceOf` snapshot is taken when an address or token is first
///   tracked. Subsequent updates come from scanning `Transfer` logs
///   over the block range since the last scan; only addresses that
///   appear in matching logs ("dirty pairs") get a `balanceOf` refresh.
///
/// - **Block coalescing**: on fast chains (e.g. Arbitrum, ~1s blocks),
///   block ticks are debounced so that multiple blocks are processed in
///   a single pass.
///
/// - **Dynamic expansion**: [trackAddress] and [trackToken] can be called
///   at any time. New entries trigger an immediate snapshot (debounced if
///   many arrive at once) and are included in subsequent block ticks.
///
/// - **Untracking**: [untrackAddress] removes an address from monitoring.
///   Its cached balances are evicted and no further updates are emitted.
///
/// ## Output
///
/// All balance updates flow through [balanceUpdates], a [StreamWithStatus]
/// that transitions:
///
///   `Idle → Querying (initial snapshot) → Live (block-driven updates)`
///
/// Consumers can use [balanceOf] to read the latest cached value for any
/// tracked (address, token) pair, or [totalBalance] for a cross-address sum.
class EvmBalanceMonitor {
  final EvmChain _chain;
  final CustomLogger _logger;

  /// Debounce duration for block coalescing.
  ///
  /// On Arbitrum (~1s blocks) this should be ~2–3s. On Rootstock (30s
  /// blocks) or Anvil (manual mining) this can be 0.
  final Duration blockCoalesceDuration;

  /// Debounce duration for batching rapid [trackAddress]/[trackToken] calls.
  final Duration expansionDebounceDuration;

  /// Maximum number of addresses per RPC batch (getBalance / balanceOf).
  final int batchChunkSize;

  // ── Tracked sets ────────────────────────────────────────────────────

  final Set<TrackedAddress> _trackedAddresses = {};
  final Set<Token> _trackedTokens = {};

  // ── Caches ──────────────────────────────────────────────────────────

  /// (addressLower, tokenAddressLower) → latest balance.
  final Map<(String, String), TokenAmount> _balanceCache = {};

  /// Last fully-processed block number (for log range continuity).
  int? _lastProcessedBlock;

  // ── Output stream ───────────────────────────────────────────────────

  final StreamWithStatus<BalanceUpdate> _updates = StreamWithStatus();

  /// All balance updates (native + ERC-20) as a [StreamWithStatus].
  ///
  /// Status lifecycle:
  /// - [StreamStatusIdle] — nothing tracked yet.
  /// - [StreamStatusQuerying] — initial snapshot in progress.
  /// - [StreamStatusLive] — block-driven updates flowing.
  StreamWithStatus<BalanceUpdate> get balanceUpdates => _updates;

  // ── Block subscription ──────────────────────────────────────────────

  StreamSubscription<int>? _blockSub;
  Timer? _coalesceTimer;
  int? _coalesceFirst;
  int? _coalesceLast;

  // ── Expansion debounce ──────────────────────────────────────────────

  Timer? _expansionTimer;
  final Set<TrackedAddress> _pendingAddresses = {};
  final Set<Token> _pendingTokens = {};

  // ── Processing lock ─────────────────────────────────────────────────

  bool _processing = false;
  bool _disposed = false;

  EvmBalanceMonitor({
    required EvmChain chain,
    required CustomLogger logger,
    this.blockCoalesceDuration = const Duration(seconds: 2),
    this.expansionDebounceDuration = const Duration(milliseconds: 100),
    this.batchChunkSize = 10,
  }) : _chain = chain,
       _logger = logger.scope('balance-monitor');

  // ══════════════════════════════════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════════════════════════════════

  /// Begin tracking [address].
  ///
  /// An initial balance snapshot is queued (debounced). The address will be
  /// included in subsequent block-driven scans.
  void trackAddress(EthereumAddress address, {String? reason}) {
    final tracked = TrackedAddress(address: address, reason: reason);
    if (!_trackedAddresses.add(tracked)) return; // already tracked

    _logger.d('trackAddress(${address.eip55With0x}, reason=$reason)');
    _pendingAddresses.add(tracked);
    _scheduleExpansionFlush();
  }

  /// Begin tracking an ERC-20 [token].
  ///
  /// All currently-tracked addresses will get an initial `balanceOf` snapshot
  /// for this token (debounced), and subsequent block ticks will include
  /// Transfer log scanning for the token's contract.
  void trackToken(Token token) {
    if (!_trackedTokens.add(token)) return; // already tracked

    _logger.d('trackToken(${token.tagId})');
    _pendingTokens.add(token);
    _scheduleExpansionFlush();
  }

  /// Stop tracking [address].
  ///
  /// Cached balances are evicted. No further updates are emitted for it.
  void untrackAddress(EthereumAddress address) {
    final tracked = TrackedAddress(address: address);
    if (!_trackedAddresses.remove(tracked)) return;

    _logger.d('untrackAddress(${address.eip55With0x})');
    _pendingAddresses.remove(tracked);

    // Evict all cached balances for this address.
    final addrLower = address.eip55With0x.toLowerCase();
    _balanceCache.removeWhere((key, _) => key.$1 == addrLower);
  }

  /// Stop tracking an ERC-20 [token].
  ///
  /// Cached balances are evicted for all addresses × this token.
  void untrackToken(Token token) {
    if (!_trackedTokens.remove(token)) return;

    _logger.d('untrackToken(${token.address})');
    _pendingTokens.remove(token);

    final tokenLower = token.address.toLowerCase();
    _balanceCache.removeWhere((key, _) => key.$2 == tokenLower);
  }

  /// Read the latest cached balance for an (address, token) pair.
  ///
  /// Returns `null` if the pair hasn't been fetched yet or isn't tracked.
  /// For native balance, pass [Token.native] (or the chain's native token).
  TokenAmount? balanceOf(EthereumAddress address, Token token) {
    final key = (
      address.eip55With0x.toLowerCase(),
      token.address.toLowerCase(),
    );
    return _balanceCache[key];
  }

  /// The current set of tracked addresses (read-only copy).
  Set<TrackedAddress> get trackedAddresses =>
      Set.unmodifiable(_trackedAddresses);

  /// The current set of tracked tokens (read-only copy).
  Set<Token> get trackedTokens => Set.unmodifiable(_trackedTokens);

  /// Whether the monitor is actively processing blocks.
  bool get isRunning => _blockSub != null;

  /// Start the monitor.
  ///
  /// Subscribes to [EvmChain.newBlocks] and begins processing. Idempotent.
  void start() {
    if (_blockSub != null || _disposed) return;

    _logger.i('Starting EvmBalanceMonitor');
    _blockSub = _chain.newBlocks().listen(
      _onNewBlock,
      onError: (Object e) => _logger.w('Block stream error: $e'),
    );
  }

  /// Stop the monitor. Can be restarted with [start].
  Future<void> stop() async {
    _logger.i('Stopping EvmBalanceMonitor');
    await _blockSub?.cancel();
    _blockSub = null;
    _coalesceTimer?.cancel();
    _coalesceTimer = null;
    _coalesceFirst = null;
    _coalesceLast = null;
    _expansionTimer?.cancel();
    _expansionTimer = null;
    _updates.addStatus(StreamStatusIdle());
  }

  /// Permanently dispose of the monitor. Cannot be restarted.
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    _updates.close();
    _balanceCache.clear();
    _trackedAddresses.clear();
    _trackedTokens.clear();
    _logger.d('EvmBalanceMonitor disposed');
  }

  // ══════════════════════════════════════════════════════════════════════
  // Expansion (dynamic track/untrack) — debounced
  // ══════════════════════════════════════════════════════════════════════

  void _scheduleExpansionFlush() {
    _expansionTimer?.cancel();
    _expansionTimer = Timer(expansionDebounceDuration, _flushExpansion);
  }

  Future<void> _flushExpansion() => _logger.span('_flushExpansion', () async {
    if (_disposed) return;

    final newAddresses = Set<TrackedAddress>.of(_pendingAddresses);
    final newTokens = Set<Token>.of(_pendingTokens);
    _pendingAddresses.clear();
    _pendingTokens.clear();

    if (newAddresses.isEmpty && newTokens.isEmpty) return;

    _updates.addStatus(StreamStatusQuerying());

    try {
      final blockNumber = await _chain.getBlockNumber();

      // ── Build one combined batch: native + ERC-20 ─────────────────
      final batch = RpcBatch();

      // Native balance requests for new addresses.
      final nativeAddrs = newAddresses.map((a) => a.address).toList();
      final BatchResult<Map<EthereumAddress, TokenAmount>>? nativeResult =
          nativeAddrs.isNotEmpty
          ? batch.getBalances(nativeAddrs, chainId: _chain.config.chainId)
          : null;

      // ERC-20 pair collection.
      final addressesToSnapshot = <EthereumAddress>{
        ...newAddresses.map((a) => a.address),
      };
      final tokensToSnapshot = <Token>{..._trackedTokens};
      if (newTokens.isNotEmpty) {
        for (final existing in _trackedAddresses) {
          addressesToSnapshot.add(existing.address);
        }
      }

      final erc20Pairs =
          <({EthereumAddress owner, EthereumAddress token, Token meta})>[];
      for (final addr in addressesToSnapshot) {
        for (final token in tokensToSnapshot) {
          final key = (
            addr.eip55With0x.toLowerCase(),
            token.address.toLowerCase(),
          );
          if (_balanceCache.containsKey(key) &&
              !newAddresses.any(
                (a) =>
                    a.address.eip55With0x.toLowerCase() ==
                    addr.eip55With0x.toLowerCase(),
              ) &&
              !newTokens.contains(token)) {
            continue;
          }
          erc20Pairs.add((
            owner: addr,
            token: EthereumAddress.fromHex(token.address),
            meta: token,
          ));
        }
      }

      final batchPairs = erc20Pairs
          .map((p) => (owner: p.owner, token: p.token))
          .toList(growable: false);
      final BatchResult<List<TokenAmount?>>? erc20Result = batchPairs.isNotEmpty
          ? batch.getERC20Balances(
              batchPairs,
              tokenResolver: _chain.resolveToken,
            )
          : null;

      // ── Single HTTP round-trip ────────────────────────────────────
      if (!batch.isEmpty) {
        await _chain.executeBatch(batch);

        // Apply native balances.
        if (nativeResult != null) {
          for (final entry in nativeResult.value.entries) {
            _emitNativeBalance(entry.key, entry.value, blockNumber);
          }
        }

        // Apply ERC-20 balances.
        if (erc20Result != null) {
          for (var i = 0; i < erc20Pairs.length; i++) {
            final balance = erc20Result.value[i];
            if (balance == null) continue;
            _emitErc20Balance(
              erc20Pairs[i].owner,
              erc20Pairs[i].meta,
              balance,
              blockNumber,
            );
          }
        }
      }

      _lastProcessedBlock ??= blockNumber;

      if (_blockSub != null) {
        _updates.addStatus(StreamStatusLive());
      }
    } catch (e, st) {
      _logger.w('Expansion snapshot failed: $e');
      _updates.addStatus(StreamStatusError(e, st));
    }
  });

  // ══════════════════════════════════════════════════════════════════════
  // Block coalescing
  // ══════════════════════════════════════════════════════════════════════

  void _onNewBlock(int blockNumber) {
    _coalesceFirst ??= blockNumber;
    _coalesceLast = blockNumber;

    if (blockCoalesceDuration == Duration.zero) {
      _flushCoalescedBlocks();
      return;
    }

    _coalesceTimer?.cancel();
    _coalesceTimer = Timer(blockCoalesceDuration, _flushCoalescedBlocks);
  }

  void _flushCoalescedBlocks() {
    final from = _coalesceFirst;
    final to = _coalesceLast;
    _coalesceFirst = null;
    _coalesceLast = null;
    _coalesceTimer?.cancel();

    if (from == null || to == null) return;
    if (_trackedAddresses.isEmpty) return;

    _processBlockRange(from, to);
  }

  // ══════════════════════════════════════════════════════════════════════
  // Per-block-range processing
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _processBlockRange(int from, int to) async {
    if (_processing || _disposed) return;
    _processing = true;

    try {
      await _logger.span('processBlockRange($from..$to)', () async {
        // ── 1. Native balances: inspect block transactions for dirty addrs ──
        await _refreshNativeBalances(to);

        // ── 2. ERC-20 balances: scan Transfer logs for dirty pairs ──────────
        await _refreshErc20Balances(from, to);

        _lastProcessedBlock = to;
      });
    } catch (e) {
      _logger.w('Block range processing failed ($from..$to): $e');
    } finally {
      _processing = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Native balance refresh
  // ══════════════════════════════════════════════════════════════════════

  /// Determine which tracked addresses are "dirty" by inspecting the latest
  /// block's transactions, then re-fetch only those balances.
  ///
  /// If fetching the block fails, falls back to refreshing all tracked
  /// addresses (safe but more expensive).
  Future<void> _refreshNativeBalances(int blockNumber) =>
      _logger.span('_refreshNativeBalances', () async {
        if (_trackedAddresses.isEmpty) return;

        final trackedLower = {
          for (final a in _trackedAddresses)
            a.address.eip55With0x.toLowerCase(): a.address,
        };

        Set<EthereumAddress> dirty;

        try {
          // Fetch block with full transactions to inspect from/to.
          final block = await _chain.client.makeRPCCall<Map<String, dynamic>>(
            'eth_getBlockByNumber',
            ['0x${blockNumber.toRadixString(16)}', true],
          );

          final txs = (block['transactions'] as List<dynamic>?) ?? [];

          dirty = {};
          for (final tx in txs) {
            if (tx is! Map<String, dynamic>) continue;
            final txFrom = (tx['from'] as String?)?.toLowerCase();
            final txTo = (tx['to'] as String?)?.toLowerCase();
            if (txFrom != null && trackedLower.containsKey(txFrom)) {
              dirty.add(trackedLower[txFrom]!);
            }
            if (txTo != null && trackedLower.containsKey(txTo)) {
              dirty.add(trackedLower[txTo]!);
            }
          }
        } catch (e) {
          _logger.w(
            'Failed to inspect block $blockNumber txs, '
            'falling back to full refresh: $e',
          );
          dirty = trackedLower.values.toSet();
        }

        if (dirty.isEmpty) return;

        _logger.d(
          'Native dirty addresses: ${dirty.length}/${_trackedAddresses.length}',
        );

        // Fetch balances in batched RPC chunks.
        for (final chunk in _chunked(dirty.toList(), batchChunkSize)) {
          final balances = await _chain.getBalancesBatch(chunk);
          for (final entry in balances.entries) {
            _emitNativeBalance(entry.key, entry.value, blockNumber);
          }
        }
      });

  // ══════════════════════════════════════════════════════════════════════
  // ERC-20 balance refresh via Transfer logs
  // ══════════════════════════════════════════════════════════════════════

  /// Scan Transfer logs over [from]..[to] for tracked token contracts.
  /// Any tracked address that appears as `from` or `to` in a Transfer
  /// event is marked dirty, and its `balanceOf` is re-fetched.
  Future<void> _refreshErc20Balances(int from, int to) => _logger.span(
    '_refreshErc20Balances',
    () async {
      if (_trackedTokens.isEmpty || _trackedAddresses.isEmpty) return;

      // Determine the log scan range. If this is our first tick and we
      // already have a _lastProcessedBlock (from expansion), scan only
      // the new range. If we're behind, scan from _lastProcessedBlock+1.
      final scanFrom = (_lastProcessedBlock != null)
          ? _lastProcessedBlock! + 1
          : from;

      if (scanFrom > to) return; // nothing new

      // Build padded address list for topic matching.
      final trackedAddrPadded = <String, EthereumAddress>{};
      for (final a in _trackedAddresses) {
        final padded = _padAddress(a.address);
        trackedAddrPadded[padded] = a.address;
      }

      final tokenContracts = _trackedTokens
          .map((t) => EthereumAddress.fromHex(t.address))
          .toList(growable: false);

      final dirtyPairs = <(EthereumAddress, Token)>{};

      // We need two log queries per range:
      // 1. topics[1] (from) matches tracked addresses
      // 2. topics[2] (to) matches tracked addresses
      //
      // We use the existing getLogs batching infrastructure.
      final paddedList = trackedAddrPadded.keys.toList(growable: false);

      for (final topicIndex in [1, 2]) {
        try {
          final topics = <List<String?>>[];
          topics.add([_transferEventTopic]); // topic0: Transfer signature
          if (topicIndex == 1) {
            topics.add(paddedList); // topic1: from
            topics.add([]); // topic2: any
          } else {
            topics.add([]); // topic1: any
            topics.add(paddedList); // topic2: to
          }

          for (final tokenContract in tokenContracts) {
            final filter = FilterOptions(
              address: tokenContract,
              topics: topics,
              fromBlock: BlockNum.exact(scanFrom),
              toBlock: BlockNum.exact(to),
            );

            final logs = await _chain.getLogs(
              filter,
              batch: true,
              batchHint: EvmLogsBatchHint(
                requestKey: 'balance-monitor-transfer-t$topicIndex',
                dynamicTopicIndex: topicIndex,
              ),
            );

            // Identify dirty addresses from the logs.
            final token = _trackedTokens.firstWhere(
              (t) =>
                  t.address.toLowerCase() ==
                  tokenContract.eip55With0x.toLowerCase(),
            );

            for (final log in logs) {
              final logTopics = log.topics;
              if (logTopics == null || logTopics.length < 3) continue;

              // Check both from (topic1) and to (topic2) against tracked.
              final fromAddr = trackedAddrPadded[logTopics[1]];
              final toAddr = trackedAddrPadded[logTopics[2]];

              if (fromAddr != null) {
                dirtyPairs.add((fromAddr, token));
              }
              if (toAddr != null) {
                dirtyPairs.add((toAddr, token));
              }
            }
          }
        } catch (e) {
          _logger.w('ERC20 log scan failed (topicIndex=$topicIndex): $e');
          // On failure, mark ALL pairs as dirty for safety.
          for (final addr in _trackedAddresses) {
            for (final token in _trackedTokens) {
              dirtyPairs.add((addr.address, token));
            }
          }
        }
      }

      if (dirtyPairs.isEmpty) return;

      _logger.d(
        'ERC20 dirty pairs: ${dirtyPairs.length} '
        '(${_trackedAddresses.length} addrs × ${_trackedTokens.length} tokens)',
      );

      // Fetch balanceOf for dirty pairs in batched-RPC chunks.
      final pairsList = dirtyPairs.toList();
      for (final chunk in _chunked(pairsList, batchChunkSize)) {
        final batchPairs = chunk
            .map(
              (p) =>
                  (owner: p.$1, token: EthereumAddress.fromHex(p.$2.address)),
            )
            .toList(growable: false);
        final results = await _chain.getERC20BalancesBatch(batchPairs);
        for (var i = 0; i < chunk.length; i++) {
          final balance = results[i];
          if (balance == null) continue;
          _emitErc20Balance(chunk[i].$1, chunk[i].$2, balance, to);
        }
      }
    },
  );

  // ══════════════════════════════════════════════════════════════════════
  // Balance emit helpers (cache-update + stream, no RPC)
  // ══════════════════════════════════════════════════════════════════════

  /// Update the cache and emit a [BalanceUpdate] for a native balance
  /// that was already fetched (e.g. via [EvmChain.getBalancesBatch]).
  void _emitNativeBalance(
    EthereumAddress address,
    TokenAmount balance,
    int blockNumber,
  ) {
    final nativeToken = Token.native(_chain.config.chainId);
    final key = (
      address.eip55With0x.toLowerCase(),
      nativeToken.address.toLowerCase(),
    );
    final previous = _balanceCache[key];
    _balanceCache[key] = balance;

    if (previous == null || previous.value != balance.value) {
      _updates.add(
        BalanceUpdate(
          address: address,
          token: nativeToken,
          balance: balance,
          blockNumber: blockNumber,
        ),
      );
    }
  }

  /// Update the cache and emit a [BalanceUpdate] for an ERC-20 balance
  /// that was already fetched (e.g. via [EvmChain.getERC20BalancesBatch]).
  void _emitErc20Balance(
    EthereumAddress address,
    Token token,
    TokenAmount balance,
    int blockNumber,
  ) {
    final key = (
      address.eip55With0x.toLowerCase(),
      token.address.toLowerCase(),
    );
    final previous = _balanceCache[key];
    _balanceCache[key] = balance;

    if (previous == null || previous.value != balance.value) {
      _updates.add(
        BalanceUpdate(
          address: address,
          token: balance.token,
          balance: balance,
          blockNumber: blockNumber,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Utilities
  // ══════════════════════════════════════════════════════════════════════

  /// Pad an Ethereum address to 32-byte hex (as used in log topics).
  static String _padAddress(EthereumAddress address) {
    final hex = address.eip55With0x.toLowerCase().replaceFirst('0x', '');
    return '0x${hex.padLeft(64, '0')}';
  }

  /// Split a list into chunks of [size].
  static List<List<T>> _chunked<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = (i + size < list.length) ? i + size : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
}
