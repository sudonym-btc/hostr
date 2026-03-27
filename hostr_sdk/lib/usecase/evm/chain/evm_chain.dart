import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/boltz/IERC20.g.dart';
import '../../../util/custom_logger.dart';
import '../../../util/http_client_factory.dart';
import '../../../util/network_error.dart';
import '../../../util/token_amount_ext.dart';
import '../../auth/auth.dart';
import '../../nwc/nwc.dart';
import '../../payments/payments.dart';
import '../call_intent.dart';
import '../capabilities/aa_capability.dart';
import '../capabilities/boltz_swap_provider.dart';
import '../capabilities/escrow_capability.dart';
import '../config/evm_config.dart';
import '../operations/swap_in/swap_in_models.dart';
import '../operations/swap_in/swap_in_operation.dart' show SwapInOperation;
import '../operations/swap_out/swap_out_models.dart';
import '../operations/swap_out/swap_out_quote_service.dart';
import '../operations/swap_out/swap_out_state.dart';
import 'operations/swap_in/swap_in_operation.dart';
import 'operations/swap_out/swap_out_operation.dart';

/// Concrete EVM chain — transport layer plus assembled capabilities.
///
/// Knows how to talk to an RPC node, poll blocks, manage HD keys,
/// track balances, send transactions (via AA or EOA), and interact
/// with swap and escrow contracts.
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

  Web3Client _client;

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

  EvmChain({
    required this.config,
    required this.auth,
    required CustomLogger logger,
    this.aa,
  }) : logger = logger.scope('evm-chain'),
       _client = _buildWeb3Client(config.rpcUrl) {
    escrow = EscrowCapability(chain: this, logger: logger);
  }

  static Web3Client _buildWeb3Client(String rpcUrl) =>
      Web3Client(rpcUrl, createPlatformHttpClient());

  Web3Client buildClient() => _buildWeb3Client(config.rpcUrl);

  void _rebuildClient() => logger.spanSync('_rebuildClient', () {
    logger.i('Rebuilding Web3Client after consecutive failures');
    final oldClient = _client;
    _client = buildClient();
    _clientGeneration++;
    oldClient.dispose();
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
    for (final timer in _getLogsTimers.values) {
      timer?.cancel();
    }
    _getLogsTimers.clear();
    _getLogsQueues.clear();
    _pollNow.close();
    client.dispose();
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
          return rbtcFromWei(val.getInWei);
        });
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

    while (true) {
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
      // Sleep until the interval elapses OR notifyNewBlock() fires.
      final delayCompleter = Completer<void>();
      final timer = Timer(currentInterval, () {
        if (!delayCompleter.isCompleted) delayCompleter.complete();
      });
      final sub = _pollNow.stream.listen((_) {
        if (!delayCompleter.isCompleted) delayCompleter.complete();
      });
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

  Stream<TokenAmount> subscribeBalance(EthereumAddress address) async* {
    try {
      yield await getBalance(address);
    } catch (e) {
      logger.w('Failed initial balance fetch: $e');
    }

    await for (final _ in _newBlocks()) {
      try {
        yield await getBalance(address);
      } catch (e) {
        logger.w('Failed to fetch balance on new block: $e');
      }
    }
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

      // Fire nonce + balance queries for every address in the batch at once.
      final results = await Future.wait(
        addresses.map((entry) async {
          final nonce = await _callRpcWithRetry(
            'getTransactionCount(${entry.address})',
            (client) => client.getTransactionCount(entry.address),
          );
          final balance = await _callRpcWithRetry(
            'getBalance(${entry.address})',
            (client) => client.getBalance(entry.address),
          );
          return (
            index: entry.index,
            address: entry.address,
            used: nonce > 0 || balance.getInWei > BigInt.zero,
          );
        }),
      );

      // Return the first unused address (results are in index order).
      for (final r in results) {
        if (!r.used) {
          return (address: r.address, accountIndex: r.index);
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
  static const _maxScanIndex = 20;

  Future<
    List<({EthereumAddress address, int accountIndex, TokenAmount balance})>
  >
  getAddressesWithBalance() => logger.span('getAddressesWithBalance', () async {
    const batchSize = 5;
    final funded =
        <({EthereumAddress address, int accountIndex, TokenAmount balance})>[];

    for (var offset = 0; offset < _maxScanIndex; offset += batchSize) {
      final count = min(batchSize, _maxScanIndex - offset);
      final indices = List.generate(count, (i) => offset + i);
      final addresses = await Future.wait(
        indices.map((i) async {
          return (
            index: i,
            address: await auth.hd.getEvmAddress(accountIndex: i),
          );
        }),
      );

      final results = await Future.wait(
        addresses.map((entry) async {
          final balance = await _callRpcWithRetry(
            'getBalance(${entry.address})',
            (client) => client.getBalance(entry.address),
          );
          return (index: entry.index, address: entry.address, balance: balance);
        }),
      );

      for (final r in results) {
        if (r.balance.getInWei > BigInt.zero) {
          funded.add((
            address: r.address,
            accountIndex: r.index,
            balance: rbtcFromWei(r.balance.getInWei),
          ));
        }
      }
    }

    return funded;
  });

  /// Returns the ERC-20 token balance for a single [owner] address.
  ///
  /// Uses the generated [IERC20] binding to call `balanceOf` and wraps
  /// the result in a [TokenAmount] with the correct [Token] metadata
  /// resolved from [config.tokens] (falls back to 18 decimals).
  Future<TokenAmount> getERC20Balance(
    EthereumAddress owner,
    EthereumAddress tokenAddress,
  ) => logger.span('getERC20Balance', () async {
    final token = IERC20(address: tokenAddress, client: client);
    final raw = await _callRpcWithRetry(
      'balanceOf(${tokenAddress.eip55With0x}, ${owner.eip55With0x})',
      (_) => token.balanceOf((account: owner)),
    );
    return tokenAmountFromEvm(
      tokenAddress.eip55With0x,
      raw,
      chainId: config.chainId,
      knownTokens: config.tokens,
    );
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

        // Derive all HD addresses up front.
        final addresses = await Future.wait(
          List.generate(_maxScanIndex, (i) async {
            return (
              index: i,
              address: await auth.hd.getEvmAddress(accountIndex: i),
            );
          }),
        );

        // For each token, check all addresses in parallel.
        for (final tokenEntry in tokens.entries) {
          final tokenName = tokenEntry.key;
          final tokenAddr = tokenEntry.value;

          final results = await Future.wait(
            addresses.map((entry) async {
              final balance = await getERC20Balance(entry.address, tokenAddr);
              return (entry: entry, balance: balance);
            }),
          );

          for (final r in results) {
            if (r.balance.value > BigInt.zero) {
              funded.add((
                address: r.entry.address,
                accountIndex: r.entry.index,
                balance: r.balance,
                tokenName: tokenName,
                tokenAddress: tokenAddr,
              ));
            }
          }
        }

        return funded;
      });

  /// Returns the total balance across all HD-derived addresses that hold
  /// funds, scanning up to [_maxScanIndex] indices.
  Future<TokenAmount> getTotalBalance() =>
      logger.span('getTotalBalance', () async {
        final addresses = await getAddressesWithBalance();
        return addresses.fold<TokenAmount>(
          TokenAmount.zero(rbtc),
          (sum, entry) => sum + entry.balance,
        );
      });

  /// Emits the total balance across all used addresses on each new block.
  Stream<TokenAmount> subscribeTotalBalance() async* {
    try {
      yield await getTotalBalance();
    } catch (e) {
      logger.w('Failed initial total balance fetch: $e');
    }

    await for (final _ in _newBlocks()) {
      try {
        yield await getTotalBalance();
      } catch (e) {
        logger.w('Failed to fetch total balance on new block: $e');
      }
    }
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

  /// Send one or more [CallIntent]s as a single atomic operation.
  ///
  /// When AA is configured, the intents are batched into a single
  /// UserOperation. Otherwise each intent is sent as a plain EOA
  /// transaction (sequentially).
  ///
  /// Returns the on-chain transaction hash.
  Future<String> sendCalls(
    EthPrivateKey signer,
    List<CallIntent> intents,
  ) async {
    if (aa != null) {
      return aa!.sendUserOp(signer, intents);
    }
    return _sendEoaCalls(signer, intents);
  }

  // ── Gas estimation ────────────────────────────────────────────────

  /// Estimate gas fee for the given call intents (or a baseline if omitted).
  ///
  /// Delegates to AA when available; otherwise uses `eth_estimateGas`.
  Future<({BigInt gasCostWei, bool gasSponsored})> estimateGas(
    EthPrivateKey signer, {
    List<CallIntent>? intents,
  }) async {
    if (aa != null) {
      return aa!.estimateGasFee(signer, intents: intents);
    }
    return _estimateEoaGas(signer, intents: intents);
  }

  // ── EOA internals ─────────────────────────────────────────────────

  Future<String> _sendEoaCalls(
    EthPrivateKey signer,
    List<CallIntent> intents,
  ) async {
    String? lastTxHash;
    for (final intent in intents) {
      final estimatedGas = await client.estimateGas(
        sender: signer.address,
        to: intent.to,
        value: intent.value,
        data: intent.data,
      );
      final bufferedGas =
          (estimatedGas * BigInt.from(12) ~/ BigInt.from(10)) +
          BigInt.from(10000);
      final txHash = await client.sendTransaction(
        signer,
        Transaction(
          from: signer.address,
          to: intent.to,
          value: intent.value,
          data: intent.data,
          maxGas: bufferedGas.toInt(),
        ),
        chainId: config.chainId,
      );
      lastTxHash = txHash;
    }
    return lastTxHash!;
  }

  Future<({BigInt gasCostWei, bool gasSponsored})> _estimateEoaGas(
    EthPrivateKey signer, {
    List<CallIntent>? intents,
  }) async {
    if (intents == null || intents.isEmpty) {
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
    for (final intent in intents) {
      final gas = await client.estimateGas(
        sender: signer.address,
        to: intent.to,
        value: intent.value,
        data: intent.data,
      );
      totalGas += gas;
    }
    return (gasCostWei: totalGas * gasPrice.getInWei, gasSponsored: false);
  }

  // ── Swap factories ──────────────────────────────────────────────────

  /// Create a swap-in (reverse submarine swap) operation for this chain.
  SwapInOperation swapIn({
    required SwapInParams params,
    required Auth auth,
    required CustomLogger logger,
  }) {
    return EvmSwapInOperation(
      chain: this,
      auth: auth,
      logger: logger,
      params: params,
    );
  }

  /// Create a swap-out (submarine swap) operation for this chain.
  EvmSwapOutOperation swapOut({
    required SwapOutParams params,
    required Auth auth,
    required CustomLogger logger,
    required Nwc nwc,
    required Payments payments,
    required SwapOutQuoteService quoteService,
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

  /// Resolve the concrete on-chain funding token from Boltz chain info.
  ///
  /// If Boltz has ERC-20 tokens configured for this chain, returns the first
  /// one (with correct decimals from [config.tokens]). Otherwise returns the
  /// chain's native asset.
  Token resolveBoltzFundingToken() {
    final boltzTokens = swaps?.chainInfo.tokens ?? {};
    if (boltzTokens.isNotEmpty) {
      final boltzTokenAddress = boltzTokens.values.first;
      var decimals = 18;
      for (final tokenConfig in config.tokens.values) {
        if (tokenConfig.address.toLowerCase() ==
            boltzTokenAddress.eip55With0x.toLowerCase()) {
          decimals = tokenConfig.decimals;
          break;
        }
      }
      return Token(
        chainId: config.chainId,
        address: boltzTokenAddress.eip55With0x,
        decimals: decimals,
      );
    }
    return Token.rbtc(config.chainId);
  }

  /// Convert a [DenominatedAmount] (e.g. BTC sats) into a [TokenAmount]
  /// denominated in the resolved Boltz funding token.
  ///
  /// Scales from the denomination's decimal precision to the token's
  /// decimals.
  TokenAmount resolveAmountInFundingToken(DenominatedAmount denominated) {
    final token = resolveBoltzFundingToken();
    final scale = token.decimals - denominated.decimals;
    final value = scale <= 0
        ? denominated.value
        : denominated.value * BigInt.from(10).pow(scale);
    return TokenAmount(value: value, token: token);
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

double convertWeiToSatoshi(BigInt wei) {
  return wei.toDouble() / pow(10, 18 - 8);
}

double convertWeiToBTC(BigInt wei) {
  return wei.toDouble() / pow(10, 18);
}
