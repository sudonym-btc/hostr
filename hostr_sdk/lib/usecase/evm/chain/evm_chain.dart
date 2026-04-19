import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/boltz/IERC20.g.dart';
import '../../../datasources/contracts/boltz/IERC20Metadata.g.dart';
import '../../../util/custom_logger.dart';
import '../../../util/http_client_factory.dart';
import '../../../util/network_error.dart';
import '../../../util/token_amount_ext.dart';
import '../../auth/auth.dart';
import '../../nwc/nwc.dart';
import '../../payments/payments.dart';
import '../capabilities/aa_capability.dart';
import '../capabilities/boltz_swap_provider.dart';
import '../capabilities/escrow_capability.dart';
import '../config/evm_config.dart';
import '../evm_call.dart';
import '../models/swap_quote.dart';
import '../operations/swap_in/swap_in_models.dart';
import '../operations/swap_in/swap_in_operation.dart' show SwapInOperation;
import '../operations/swap_out/swap_out_models.dart';
import '../operations/swap_out/swap_out_state.dart';
import '../operations/swap_quote_service.dart';
import 'operations/swap_in/swap_in_operation.dart';
import 'operations/swap_out/swap_out_operation.dart';
import 'rpc_batch_builder.dart';

/// Concrete EVM chain — transport layer plus assembled capabilities.
///
/// Knows how to talk to an RPC node, poll blocks, manage HD keys,
/// send transactions (via AA or EOA), and interact
/// with swap and escrow contracts.
@injectable
class EvmChain {
  final EvmChainConfig config;
  final CustomLogger logger;
  final Auth auth;

  // ── Capabilities ──────────────────────────────────────────────────

  /// ERC-4337 Account Abstraction — `null` if the chain has no AA config.
  final AACapability? aa;

  /// Boltz swap provider — `null` if Boltz doesn't support this chain.
  /// Attached after Boltz discovery in [Evm.init].
  BoltzSwapProvider? swaps;

  /// Escrow contract lookup — always present.
  late final EscrowCapability escrow;

  /// Whether this chain uses ERC-4337 Account Abstraction.
  bool get hasAA => aa != null;

  /// Quote service — injected so callers can get fee estimates without
  /// building a full operation.
  final SwapQuoteService quoteService;

  /// Nostr Wallet Connect — used by swap-out operations to pay invoices.
  final Nwc nwc;

  /// Payment tracking — used by swap-out operations to record payments.
  final Payments payments;

  late Web3Client _client;
  late http.Client _httpClient;

  /// The current [Web3Client] instance.
  Web3Client get client => _client;

  int _clientGeneration = 0;

  /// Exposes the current transport generation so callers caching
  /// chain-scoped helpers can invalidate them when the underlying
  /// [Web3Client] is rebuilt.
  int get clientGeneration => _clientGeneration;

  /// Number of consecutive RPC failures before the client is rebuilt.
  static const int maxConsecutiveFailures = 3;

  /// Maximum poll interval during backoff (caps exponential growth).
  static const Duration maxPollInterval = Duration(seconds: 60);
  static const Duration _getLogsDebounce = Duration(milliseconds: 16);

  final Map<String, List<_GetLogsRequest>> _getLogsQueues = {};
  final Map<String, Timer?> _getLogsTimers = {};
  final StreamController<void> _pollNow = StreamController<void>.broadcast();
  bool _disposed = false;

  /// ERC-20 token registry — keyed by lower-case checksummed address.
  ///
  /// Populated lazily via [resolveToken]. Native tokens are also stored here
  /// on first access so all token lookups share a single cache.
  final Map<String, Token> _tokenRegistry = {};

  EvmChain({
    @factoryParam required this.config,
    required this.auth,
    required CustomLogger logger,
    required this.quoteService,
    required this.nwc,
    required this.payments,
    @factoryParam this.aa,
    @ignoreParam http.Client? httpClient,
  }) : logger = logger.scope('evm-chain') {
    _httpClient = httpClient ?? createPlatformHttpClient();
    _client = Web3Client(config.rpcUrl, _httpClient);
    escrow = EscrowCapability(chain: this, logger: logger);
  }

  static (Web3Client, http.Client) _buildWeb3Client(String rpcUrl) {
    final httpClient = createPlatformHttpClient();
    return (Web3Client(rpcUrl, httpClient), httpClient);
  }

  /// Creates a standalone [Web3Client] with its own HTTP transport.
  ///
  /// **The caller is responsible for disposing both** the returned client
  /// and the [http.Client] (via the record's second element).
  (Web3Client, http.Client) buildClient() => _buildWeb3Client(config.rpcUrl);

  void _rebuildClient() => logger.spanSync('_rebuildClient', () {
    if (_disposed) return;
    logger.i('Rebuilding Web3Client after consecutive failures');
    final oldClient = _client;
    final oldHttp = _httpClient;
    final (newClient, newHttp) = _buildWeb3Client(config.rpcUrl);
    _client = newClient;
    _httpClient = newHttp;
    _clientGeneration++;
    oldClient.dispose();
    oldHttp.close();
  });

  void _resetClientIfGeneration(int generation) {
    if (_clientGeneration != generation) return;
    _rebuildClient();
  }

  bool _isTransientRpcError(Object error) =>
      error is http.ClientException ||
      isPlatformSocketException(error) ||
      error is TimeoutException;

  Future<T> _callRpcWithRetry<T>(
    String operation,
    Future<T> Function(Web3Client client) fn, {
    int retries = 1,
    Duration retryDelay = const Duration(milliseconds: 250),
    Duration timeout = const Duration(seconds: 30),
  }) => logger.span('_callRpcWithRetry', () async {
    for (int attempt = 1; attempt <= retries + 1; attempt++) {
      final generation = _clientGeneration;
      try {
        return await fn(client).timeout(timeout);
      } catch (error) {
        if (!_isTransientRpcError(error) || attempt > retries) rethrow;
        logger.w(
          '$operation failed on attempt $attempt/${retries + 1}: $error. '
          'Resetting Web3Client and retrying.',
        );
        _resetClientIfGeneration(generation);
        await Future.delayed(retryDelay * attempt);
      }
    }

    throw StateError('unreachable');
  });

