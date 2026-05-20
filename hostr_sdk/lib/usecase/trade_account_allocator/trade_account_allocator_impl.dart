import 'dart:async';

import 'package:injectable/injectable.dart' hide Order;
import 'package:wallet/wallet.dart' as bip;

import '../../util/main.dart';
import '../auth/auth.dart';
import '../deterministic_keys/deterministic_keys.dart';
import '../evm/evm.dart';
import '../messaging/threads.dart';
import '../orders/orders.dart';
import 'trade_account_allocator.dart';
import 'trade_account_cache.dart';

@Singleton(as: TradeAccountAllocator)
class TradeAccountAllocatorImpl implements TradeAccountAllocator {
  final Auth _auth;
  final DeterministicKeys _hd;
  final Evm _evm;
  final Orders _orders;
  final Threads _threads;
  final TradeAccountCache _cache;
  final CustomLogger _logger;

  TradeAccountAllocatorImpl({
    required Auth auth,
    required DeterministicKeys hd,
    required Evm evm,
    required Orders orders,
    required Threads threads,
    required TradeAccountCache cache,
    required CustomLogger logger,
  }) : _auth = auth,
       _hd = hd,
       _evm = evm,
       _orders = orders,
       _threads = threads,
       _cache = cache,
       _logger = logger.scope('trade_account_allocator');

  @override
  Future<int> reserveNextTradeIndex() =>
      _logger.span('reserveNextTradeIndex', () async {
        await _cache.ensureTradeIdsLoaded();
        await _waitForThreadHydration();

        // HD account 0 is the stable public/profile EVM address. Trade
        // allocations start at index 1 so the first booking cannot reveal the
        // user's public address.
        var accountIndex = _auth.storedMaxAccountIndex + 1;
        if (accountIndex < kFirstTradeAccountIndex) {
          accountIndex = kFirstTradeAccountIndex;
        }

        while (true) {
          // Derive (and cache) the full entry for this candidate index.
          final entry = await _cache.ensureFullEntry(accountIndex);

          final tradeExists = await _tradeExists(entry.tradeId);
          final accountUsed = await _tradeAccountIsUsed(
            accountIndex,
            eoaAddress: bip.EthereumAddress.fromHex(entry.evmAddress!),
          );

          if (!tradeExists && !accountUsed) {
            break;
          }

          accountIndex++;
          await _yieldToEventLoop();
        }

        // Persist the chosen index into the cache (may already be there).
        if (!_cache.containsIndex(accountIndex)) {
          await _cache.put(accountIndex);
        }

        await _auth.updateMaxAccountIndex(accountIndex);
        return accountIndex;
      });

  @override
  Future<int> findTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 64,
  }) => _logger.span('findTradeAccountIndexByTradeId', () async {
    final index = await tryFindTradeAccountIndexByTradeId(
      tradeId,
      maxScan: maxScan,
    );
    if (index != null) {
      return index;
    }
    throw StateError('No trade account index matches tradeId $tradeId');
  });

  @override
  Future<int?> tryFindTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 64,
  }) async {
    await _cache.ensureTradeIdsLoaded();

    // O(1) cache hit.
    final cached = _cache.indexByTradeId(tradeId);
    if (cached != null) {
      await _rememberObservedTradeIndex(cached);
      return cached;
    }

    // Cache miss — lightweight scan using only getTradeId.
    final upperBound = _scanUpperBound(maxScan);
    for (var index = 0; index < upperBound; index++) {
      if (_cache.containsIndex(index)) {
        await _yieldToEventLoop();
        continue;
      }
      final derivedTradeId = await _hd.getTradeId(accountIndex: index);
      // Cache the tradeId for future lookups (no salt/evmAddress yet).
      _cache.putTradeIdOnly(index, derivedTradeId);
      if (derivedTradeId == tradeId) {
        await _rememberObservedTradeIndex(index);
        return index;
      }
      await _yieldToEventLoop();
    }
    return null;
  }

  Future<void> _rememberObservedTradeIndex(int accountIndex) async {
    if (accountIndex < kFirstTradeAccountIndex) return;
    if (accountIndex <= _auth.storedMaxAccountIndex) return;
    await _auth.updateMaxAccountIndex(accountIndex);
  }

  @override
  List<int> getReservedTradeIndices() {
    if (_auth.activeKeyPair == null) {
      return const [];
    }
    final maxAccountIndex = _auth.storedMaxAccountIndex;
    if (maxAccountIndex < kFirstTradeAccountIndex) {
      return const [];
    }
    return List<int>.unmodifiable(
      List<int>.generate(
        maxAccountIndex - kFirstTradeAccountIndex + 1,
        (offset) => kFirstTradeAccountIndex + offset,
      ),
    );
  }

  int _scanUpperBound(int maxScan) {
    final maxAccountIndex = _auth.storedMaxAccountIndex;
    final maxReserved = maxAccountIndex >= 0 ? maxAccountIndex + 1 : 0;
    return maxScan > maxReserved ? maxScan : maxReserved + 1;
  }

  Future<bool> _tradeExists(String tradeId) async {
    // Check in-memory threads first — covers negotiate-only trades that have
    // never progressed to a committed order on the relay.
    if (_threads.findByConversationTag(tradeId).isNotEmpty) return true;
    final orders = await _orders.getByTradeId(tradeId);
    return orders.isNotEmpty;
  }

  Future<void> _waitForThreadHydration() async {
    final status = _threads.events$.status.value;
    if (status is StreamStatusLive) return;

    try {
      await _threads.events$.status
          .where((status) => status is StreamStatusLive)
          .first
          .timeout(const Duration(seconds: 20));
      await _yieldToEventLoop();
    } on TimeoutException {
      _logger.w(
        'Thread hydration did not reach live before trade account allocation; '
        'continuing with ${_threads.threads.length} hydrated thread(s).',
      );
    }
  }

  Future<bool> _tradeAccountIsUsed(
    int accountIndex, {
    required bip.EthereumAddress eoaAddress,
  }) async {
    final signer = await _hd.getActiveEvmKey(accountIndex: accountIndex);
    for (final configured in _evm.configuredChains) {
      if (await configured.hasAccountActivity(signer, eoaAddress: eoaAddress)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _yieldToEventLoop() => Future<void>.delayed(Duration.zero);
}
