import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../util/bitcoin_amount.dart';
import '../../../util/custom_logger.dart';
import '../../../util/network_error.dart';
import '../../auth/auth.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../operations/swap_in/swap_in_models.dart';
import '../operations/swap_in/swap_in_operation.dart';
import '../operations/swap_out/swap_out_operation.dart';

abstract class EvmChain {
  Web3Client _client;
  final CustomLogger logger;
  final Auth auth;

  /// The current [Web3Client] instance.
  ///
  /// Accessed via getter so subclasses can transparently rebuild the
  /// underlying HTTP transport after network failures.
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
    required Web3Client client,
    required this.auth,
    required CustomLogger logger,
  }) : logger = logger.scope('evm-chain'),
       _client = client;

  /// Replace the underlying [Web3Client] with a fresh instance.
  ///
  /// Called automatically by [_newBlocks] after [maxConsecutiveFailures]
  /// consecutive RPC errors. Subclasses must override to construct a new
  /// [Web3Client] appropriate for their chain.
  Web3Client buildClient();

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
    return _callRpcWithRetry(
      'getLogs(${_stringifyFilterOptions(filter)})',
      (client) => client.getLogs(filter),
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

  SupportedEscrowContract getSupportedEscrowContract(
    EscrowService escrowService,
  ) {
    return getSupportedEscrowContractByName(
      'MultiEscrow',
      EthereumAddress.fromHex(escrowService.contractAddress),
    );
  }

  SupportedEscrowContract getSupportedEscrowContractByName(
    String contractName,
    EthereumAddress address,
  ) {
    return SupportedEscrowContractRegistry.getSupportedContract(
      contractName,
      client,
      address,
    )!;
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

  Future<BitcoinAmount> getBalance(EthereumAddress address) =>
      logger.span('getBalance', () async {
        logger.d('Getting balance for $address');
        return await _callRpcWithRetry(
          'getBalance($address)',
          (client) => client.getBalance(address),
        ).then((val) {
          logger.d('Balance for $address: $val');
          return BitcoinAmount.inWei(val.getInWei);
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
    if (!_pollNow.isClosed) _pollNow.add(null);
  }

  Stream<BitcoinAmount> subscribeBalance(EthereumAddress address) async* {
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
    List<({EthereumAddress address, int accountIndex, BitcoinAmount balance})>
  >
  getAddressesWithBalance() => logger.span('getAddressesWithBalance', () async {
    const batchSize = 5;
    final funded =
        <
          ({EthereumAddress address, int accountIndex, BitcoinAmount balance})
        >[];

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
            balance: BitcoinAmount.inWei(r.balance.getInWei),
          ));
        }
      }
    }

    return funded;
  });

  /// Returns the total balance across all HD-derived addresses that hold
  /// funds, scanning up to [_maxScanIndex] indices.
  Future<BitcoinAmount> getTotalBalance() =>
      logger.span('getTotalBalance', () async {
        final addresses = await getAddressesWithBalance();
        return addresses.fold<BitcoinAmount>(
          BitcoinAmount.zero(),
          (sum, entry) => sum + entry.balance,
        );
      });

  /// Emits the total balance across all used addresses on each new block.
  Stream<BitcoinAmount> subscribeTotalBalance() async* {
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

  Future<EtherSwap> getEtherSwapContract();

  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapInLimits();

  SwapInOperation swapIn(SwapInParams params);

  Future<List<SwapOutOperation>> swapOutAll();

  /// Async version that scans all HD-derived addresses for non-zero balances
  /// and returns one [SwapOutOperation] per funded address.
  ///
  /// Subclasses should override to provide chain-specific implementations.
  /// The default falls back to [swapOutAll] (account 0 only).
  Future<List<SwapOutOperation>> swapOutAllAddresses() async =>
      await swapOutAll();

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