  Future<void> dispose() async {
    _disposed = true;
    _pollNow.close(); // unblock any _newBlocks generators first
    for (final timer in _getLogsTimers.values) {
      timer?.cancel();
    }
    _getLogsTimers.clear();
    _getLogsQueues.clear();
    client.dispose();
    _httpClient.close();
  }

  Future<List<FilterEvent>> getLogs(
    FilterOptions filter, {
    bool batch = true,
    EvmLogsBatchHint? batchHint,
  }) => logger.span('getLogs', () async {
    if (!batch || batchHint == null || !batchHint.canBatch) {
      return _getLogsDirect(filter);
    }

    final topicValues = _batchedTopicValues(
      filter: filter,
      dynamicTopicIndex: batchHint.dynamicTopicIndex,
    );

    if (topicValues.isEmpty) {
      return _getLogsDirect(filter);
    }

    final completer = Completer<List<FilterEvent>>();
    final request = _GetLogsRequest(
      filter: filter,
      completer: completer,
      dynamicTopicIndex: batchHint.dynamicTopicIndex,
      topicValues: topicValues,
    );

    _getLogsQueues.putIfAbsent(batchHint.requestKey, () => []).add(request);
    _getLogsTimers[batchHint.requestKey]?.cancel();
    _getLogsTimers[batchHint.requestKey] = Timer(
      _getLogsDebounce,
      () => _flushGetLogsQueue(batchHint.requestKey),
    );

    return completer.future;
  });

  Future<List<FilterEvent>> _getLogsDirect(FilterOptions filter) {
    // Arbitrum's public RPC rejects named block tags like "earliest" in
    // eth_getLogs and requires hex block numbers.  Normalise them here so
    // every caller is safe.
    final normalised = _normaliseBlockTags(filter);
    return _callRpcWithRetry(
      'getLogs(${_stringifyFilterOptions(normalised)})',
      (client) => client.getLogs(normalised),
    );
  }

  /// Replaces the `"earliest"` block tag ([BlockNum.genesis]) with `0x0` so
  /// that RPCs which only accept hex strings (e.g. Arbitrum One) work.
  FilterOptions _normaliseBlockTags(FilterOptions filter) {
    final from = filter.fromBlock;
    final to = filter.toBlock;

    // BlockNum.genesis() → useAbsolute=false, blockNum=0 → "earliest"
    // Replace with BlockNum.exact(0) → "0x0"
    final normFrom = from != null && !from.useAbsolute && from.blockNum == 0
        ? const BlockNum.exact(0)
        : from;
    final normTo = to != null && !to.useAbsolute && to.blockNum == 0
        ? const BlockNum.exact(0)
        : to;

    if (identical(normFrom, from) && identical(normTo, to)) return filter;

    return FilterOptions(
      address: filter.address,
      topics: filter.topics,
      fromBlock: normFrom,
      toBlock: normTo,
    );
  }

  List<String> _batchedTopicValues({
    required FilterOptions filter,
    required int dynamicTopicIndex,
  }) {
    final topics = filter.topics;
    if (topics == null || dynamicTopicIndex >= topics.length) {
      return const [];
    }

    return topics[dynamicTopicIndex].whereType<String>().toList(
      growable: false,
    );
  }

  void _flushGetLogsQueue(String requestKey) {
    final queue = _getLogsQueues.remove(requestKey);
    _getLogsTimers.remove(requestKey)?.cancel();
    if (queue == null || queue.isEmpty) return;

    final first = queue.first;
    final mergedValues = queue
        .expand((request) => request.topicValues)
        .toSet()
        .toList(growable: false);

    final mergedTopics = <List<String?>>[];
    final firstTopics = first.filter.topics ?? const <List<String?>>[];
    for (var i = 0; i < firstTopics.length; i++) {
      if (i == first.dynamicTopicIndex) {
        mergedTopics.add(mergedValues);
      } else {
        mergedTopics.add(List<String?>.from(firstTopics[i]));
      }
    }

    final mergedFilter = FilterOptions(
      address: first.filter.address,
      topics: mergedTopics,
      fromBlock: first.filter.fromBlock,
      toBlock: first.filter.toBlock,
    );

    logger.d(
      'getLogs batch: ${queue.length} requests merged into 1 RPC call '
      'with ${mergedValues.length} distinct topic value(s) for '
      '${_stringifyFilterOptions(mergedFilter)}',
    );

    _getLogsDirect(mergedFilter)
        .then((logs) {
          for (final request in queue) {
            if (request.completer.isCompleted) continue;
            final matched = logs
                .where((log) {
                  final logTopics = log.topics;
                  if (logTopics == null ||
                      request.dynamicTopicIndex >= logTopics.length) {
                    return false;
                  }
                  return request.topicValues.contains(
                    logTopics[request.dynamicTopicIndex],
                  );
                })
                .toList(growable: false);
            request.completer.complete(matched);
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          for (final request in queue) {
            if (!request.completer.isCompleted) {
              request.completer.completeError(error, stackTrace);
            }
          }
        });
  }

  String _stringifyFilterOptions(FilterOptions filter) {
    return 'FilterOptions(address: ${filter.address?.eip55With0x}, '
        'topics: ${filter.topics}, fromBlock: ${filter.fromBlock}, '
        'toBlock: ${filter.toBlock})';
  }

  Future<BigInt> getChainId() async {
    return _callRpcWithRetry('getChainId', (client) => client.getChainId());
  }

  Future<int> getBlockNumber() {
    return _callRpcWithRetry(
      'getBlockNumber',
      (client) => client.getBlockNumber(),
    );
  }

  /// Known Arbitrum L2 chain IDs where [getBlockNumber] returns L2 blocks
  /// but Boltz timelock heights reference Ethereum L1 blocks.
  static const Set<int> _arbitrumChainIds = {
    42161, // Arbitrum One
    421614, // Arbitrum Sepolia
    42170, // Arbitrum Nova
    412346, // Anvil (local dev/test Arbitrum)
  };

  /// Returns the block number relevant for locktime / timelock comparisons.
  ///
  /// On Arbitrum L2 chains, Boltz swap contracts and the Boltz backend use
  /// Ethereum L1 block numbers for timelocks. However, `eth_blockNumber`
  /// on Arbitrum returns the much-larger L2 sequencer block number. This
  /// method extracts the `l1BlockNumber` from the Arbitrum block metadata
  /// so that client-side expiry checks compare apples-to-apples.
  ///
  /// On non-Arbitrum chains (e.g. Rootstock), delegates to [getBlockNumber].
  Future<int> getLocktimeBlockNumber() {
    if (!_arbitrumChainIds.contains(config.chainId)) {
      return getBlockNumber();
    }
    return _callRpcWithRetry('getLocktimeBlockNumber', (client) async {
      final block = await client.makeRPCCall<Map<String, dynamic>>(
        'eth_getBlockByNumber',
        ['latest', false],
      );
      final l1BlockHex = block['l1BlockNumber'] as String?;
      if (l1BlockHex == null) {
        logger.w(
          'Arbitrum block metadata missing l1BlockNumber, '
          'falling back to eth_blockNumber',
        );
        return client.getBlockNumber();
      }
      final clean = l1BlockHex.startsWith('0x')
          ? l1BlockHex.substring(2)
          : l1BlockHex;
      return int.parse(clean, radix: 16);
    });
  }

  Future<TokenAmount> getBalance(EthereumAddress address) =>
      logger.span('getBalance', () async {
        logger.d('Getting balance for $address');
        return await _callRpcWithRetry(
          'getBalance($address)',
          (client) => client.getBalance(address),
        ).then((val) {
          logger.d('Balance for $address: $val');
          return rbtcFromWei(val.getInWei, chainId: config.chainId);
        });
      });

  // ════════════════════════════════════════════════════════════════════
  // JSON-RPC batch transport
  //
  // The low-level [batchRpc] method sends an array of JSON-RPC requests
  // in a single HTTP POST.  Higher-level callers should use
  // [RpcBatchBuilder] to compose requests from multiple helpers into
  // one call — see [scanAllHDBalances] for an example.
  // ════════════════════════════════════════════════════════════════════

  /// Sends a [JSON-RPC batch request](https://www.jsonrpc.org/specification#batch)
  /// — a single HTTP POST whose body is an array of individual requests.
  ///
  /// Returns the results in the **same order** as [requests], with each
  /// element being either the decoded `result` field on success, or `null`
  /// if that sub-request returned an error.
  ///
  /// The method retries once on transient transport errors (same policy as
  /// [_callRpcWithRetry]). Individual JSON-RPC errors (e.g. invalid params)
  /// are **not** retried — the corresponding entry is simply `null`.
  Future<List<dynamic>> batchRpc(
    List<({String method, List<dynamic> params})> requests, {
    Duration timeout = const Duration(seconds: 30),
  }) => logger.span('batchRpc(${requests.length} calls)', () async {
    if (requests.isEmpty) return [];

    // Build the JSON-RPC array.
    final body = <Map<String, dynamic>>[];
    for (var i = 0; i < requests.length; i++) {
      body.add({
        'jsonrpc': '2.0',
        'method': requests[i].method,
        'params': requests[i].params,
        'id': i,
      });
    }

    final payload = jsonEncode(body);

    // Retry wrapper (mirrors _callRpcWithRetry logic).
    const retries = 1;
    for (var attempt = 1; attempt <= retries + 1; attempt++) {
      final generation = _clientGeneration;
      try {
        final response = await _httpClient
            .post(
              Uri.parse(config.rpcUrl),
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(timeout);

        if (response.statusCode != 200) {
          throw http.ClientException(
            'Batch RPC HTTP ${response.statusCode}: ${response.body}',
          );
        }

        final decoded = jsonDecode(response.body);

        // Some nodes (incorrectly) return a single object instead of an
        // array when the batch has one element. Handle both.
        final List<dynamic> results;
        if (decoded is List) {
          results = decoded;
        } else if (decoded is Map<String, dynamic>) {
          results = [decoded];
        } else {
          throw FormatException(
            'Unexpected batch RPC response type: ${decoded.runtimeType}',
          );
        }

        // Index by 'id' to reorder into request order.
        final byId = <int, dynamic>{};
        for (final r in results) {
          if (r is Map<String, dynamic>) {
            byId[r['id'] as int] = r;
          }
        }

        return List.generate(requests.length, (i) {
          final r = byId[i];
          if (r == null) return null;
          if (r is Map<String, dynamic> && r.containsKey('error')) {
            logger.w('Batch RPC error for id=$i: ${r['error']}');
            return null;
          }
          return (r as Map<String, dynamic>)['result'];
        });
      } catch (error) {
        if (!_isTransientRpcError(error) || attempt > retries) rethrow;
        logger.w(
          'batchRpc failed on attempt $attempt/${retries + 1}: $error. '
          'Resetting Web3Client and retrying.',
        );
        _resetClientIfGeneration(generation);
        await Future.delayed(Duration(milliseconds: 250 * attempt));
      }
    }

    throw StateError('unreachable');
  });

  /// Execute an [RpcBatch], firing all accumulated requests in a single
  /// HTTP round-trip and resolving every [BatchResult] handle.
  Future<void> executeBatch(RpcBatch batch) async {
    if (batch.isEmpty) return;
    final raw = await batchRpc(batch.requests);
    await batch.resolve(raw);
  }

  /// Fetch native (ETH/RBTC) balances for multiple addresses in a single
  /// HTTP round-trip.
  Future<Map<EthereumAddress, TokenAmount>> getBalancesBatch(
    List<EthereumAddress> addresses,
  ) => logger.span('getBalancesBatch(${addresses.length})', () async {
    if (addresses.isEmpty) return {};
    final batch = RpcBatch();
    final result = batch.getBalances(addresses, chainId: config.chainId);
    await executeBatch(batch);
    return result.value;
  });

  /// Fetch ERC-20 balances for multiple (owner, token) pairs in a single
  /// HTTP round-trip.
  Future<List<TokenAmount?>> getERC20BalancesBatch(
    List<({EthereumAddress owner, EthereumAddress token})> pairs,
  ) => logger.span('getERC20BalancesBatch(${pairs.length})', () async {
    if (pairs.isEmpty) return [];
    final batch = RpcBatch();
    final result = batch.getERC20Balances(pairs, tokenResolver: resolveToken);
    await executeBatch(batch);
    return result.value;
  });

  /// Emits a new block number whenever the chain advances.
  ///
  /// Uses `eth_blockNumber` polling — the most universally supported RPC
  /// method across all EVM nodes (Rootstock, Anvil, Geth, etc.).
  /// Unlike `eth_newBlockFilter` or `eth_subscribe`, this works with every
  /// HTTP and WebSocket RPC endpoint.
  ///
  /// Self-healing: after [maxConsecutiveFailures] consecutive errors the
  /// underlying [Web3Client] is rebuilt via [buildClient].  The poll
  /// interval doubles on each failure (capped at [maxPollInterval]) and
  /// resets on success.  Errors are never yielded — downstream streams
  /// simply stop receiving values until the transport recovers.
  Stream<int> _newBlocks({
    Duration interval = const Duration(seconds: 15),
  }) async* {
    int? lastBlock;
    int consecutiveFailures = 0;
    Duration currentInterval = interval;

    while (!_disposed) {
      try {
        final current = await _callRpcWithRetry(
          'getBlockNumber',
          (client) => client.getBlockNumber(),
        );
        // Success — reset failure tracking.
        if (consecutiveFailures > 0) {
          logger.i(
            'Block poll recovered after $consecutiveFailures failure(s)',
          );
        }
        consecutiveFailures = 0;
        currentInterval = interval;

        if (lastBlock == null || current > lastBlock) {
          lastBlock = current;
          yield current;
        }
      } catch (e) {
        if (_disposed) break;
        consecutiveFailures++;
        logger.w(
          'Block number poll failed ($consecutiveFailures/$maxConsecutiveFailures): $e',
        );

        if (consecutiveFailures >= maxConsecutiveFailures) {
          _rebuildClient();
          consecutiveFailures = 0;
        }

        // Exponential backoff: double the interval on each failure,
        // capped at maxPollInterval.
        currentInterval = Duration(
          milliseconds: min(
            (currentInterval.inMilliseconds * 2),
            maxPollInterval.inMilliseconds,
          ),
        );
      }
      if (_disposed) break;
      // Sleep until the interval elapses OR notifyNewBlock() fires.
      final delayCompleter = Completer<void>();
      final timer = Timer(currentInterval, () {
        if (!delayCompleter.isCompleted) delayCompleter.complete();
      });
      final sub = _pollNow.stream.listen(
        (_) {
          if (!delayCompleter.isCompleted) delayCompleter.complete();
        },
        onDone: () {
          if (!delayCompleter.isCompleted) delayCompleter.complete();
        },
      );
      await delayCompleter.future;
      timer.cancel();
      await sub.cancel();
    }
  }

  Stream<int> newBlocks({Duration interval = const Duration(seconds: 15)}) =>
      _newBlocks(interval: interval);

  /// Nudge all [_newBlocks] listeners to poll immediately.
  ///
  /// Call this whenever you *know* a new block has been mined (e.g. after
  /// a transaction receipt is confirmed) so that dependent streams such as
  /// escrow-event polling react without waiting for the next 15-second tick.
  void notifyNewBlock() {
    logger.d('Notifying new block');
    if (!_pollNow.isClosed) _pollNow.add(null);
  }

  Future<TransactionInformation?> getTransaction(
    String txHash,
  ) => logger.span('getTransaction', () async {
    logger.d('Getting transaction for $txHash');
    return await _callRpcWithRetry(
      'getTransactionByHash($txHash)',
      (client) => client.getTransactionByHash(txHash),
    ).then((val) {
      logger.d(
        'Transaction for $txHash: from ${val?.from} to ${val?.to} amount ${val?.value.getInWei}',
      );
      return val;
    });
  });

  Future<TransactionInformation> awaitTransaction(
    String txHash,
  ) => logger.span('awaitTransaction', () async {
    // Poll until our RPC node sees the transaction (may lag behind Boltz).
    while (true) {
      final tx = await getTransaction(txHash);
      if (tx != null) {
        logger.i(
          'Transaction $txHash visible: from ${tx.from} value ${tx.value.getInWei}',
        );
        return tx;
      }
      logger.i('Transaction $txHash not found, retrying…');
      await Future.delayed(const Duration(milliseconds: 500));
    }
  });

  Future<TransactionReceipt> awaitReceipt(String txHash) =>
      logger.span('awaitReceipt', () async {
        int polls = 0;
        logger.d('awaitReceipt: polling for $txHash');
        while (true) {
          try {
            final receipt = await _callRpcWithRetry(
              'getTransactionReceipt($txHash)',
              (client) => client.getTransactionReceipt(txHash),
            );
            if (receipt != null) {
              logger.i(
                'awaitReceipt: got receipt for $txHash after $polls polls '
                '(status=${receipt.status})',
              );
              return receipt;
            }
          } catch (e) {
            logger.w('awaitReceipt: RPC error on poll $polls for $txHash: $e');
            rethrow;
          }
          polls++;
          if (polls % 10 == 0) {
            logger.d('awaitReceipt: $polls polls for $txHash, still waiting…');
          }
          await Future.delayed(const Duration(milliseconds: 300));
        }
      });

  /// Returns the first HD-derived EVM address that has never been used
  /// on-chain (zero nonce **and** zero balance).
  ///
  /// Addresses are derived from [auth] using BIP-44 account indices
  /// (`m/44'/60'/0'/0/{index}`).  To minimise latency the function checks
  /// [_batchSize] addresses in parallel per round, which keeps RPC round-trips
  /// to a minimum while staying within typical rate-limits.
  ///
  /// Returns a record containing both the [EthereumAddress] and its
  /// [accountIndex] so callers can persist or re-derive the key later.
  Future<({EthereumAddress address, int accountIndex})>
  getNextUnusedAddress() => logger.span('getNextUnusedAddress', () async {
    const batchSize = 5;

    for (var offset = 0; ; offset += batchSize) {
      // Derive a batch of addresses.
      final indices = List.generate(batchSize, (i) => offset + i);
      final addresses = await Future.wait(
        indices.map((i) async {
          return (
            index: i,
            address: await auth.hd.getEvmAddress(accountIndex: i),
          );
        }),
      );

      // Nonce + balance in a single HTTP round-trip.
      final addrList = addresses.map((a) => a.address).toList(growable: false);
      final batch = RpcBatch();
      final nonces = batch.getTransactionCounts(addrList);
      final balances = batch.getBalances(addrList, chainId: config.chainId);
      await executeBatch(batch);

      // Return the first unused address (results are in index order).
      for (var i = 0; i < addresses.length; i++) {
        final balance = balances.value[addresses[i].address];
        if (nonces.value[i] == 0 &&
            (balance == null || balance.value == BigInt.zero)) {
          return (
            address: addresses[i].address,
            accountIndex: addresses[i].index,
          );
        }
      }
    }
  });

  /// Returns all HD-derived EVM addresses that hold a non-zero balance,
  /// along with their account index and current balance.
  ///
  /// Unlike the previous nonce-based approach, this scans a fixed window of
  /// [_maxScanIndex] addresses by **balance only**.  Addresses that received
  /// funds via swap-in never send a transaction (nonce stays 0), so
  /// nonce-based gap detection would miss them.
  static const _maxScanIndex = 5;

  Future<
    List<({EthereumAddress address, int accountIndex, TokenAmount balance})>
  >
  getAddressesWithBalance() => logger.span('getAddressesWithBalance', () async {
    final allAddresses = await _deriveHDAddresses();
    final targets = _balanceScanTargets(allAddresses);
    final addrList = targets.map((a) => a.address).toList(growable: false);

    final batch = RpcBatch();
    final balances = batch.getBalances(addrList, chainId: config.chainId);
    await executeBatch(batch);

    final fundedByAccount =
        <
          int,
          ({EthereumAddress address, int accountIndex, TokenAmount balance})
        >{};
    for (final target in targets) {
      final balance = balances.value[target.address];
      if (balance == null || balance.value == BigInt.zero) continue;
      if (target.isSmartAddress || !fundedByAccount.containsKey(target.index)) {
        fundedByAccount[target.index] = (
          address: target.address,
          accountIndex: target.index,
          balance: balance,
        );
      }
    }

    return fundedByAccount.values.toList(growable: false);
  });

  /// Returns the ERC-20 token balance for a single [owner] address.
  ///
  /// Uses the generated [IERC20] binding to call `balanceOf` and wraps
  /// the result in a [TokenAmount] with the correct [Token] metadata
  /// resolved via [resolveToken] (cached in [_tokenRegistry]).
  Future<TokenAmount> getERC20Balance(
    EthereumAddress owner,
    EthereumAddress tokenAddress,
  ) => logger.span('getERC20Balance', () async {
    final contract = IERC20(address: tokenAddress, client: client);
    final raw = await _callRpcWithRetry(
      'balanceOf(${tokenAddress.eip55With0x}, ${owner.eip55With0x})',
      (_) => contract.balanceOf((account: owner)),
    );
    final token = await resolveToken(tokenAddress.eip55With0x);
    return TokenAmount(value: raw, token: token);
  });

  /// Scans all HD-derived addresses for non-zero ERC-20 balances across
  /// the given [tokens] map (Boltz token-name → contract address).
  ///
  /// Returns one record per (address, token) pair that has a non-zero
  /// balance, along with the Boltz token name for downstream swap routing.
  Future<
    List<
      ({
        EthereumAddress address,
        int accountIndex,
        TokenAmount balance,
        String tokenName,
        EthereumAddress tokenAddress,
      })
    >
  >
  getAddressesWithTokenBalances(Map<String, EthereumAddress> tokens) =>
      logger.span('getAddressesWithTokenBalances', () async {
        if (tokens.isEmpty) return [];

        final addresses = await _deriveHDAddresses();
        final targets = _balanceScanTargets(addresses);

        // Build one batch for ALL tokens × ALL addresses.
        final batch = RpcBatch();
        final handles =
            <
              String,
              ({
                BatchResult<List<TokenAmount?>> result,
                EthereumAddress tokenAddr,
              })
            >{};

        for (final tokenEntry in tokens.entries) {
          final pairs = targets
              .map((a) => (owner: a.address, token: tokenEntry.value))
              .toList(growable: false);
          handles[tokenEntry.key] = (
            result: batch.getERC20Balances(pairs, tokenResolver: resolveToken),
            tokenAddr: tokenEntry.value,
          );
        }

        await executeBatch(batch);

        final funded =
            <
              ({
                EthereumAddress address,
                int accountIndex,
                TokenAmount balance,
                String tokenName,
                EthereumAddress tokenAddress,
              })
            >[];

        for (final entry in handles.entries) {
          final tokenName = entry.key;
          final h = entry.value;
          final fundedByAccount =
              <
                int,
                ({
                  EthereumAddress address,
                  int accountIndex,
                  TokenAmount balance,
                  String tokenName,
                  EthereumAddress tokenAddress,
                })
              >{};
          for (var i = 0; i < targets.length; i++) {
            final balance = h.result.value[i];
            if (balance != null && balance.value > BigInt.zero) {
              final target = targets[i];
              if (target.isSmartAddress ||
                  !fundedByAccount.containsKey(target.index)) {
                fundedByAccount[target.index] = (
                  address: target.address,
                  accountIndex: target.index,
                  balance: balance,
                  tokenName: tokenName,
                  tokenAddress: h.tokenAddr,
                );
              }
            }
          }
          funded.addAll(fundedByAccount.values);
        }

        return funded;
      });

  /// Scans all HD-derived addresses for **both** native and ERC-20 balances
  /// in a **single** JSON-RPC batch request.
  ///
  /// This is the most efficient way to seed balance monitors: all
  /// `eth_getBalance` + `eth_call(balanceOf)` calls are packed into one
  /// HTTP round-trip via [RpcBatchBuilder].
  Future<
    ({
      List<
        ({
          EthereumAddress address,
          EthPrivateKey keypair,
          int accountIndex,
          TokenAmount balance,
          bool isSmartAddress,
        })
      >
      nativeFunded,
      List<
        ({
          EthereumAddress address,
          EthPrivateKey keypair,
          int accountIndex,
          TokenAmount balance,
          String tokenName,
          EthereumAddress tokenAddress,
          bool isSmartAddress,
        })
      >
      tokenFunded,
    })
  >
  scanAllHDBalances({
    Map<String, EthereumAddress> tokens = const {},
  }) => logger.span('scanAllHDBalances', () async {
    final addresses = await _deriveHDAddresses();
    final targets = _balanceScanTargets(addresses);
    final addrList = targets.map((a) => a.address).toList(growable: false);

    // One batch: native balances + all ERC-20 balanceOf calls.
    final batch = RpcBatch();
    final nativeResult = batch.getBalances(addrList, chainId: config.chainId);

    final tokenHandles =
        <
          String,
          ({BatchResult<List<TokenAmount?>> result, EthereumAddress tokenAddr})
        >{};
    for (final tokenEntry in tokens.entries) {
      final pairs = targets
          .map((a) => (owner: a.address, token: tokenEntry.value))
          .toList(growable: false);
      tokenHandles[tokenEntry.key] = (
        result: batch.getERC20Balances(pairs, tokenResolver: resolveToken),
        tokenAddr: tokenEntry.value,
      );
    }

    // Single HTTP round-trip.
    await executeBatch(batch);

    // Collect native balances.
    final nativeFundedByAccount =
        <
          int,
          ({
            EthereumAddress address,
            EthPrivateKey keypair,
            int accountIndex,
            TokenAmount balance,
            bool isSmartAddress,
          })
        >{};
    for (final target in targets) {
      final balance = nativeResult.value[target.address];
      if (balance == null || balance.value == BigInt.zero) continue;
      if (target.isSmartAddress ||
          !nativeFundedByAccount.containsKey(target.index)) {
        nativeFundedByAccount[target.index] = (
          address: target.address,
          keypair: target.keypair,
          accountIndex: target.index,
          balance: balance,
          isSmartAddress: target.isSmartAddress,
        );
      }
    }

    // Collect ERC-20 balances.
    final tokenFunded =
        <
          ({
            EthereumAddress address,
            EthPrivateKey keypair,
            int accountIndex,
            TokenAmount balance,
            String tokenName,
            EthereumAddress tokenAddress,
            bool isSmartAddress,
          })
        >[];
    for (final entry in tokenHandles.entries) {
      final tokenName = entry.key;
      final h = entry.value;
      final fundedByAccount =
          <
            int,
            ({
              EthereumAddress address,
              EthPrivateKey keypair,
              int accountIndex,
              TokenAmount balance,
              String tokenName,
              EthereumAddress tokenAddress,
              bool isSmartAddress,
            })
          >{};
      for (var i = 0; i < targets.length; i++) {
        final balance = h.result.value[i];
        if (balance != null && balance.value > BigInt.zero) {
          final target = targets[i];
          if (target.isSmartAddress ||
              !fundedByAccount.containsKey(target.index)) {
            fundedByAccount[target.index] = (
              address: target.address,
              keypair: target.keypair,
              accountIndex: target.index,
              balance: balance,
              tokenName: tokenName,
              tokenAddress: h.tokenAddr,
              isSmartAddress: target.isSmartAddress,
            );
          }
        }
      }
      tokenFunded.addAll(fundedByAccount.values);
    }

    return (
      nativeFunded: nativeFundedByAccount.values.toList(growable: false),
      tokenFunded: tokenFunded,
    );
  });

  List<
    ({
      int index,
      EthPrivateKey keypair,
      EthereumAddress address,
      bool isSmartAddress,
    })
  >
  _balanceScanTargets(
    List<
      ({
        int index,
        EthPrivateKey keypair,
        EthereumAddress eoaAddress,
        EthereumAddress? smartAddress,
      })
    >
    addresses,
  ) {
    return [
      for (final entry in addresses) ...[
        (
          index: entry.index,
          keypair: entry.keypair,
          address: entry.eoaAddress,
          isSmartAddress: false,
        ),
        if (entry.smartAddress != null &&
            entry.smartAddress != entry.eoaAddress)
          (
            index: entry.index,
            keypair: entry.keypair,
            address: entry.smartAddress!,
            isSmartAddress: true,
          ),
      ],
    ];
  }

  /// Derive all HD addresses (EOA + optional smart-account) in the scan window.
  ///
  /// Keys are derived **sequentially** with event-loop yields between each
  /// derivation so the UI thread stays responsive (BIP-32 EC math takes
  /// ~500 ms per key in DDC debug mode). Smart-account addresses are then
  /// resolved in a single concurrent batch since they're I/O-bound RPCs.
  Future<
    List<
      ({
        int index,
        EthPrivateKey keypair,
        EthereumAddress eoaAddress,
        EthereumAddress? smartAddress,
      })
    >
  >
  _deriveHDAddresses() async {
    // 1. Derive EVM keys sequentially — each is CPU-bound EC point math.
    final keys = <({int index, EthPrivateKey key})>[];
    for (var i = 0; i < _maxScanIndex; i++) {
      final keypair = await auth.hd.getActiveEvmKey(accountIndex: i);
      keys.add((index: i, key: keypair));
      // Yield to the event loop so the UI can paint between derivations.
      await Future<void>.delayed(Duration.zero);
    }

    // 2. Resolve smart-account addresses concurrently (I/O-bound RPCs).
    if (aa != null) {
      final results = await Future.wait(
        keys.map((k) async {
          final smartAddress = await aa!.getSmartAccountAddress(k.key);
          return (
            index: k.index,
            keypair: k.key,
            eoaAddress: k.key.address,
            smartAddress: smartAddress,
          );
        }),
      );
      return results;
    }

    return keys
        .map(
          (k) => (
            index: k.index,
            keypair: k.key,
            eoaAddress: k.key.address,
            smartAddress: null as EthereumAddress?,
          ),
        )
        .toList();
  }

  Future<List<dynamic>> call(
    ContractAbi abi,
    EthereumAddress address,
    ContractFunction func,
    params,
  ) {
    return _callRpcWithRetry(
      'call(${func.name})',
      (client) => client.call(
        contract: DeployedContract(abi, address),
        function: func,
        params: params,
      ),
    );
  }

  // ── Account address resolution ────────────────────────────────────

  /// Returns the address that should receive funds on this chain.
  ///
  /// When AA is configured, this is the counterfactual smart-account
  /// address. Otherwise it is the plain EOA address derived from the key.
  Future<EthereumAddress> getAccountAddress(EthPrivateKey signer) async {
    if (aa != null) {
      return aa!.getSmartAccountAddress(signer);
    }
    return signer.address;
  }

  // ── Transaction sending ───────────────────────────────────────────

  /// Send one or more [Call]s as a single atomic operation.
  ///
  /// When AA is configured, the calls are batched into a single
  /// UserOperation. Otherwise each call is sent as a plain EOA
  /// transaction (sequentially).
  ///
  /// Returns the on-chain transaction hash.
  Future<String> sendCalls(
    EthPrivateKey signer,
    Map<String, Call> calls,
  ) async {
    if (aa != null) {
      return aa!.sendUserOp(signer, calls);
    }
    return _sendEoaCalls(signer, calls);
  }

  // ── Gas estimation ────────────────────────────────────────────────

  /// Estimate gas fee for the given calls (or a baseline if omitted).
  ///
  /// Delegates to AA when available; otherwise uses `eth_estimateGas`.
  Future<({BigInt gasCostWei, bool gasSponsored})> estimateGas(
    EthPrivateKey signer, {
    required Map<String, Call> calls,
    List<permissionless.StateOverride>? stateOverride,
  }) async {
    if (aa != null) {
      return aa!.estimateGasFee(
        signer,
        calls: calls,
        stateOverride: stateOverride,
      );
    }
    return _estimateEoaGas(signer, calls: calls, stateOverride: stateOverride);
  }

  // ── EOA internals ─────────────────────────────────────────────────

  Future<String> _sendEoaCalls(
    EthPrivateKey signer,
    Map<String, Call> calls,
  ) async {
    String? lastTxHash;
    for (final entry in calls.entries) {
      final call = entry.value;
      final value = EtherAmount.inWei(call.value);
      final data = _hexToBytes(call.data);
      final estimatedGas = await client.estimateGas(
        sender: signer.address,
        to: call.to,
        value: value,
        data: data,
      );
      final bufferedGas =
          (estimatedGas * BigInt.from(12) ~/ BigInt.from(10)) +
          BigInt.from(10000);
      final txHash = await client.sendTransaction(
        signer,
        Transaction(
          from: signer.address,
          to: call.to,
          value: value,
          data: data,
          maxGas: bufferedGas.toInt(),
        ),
        chainId: config.chainId,
      );
      lastTxHash = txHash;
    }
    return lastTxHash!;
  }

  static Uint8List _hexToBytes(String hexStr) {
    final clean = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
    return Uint8List.fromList(hex.decode(clean));
  }

  Future<({BigInt gasCostWei, bool gasSponsored})> _estimateEoaGas(
    EthPrivateKey signer, {
    Map<String, Call>? calls,
    List<permissionless.StateOverride>? stateOverride,
  }) async {
    if (calls == null || calls.isEmpty) {
      // Baseline estimate for contract interactions when the exact calldata is
      // not known yet (for example during swap-out quoting before Boltz has
      // returned the concrete lock parameters).
      final gasPrice = await client.getGasPrice();
      return (
        gasCostWei: BigInt.from(150000) * gasPrice.getInWei,
        gasSponsored: false,
      );
    }

    BigInt totalGas = BigInt.zero;
    final gasPrice = await client.getGasPrice();

    // Build the state-override map once (if provided) so it can be appended to
    // every raw `eth_estimateGas` call.
    final Map<String, dynamic>? overrideJson =
        (stateOverride != null && stateOverride.isNotEmpty)
        ? permissionless.stateOverridesToJson(stateOverride)
        : null;

    for (final entry in calls.entries) {
      final call = entry.value;
      if (overrideJson != null) {
        // web3dart's `estimateGas` does not support state overrides, so we
        // fall back to a raw JSON-RPC call that includes the override map as
        // the third parameter.
        final txObj = <String, dynamic>{
          'from': signer.address.hex,
          'to': call.to.hex,
          if (call.value != BigInt.zero)
            'value': '0x${call.value.toRadixString(16)}',
          'data': call.data.startsWith('0x') ? call.data : '0x${call.data}',
        };
        final amountHex = await client.makeRPCCall<String>('eth_estimateGas', [
          txObj,
          'latest',
          overrideJson,
        ]);
        totalGas += hexToInt(amountHex);
      } else {
        final gas = await client.estimateGas(
          sender: signer.address,
          to: call.to,
          value: EtherAmount.inWei(call.value),
          data: _hexToBytes(call.data),
        );
        totalGas += gas;
      }
    }
    return (gasCostWei: totalGas * gasPrice.getInWei, gasSponsored: false);
  }

  // ── Swap factories ──────────────────────────────────────────────────

  /// Create a swap-in (reverse submarine swap) operation for this chain.
  SwapInOperation swapIn({required SwapInParams params}) {
    return EvmSwapInOperation(
      chain: this,
      auth: auth,
      logger: logger,
      params: params,
    );
  }

  // ── Quote factories ─────────────────────────────────────────────────────

  /// Build a [SwapQuote] for [params] on this chain (swap-in direction).
  Future<SwapQuote> swapInQuote({required SwapInParams params}) =>
      quoteService.buildSwapInQuote(chain: this, params: params);

  /// Build a [SwapQuote] for [params] on this chain (swap-out direction).
  Future<SwapQuote> swapOutQuote({required SwapOutParams params}) =>
      quoteService.buildSwapOutQuote(chain: this, params: params);

  /// Create a swap-out (submarine swap) operation for this chain.
  EvmSwapOutOperation swapOut({
    required SwapOutParams params,
    SwapOutState? initialState,
  }) {
    return EvmSwapOutOperation(
      chain: this,
      auth: auth,
      logger: logger,
      nwc: nwc,
      payments: payments,
      quoteService: quoteService,
      params: params,
      initialState: initialState,
    );
  }

  // ── Token resolution ────────────────────────────────────────────────

  /// Resolve the full [Token] for an ERC-20 or native [address].
  ///
  /// Checks [_tokenRegistry] first; on a miss makes an on-chain
  /// `IERC20Metadata.decimals()` call and writes the result back.
  ///
  /// This is the canonical one-stop resolver — callers should prefer this
  /// over the lower-level [resolveTokenDecimals].
  Future<Token> resolveToken(String address) async {
    final key = address.toLowerCase();
    final cached = _tokenRegistry[key];
    if (cached != null) return cached;

    // Native token — no on-chain call needed.
    if (key == '0x0000000000000000000000000000000000000000') {
      final token = Token.native(config.chainId);
      _tokenRegistry[key] = token;
      return token;
    }

    final contract = IERC20Metadata(
      address: EthereumAddress.fromHex(address),
      client: client,
    );
    final decimals = (await contract.decimals()).toInt();
    final token = Token(
      chainId: config.chainId,
      address: EthereumAddress.fromHex(address).eip55With0x,
      decimals: decimals,
    );
    _tokenRegistry[key] = token;
    return token;
  }

  /// Synchronous read of the token registry.
  ///
  /// Returns `null` if the token has not yet been resolved via [resolveToken].
  Token? tokenByAddress(String address) =>
      _tokenRegistry[address.toLowerCase()];

  /// Resolve the ERC-20 `decimals()` for [address].
  ///
  /// Delegates to [resolveToken] — results are cached in [_tokenRegistry].
  Future<int> resolveTokenDecimals(String address) async =>
      (await resolveToken(address)).decimals;

  /// The internal Boltz bridge token for this chain — the first ERC-20
  /// natively supported by Boltz (e.g. tBTC on Arbitrum).
  ///
  /// This is a Boltz-level concept used for swap routing. For the token
  /// that an escrow should be funded in, use [resolveEscrowToken] instead.
  Future<Token> resolveBridgeToken() async {
    final boltzTokens = swaps?.chainInfo.tokens ?? {};
    if (boltzTokens.isNotEmpty) {
      return resolveToken(boltzTokens.values.first.eip55With0x);
    }
    return Token.native(config.chainId);
  }

  /// Resolve the on-chain token the escrow should be funded with, according
  /// to the seller's [EscrowMethod] event.
  ///
  /// Looks up [EscrowMethod.acceptedTokensFor] for the listing's denomination
  /// (e.g. `"USD"`) and resolves the first EVM `tokenTagId` (format
  /// `"chainId:address"`) with live on-chain decimals.  Falls back to
  /// [resolveBridgeToken] when no on-chain token is declared for that
  /// denomination.
  ///
  /// This is the correct source of truth — the seller declares which ERC-20
  /// they accept, not the app config.
  Future<Token> resolveEscrowToken(
    DenominatedAmount denominated,
    EscrowMethod sellerMethod,
  ) async {
    final accepted = sellerMethod.acceptedTokensFor(denominated.denomination);
    for (final tagId in accepted) {
      if (!tagId.contains(':')) continue; // skip Lightning 'BTC' sentinel
      return resolveToken(tagId.substring(tagId.indexOf(':') + 1));
    }
    return resolveBridgeToken();
  }

  /// Convert [denominated] into a [TokenAmount] scaled to [token]'s decimals.
  TokenAmount scaleToToken(DenominatedAmount denominated, Token token) {
    final scale = token.decimals - denominated.decimals;
    final value = scale <= 0
        ? denominated.value
        : denominated.value * BigInt.from(10).pow(scale);
    return TokenAmount(value: value, token: token);
  }

  /// @deprecated Use [resolveEscrowToken] + [scaleToToken] for escrow amounts.
  /// Kept for existing swap-routing callers that explicitly want the Boltz
  /// bridge token.
  Future<TokenAmount> resolveAmountInFundingToken(
    DenominatedAmount denominated,
  ) async {
    final token = await resolveBridgeToken();
    return scaleToToken(denominated, token);
  }
}

class EvmLogsBatchHint {
  final String requestKey;
  final int dynamicTopicIndex;
  final bool canBatch;

  const EvmLogsBatchHint({
    required this.requestKey,
    required this.dynamicTopicIndex,
    this.canBatch = true,
  });
}

class _GetLogsRequest {
  final FilterOptions filter;
  final Completer<List<FilterEvent>> completer;
  final int dynamicTopicIndex;
  final List<String> topicValues;

  _GetLogsRequest({
    required this.filter,
    required this.completer,
    required this.dynamicTopicIndex,
    required this.topicValues,
  });
}
