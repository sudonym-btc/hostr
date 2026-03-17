import 'dart:math';

import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/escrow/MultiEscrow.g.dart';
import '../../../util/main.dart';
import '../../evm/chain/evm_chain.dart';
import '../../payments/constants.dart';
import 'supported_escrow_contract.dart';

class MultiEscrowContractException implements Exception {
  final String selector;
  final String errorName;
  final String message;
  final Object? originalError;

  MultiEscrowContractException({
    required this.selector,
    required this.errorName,
    required this.message,
    this.originalError,
  });

  @override
  String toString() =>
      'MultiEscrowContractException($errorName, selector: $selector): $message';
}

class MultiEscrowWrapper extends SupportedEscrowContract<MultiEscrow> {
  static const List<String> _eventNames = [
    'TradeCreated',
    'Arbitrated',
    'Claimed',
    'ReleasedToCounterparty',
  ];

  static const Map<String, String> _customErrorSelectors = {
    '0x916da0d1': 'ClaimPeriodNotStarted',
    '0xdff46e2b': 'NoFundsToClaim',
    '0xb95c5dfc': 'TradeNotActive',
    '0x85d1f726': 'OnlySeller',
    '0x39fc5e0a': 'OnlyBuyerOrSeller',
    '0xe598e3ce': 'OnlyArbiter',
    '0x7505eadc': 'TradeIdAlreadyExists',
    '0xca4b8ad6': 'TradeAlreadyActive',
    '0x29ce3ded': 'MustSendFunds',
    '0xb7cc22bc': 'NoFundsToRelease',
    '0x3fb86fe2': 'InvalidFactor',
    '0xf4b3b1bc': 'NativeTransferFailed',
  };

  final CustomLogger logger;
  final EvmChain? chain;
  final Map<String, _CachedTradeEvents> _tradeEvents = {};

  MultiEscrowWrapper({
    required super.client,
    required super.address,
    super.rifRelay,
    this.chain,
    required CustomLogger logger,
  }) : logger = logger.scope('multi-escrow'),
       super(
         contract: MultiEscrow(address: address, client: client),
         supportsClaimSwapAndFund: true,
       );

  @override
  ContractCallIntent fund(FundArgs args) => logger.spanSync('fund', () {
    return buildIntent(
      functionName: 'createTrade',
      args: [
        getBytes32(args.tradeId),
        args.ethKey.address,
        EthereumAddress.fromHex(args.sellerEvmAddress),
        EthereumAddress.fromHex(args.arbiterEvmAddress),
        BigInt.from(args.unlockAt),
        args.escrowFee?.getInWei ?? BigInt.zero,
      ],
      from: args.ethKey.address,
      methodName: 'createTrade',
      value: args.amount.toEtherAmount(),
      gasPrice: args.gasEstimate?.gasPrice,
      maxGas: args.gasEstimate?.gasLimit.toInt(),
    );
  });

  @override
  Future<ContractCallIntent> fundRelayed(FundArgs args) async => fund(args);

  @override
  ContractCallIntent claim({
    required String tradeId,
    required EthPrivateKey ethKey,
  }) => logger.spanSync('claim', () {
    return buildIntent(
      functionName: 'claim',
      args: [getBytes32(tradeId)],
      from: ethKey.address,
      methodName: 'claim',
    );
  });

  @override
  Future<ContractCallIntent> claimRelayed({
    required String tradeId,
    required EthPrivateKey ethKey,
  }) => logger.span('claimRelayed', () {
    return buildAuthorizedRelayIntent(
      tradeId: getBytes32(tradeId),
      ethKey: ethKey,
      authorizationHashFn: contract.hashClaimAuthorization,
      functionName: 'claim',
      methodName: 'claimRelayed',
    );
  });

  @override
  ContractCallIntent claimSwapAndFund(ClaimSwapAndFundArgs args) =>
      logger.spanSync('claimAndFund', () {
        final sender = args.fundArgs.ethKey.address;
        final estimatedMaxGas = args.fundArgs.gasEstimate?.gasLimit.toInt();
        final claimAndFundMaxGas = estimatedMaxGas == null
            ? null
            : max(estimatedMaxGas * 2, 500000);
        logger.i(
          'claimAndFund sender=${sender.eip55With0x} '
          'buyer=${args.fundArgs.ethKey.address.eip55With0x} '
          'seller=${args.fundArgs.sellerEvmAddress} '
          'arbiter=${args.fundArgs.arbiterEvmAddress} '
          'swapContract=${args.swapContract.eip55With0x} '
          'amount=${args.claimArgs.amount} '
          'gasPrice=${args.fundArgs.gasEstimate?.gasPrice.getInWei} '
          'estimatedMaxGas=${args.fundArgs.gasEstimate?.gasLimit} '
          'claimAndFundMaxGas=$claimAndFundMaxGas',
        );

        return buildIntent(
          functionName: 'claimSwapAndFund',
          args: [
            [
              args.swapContract,
              args.claimArgs.preimage,
              args.claimArgs.amount,
              args.claimArgs.refundAddress,
              args.claimArgs.timelock,
              args.claimArgs.v,
              args.claimArgs.r,
              args.claimArgs.s,
            ],
            [
              getBytes32(args.fundArgs.tradeId),
              args.fundArgs.ethKey.address,
              EthereumAddress.fromHex(args.fundArgs.sellerEvmAddress),
              EthereumAddress.fromHex(args.fundArgs.arbiterEvmAddress),
              BigInt.from(args.fundArgs.unlockAt),
              args.fundArgs.escrowFee?.getInWei ?? BigInt.zero,
            ],
          ],
          from: sender,
          methodName: 'claimSwapAndFund',
          gasPrice: args.fundArgs.gasEstimate?.gasPrice,
          maxGas: claimAndFundMaxGas,
        );
      });

  @override
  Future<ContractCallIntent> claimSwapAndFundRelayed(
    ClaimSwapAndFundArgs args,
  ) async => claimSwapAndFund(args);

  @override
  ContractCallIntent arbitrate({
    required String tradeId,
    required double forward,
    required EthPrivateKey ethKey,
  }) => logger.spanSync('arbitrate', () {
    final function = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'arbitrate',
    );
    final data = function.encodeCall([
      getBytes32(tradeId),
      BigInt.from((forward * 1000).round()),
    ]);
    return ContractCallIntent(
      to: contract.self.address,
      data: data,
      value: EtherAmount.zero(),
      from: ethKey.address,
      methodName: 'arbitrate',
    );
  });

  @override
  ContractCallIntent release(ReleaseArgs args) =>
      logger.spanSync('release', () {
        return buildIntent(
          functionName: 'releaseToCounterparty',
          args: [getBytes32(args.tradeId)],
          from: args.ethKey.address,
          methodName: 'releaseToCounterparty',
        );
      });

  @override
  Future<ContractCallIntent> releaseRelayed(ReleaseArgs args) =>
      logger.span('releaseRelayed', () {
        return buildAuthorizedRelayIntent(
          tradeId: getBytes32(args.tradeId),
          ethKey: args.ethKey,
          authorizationHashFn: contract.hashReleaseAuthorization,
          functionName: 'releaseToCounterparty',
          methodName: 'releaseToCounterpartyRelayed',
        );
      });

  @override
  Future<OnChainTrade?> getTrade(String tradeId) =>
      logger.span('getTrade', () async {
        await ensureDeployed();
        final activeTrade = await _withDecodedCustomError(() {
          return contract.activeTrade((tradeId: getBytes32(tradeId)));
        });

        if (!activeTrade.isActive) return null;

        final trade = _extractTrade(activeTrade.trade);
        if (trade == null) return null;

        return OnChainTrade(
          isActive: true,
          buyer: trade.buyer,
          seller: trade.seller,
          arbiter: trade.arbiter,
          amount: trade.amount,
          unlockAt: trade.unlockAt,
          escrowFee: trade.escrowFee,
        );
      });

  @override
  Future<bool> canClaim({required String tradeId}) =>
      logger.span('canClaim', () async {
        await ensureDeployed();
        final activeTrade = await _withDecodedCustomError(() {
          return contract.activeTrade((tradeId: getBytes32(tradeId)));
        });

        if (!activeTrade.isActive) {
          return false;
        }

        final trade = _extractTrade(activeTrade.trade);
        if (trade == null) {
          logger.w('Could not decode active trade for $tradeId');
          return false;
        }

        return DateTime.now().millisecondsSinceEpoch ~/ 1000 >
            trade.unlockAt.toInt();
      });

  @override
  Future<bool> canRelease(ReleaseArgs args) =>
      logger.span('canRelease', () async {
        await ensureDeployed();
        final activeTrade = await _withDecodedCustomError(() {
          return contract.activeTrade((tradeId: getBytes32(args.tradeId)));
        });

        if (!activeTrade.isActive) {
          return false;
        }

        final trade = _extractTrade(activeTrade.trade);
        if (trade == null) {
          logger.w('Could not decode active trade for ${args.tradeId}');
          return false;
        }

        final actor = args.ethKey.address;
        return actor == trade.buyer || actor == trade.seller;
      });

  @override
  StreamWithStatus<EscrowEvent> allEvents(
    ContractEventsParams params,
    EscrowServiceSelected? selectedEscrow, {
    bool includeLive = true,
    bool batch = true,
  }) => logger.spanSync('allEvents', () {
    final eventNamesByTopic = _eventNamesByTopic();
    final cachedTrade = params.tradeId != null
        ? _tradeEvents[params.tradeId!]
        : null;

    if (params.tradeId != null && cachedTrade?.isTerminal == true) {
      logger.d('Returning cached terminal events for trade ${params.tradeId}');
      return StreamWithStatus<EscrowEvent>.query(
        query: () => Stream.fromIterable(cachedTrade!.events),
      );
    }

    final eventFilter = _buildEventFilter(
      params,
      eventNamesByTopic.keys,
      fromBlock: _effectiveFromBlock(cachedTrade),
    );
    logger.d(
      'Subscribing to events for trade id at address: ${params.tradeId}, ${contract.self.address}',
    );

    final cachedEvents = cachedTrade?.events ?? const <EscrowEvent>[];
    final logStore = <FilterEvent>[];

    return StreamWithStatus<EscrowEvent>.query(
      query: () async* {
        for (final event in cachedEvents) {
          yield event;
        }

        await ensureDeployed();
        final logs = await _getLogs(eventFilter, params: params, batch: batch);
        logger.d(
          'Fetched ${logs.length} logs for filter: ${eventFilter.stringify()}',
        );
        logStore.addAll(logs);

        for (final log in logs) {
          if (log.transactionHash == null) continue;
          yield await _mapAndCacheEscrowEvent(
            log,
            eventNamesByTopic,
            selectedEscrow,
          );
        }
      },
      live: includeLive == true
          ? () => contract.client
                .events(
                  FilterOptions(
                    address: eventFilter.address,
                    topics: eventFilter.topics,
                    fromBlock: _nextLiveBlock(
                      logStore,
                      cachedHighestSeenBlock: cachedTrade?.highestSeenBlock,
                    ),
                  ),
                )
                .where((log) => log.transactionHash != null)
                .asyncMap(
                  (log) => _mapAndCacheEscrowEvent(
                    log,
                    eventNamesByTopic,
                    selectedEscrow,
                  ),
                )
          : null,
    );
  });

  Map<String, String> _eventNamesByTopic() => {
    for (final name in _eventNames) _eventTopic(name): name,
  };

  FilterOptions _buildEventFilter(
    ContractEventsParams params,
    Iterable<String> eventTopics, {
    BlockNum? fromBlock,
  }) {
    final topics = <List<String?>>[
      [...eventTopics],
    ];

    if (params.tradeId != null) {
      topics.add([_tradeIdTopic(params.tradeId!)]);
    }
    if (params.arbiterEvmAddress != null) {
      if (params.tradeId == null) {
        topics.add([]);
      }
      topics.add([_indexedAddressTopic(params.arbiterEvmAddress!)]);
    }

    return FilterOptions(
      address: contract.self.address,
      topics: topics,
      fromBlock: fromBlock ?? BlockNum.genesis(),
    );
  }

  Future<List<FilterEvent>> _getLogs(
    FilterOptions eventFilter, {
    required ContractEventsParams params,
    required bool batch,
  }) {
    final currentChain = chain;
    final tradeId = params.tradeId;
    if (currentChain == null || tradeId == null) {
      return contract.client.getLogs(eventFilter);
    }

    return currentChain.getLogs(
      eventFilter,
      batch: batch,
      batchHint: EvmLogsBatchHint(
        requestKey: _logsRequestKey(eventFilter),
        dynamicTopicIndex: 1,
      ),
    );
  }

  String _logsRequestKey(FilterOptions filter) {
    final topics = filter.topics ?? const <List<String?>>[];
    final normalizedTopics = <String>[];
    for (var i = 0; i < topics.length; i++) {
      if (i == 1) {
        normalizedTopics.add('<batched-trade-id>');
      } else {
        normalizedTopics.add(topics[i].join('|'));
      }
    }

    return [
      contract.self.address.eip55With0x,
      '${filter.fromBlock}',
      '${filter.toBlock}',
      ...normalizedTopics,
    ].join('::');
  }

  BlockNum _effectiveFromBlock(_CachedTradeEvents? cachedTrade) {
    if (cachedTrade?.highestSeenBlock == null) {
      return BlockNum.genesis();
    }
    return BlockNum.exact(cachedTrade!.highestSeenBlock! + 1);
  }

  Future<EscrowEvent> _mapEscrowEvent(
    FilterEvent log,
    Map<String, String> eventNamesByTopic,
    EscrowServiceSelected? selectedEscrow,
  ) async {
    final block = await _blockForLog(log);
    final txHash = log.transactionHash!;

    switch (eventNamesByTopic[log.topics?.first]) {
      case 'TradeCreated':
        final tradeCreated = TradeCreated(
          _decodeEvent('TradeCreated', log),
          log,
        );
        final trade = await contract.trades(
          ($param25: tradeCreated.tradeId),
          atBlock: log.blockNum != null
              ? BlockNum.exact(log.blockNum!.toInt())
              : null,
        );
        return EscrowFundedEvent(
          tradeId: bytesToHex(tradeCreated.tradeId),
          block: block,
          escrowService: selectedEscrow,
          transactionHash: txHash,
          amount: BitcoinAmount.fromBigInt(BitcoinUnit.wei, trade.amount),
          unlockAt: tradeCreated.unlockAt.toInt(),
        );
      case 'Arbitrated':
        final arb = Arbitrated(_decodeEvent('Arbitrated', log), log);
        return EscrowArbitratedEvent(
          tradeId: bytesToHex(arb.tradeId),
          block: block,
          escrowService: selectedEscrow,
          transactionHash: txHash,
          forwarded: arb.fractionForwarded.toInt() / 1000,
        );
      case 'ReleasedToCounterparty':
        final released = ReleasedToCounterparty(
          _decodeEvent('ReleasedToCounterparty', log),
          log,
        );
        return EscrowReleasedEvent(
          tradeId: bytesToHex(released.tradeId),
          block: block,
          escrowService: selectedEscrow,
          transactionHash: txHash,
        );
      case 'Claimed':
        final claimed = Claimed(_decodeEvent('Claimed', log), log);
        return EscrowClaimedEvent(
          tradeId: bytesToHex(claimed.tradeId),
          block: block,
          escrowService: selectedEscrow,
          transactionHash: txHash,
        );
      default:
        logger.w(
          'Unknown event found in allEvents stream: ${log.topics?.first}',
        );
        return UnknownEscrowEvent(
          tradeId: '',
          block: block,
          escrowService: selectedEscrow,
        );
    }
  }

  Future<EscrowEvent> _mapAndCacheEscrowEvent(
    FilterEvent log,
    Map<String, String> eventNamesByTopic,
    EscrowServiceSelected? selectedEscrow,
  ) async {
    final event = await _mapEscrowEvent(log, eventNamesByTopic, selectedEscrow);
    _recordTradeEvent(event, log.blockNum?.toInt());
    return event;
  }

  void _recordTradeEvent(EscrowEvent event, int? blockNum) {
    final tradeId = event.tradeId;
    if (tradeId.isEmpty) return;

    final previous = _tradeEvents[tradeId];
    final mergedEvents = _mergeEvents(previous?.events ?? const [], event);
    final highestSeenBlock = [previous?.highestSeenBlock, blockNum]
        .whereType<int>()
        .fold<int?>(null, (maxSoFar, value) {
          if (maxSoFar == null) return value;
          return max(maxSoFar, value);
        });

    final isTerminal =
        previous?.isTerminal == true ||
        event is EscrowReleasedEvent ||
        event is EscrowClaimedEvent ||
        event is EscrowArbitratedEvent;

    _tradeEvents[tradeId] = _CachedTradeEvents(
      events: mergedEvents,
      highestSeenBlock: highestSeenBlock,
      isTerminal: isTerminal,
    );
  }

  List<EscrowEvent> _mergeEvents(List<EscrowEvent> existing, EscrowEvent next) {
    final identity = _eventIdentity(next);
    if (existing.any((event) => _eventIdentity(event) == identity)) {
      return existing;
    }
    return [...existing, next];
  }

  String _eventIdentity(EscrowEvent event) {
    final txHash = switch (event) {
      EscrowFundedEvent funded => funded.transactionHash,
      EscrowReleasedEvent released => released.transactionHash,
      EscrowArbitratedEvent arbitrated => arbitrated.transactionHash,
      EscrowClaimedEvent claimed => claimed.transactionHash,
      _ => '',
    };
    return '${event.runtimeType}:${event.tradeId}:$txHash';
  }

  Future<BlockInformation> _blockForLog(FilterEvent log) async {
    final receipt = await contract.client.getTransactionByHash(
      log.transactionHash!,
    );
    return contract.client.getBlockInformation(
      blockNumber: receipt!.blockNumber.toString(),
    );
  }

  List<dynamic> _decodeEvent(String eventName, FilterEvent log) => contract
      .self
      .events
      .firstWhere((event) => event.name == eventName)
      .decodeResults(log.topics!, log.data!);

  BlockNum _nextLiveBlock(
    List<FilterEvent> logStore, {
    int? cachedHighestSeenBlock,
  }) {
    final blockNumbers = logStore
        .where((event) => event.blockNum != null)
        .map((event) => event.blockNum!.toInt());
    if (blockNumbers.isEmpty && cachedHighestSeenBlock == null) {
      return BlockNum.current();
    }

    var highestSeenBlock = cachedHighestSeenBlock;
    for (final blockNumber in blockNumbers) {
      highestSeenBlock = highestSeenBlock == null
          ? blockNumber
          : max(highestSeenBlock, blockNumber);
    }

    if (highestSeenBlock == null) {
      return BlockNum.current();
    }

    return BlockNum.exact(highestSeenBlock + 1);
  }

  String _eventTopic(String eventName) => bytesToHex(
    contract.self.events
        .firstWhere((event) => event.name == eventName)
        .signature,
    padToEvenLength: true,
    include0x: true,
  );

  String _tradeIdTopic(String tradeId) =>
      bytesToHex(getBytes32(tradeId), padToEvenLength: true, include0x: true);

  String _indexedAddressTopic(EthereumAddress address) =>
      '0x${address.without0x.padLeft(64, '0')}';

  Trades? _extractTrade(dynamic trade) => logger.spanSync('_extractTrade', () {
    if (trade is Trades) {
      return trade;
    }
    if (trade is List<dynamic>) {
      try {
        return Trades(trade);
      } catch (_) {
        return null;
      }
    }
    return null;
  });

  Future<T> _withDecodedCustomError<T>(Future<T> Function() action) =>
      logger.span('_withDecodedCustomError', () async {
        try {
          return await action();
        } catch (error) {
          final decoded = _decodeCustomError(error);
          if (decoded != null) {
            logger.w(decoded.toString());
            throw decoded;
          }
          rethrow;
        }
      });

  @override
  Object decodeWriteError(Object error) {
    final decoded = _decodeCustomError(error);
    if (decoded != null) {
      logger.w(decoded.toString());
      return decoded;
    }
    return error;
  }

  MultiEscrowContractException? _decodeCustomError(Object error) =>
      logger.spanSync('_decodeCustomError', () {
        final text = error.toString();
        final match = RegExp(
          r'custom error\s*:??\s*(0x[a-fA-F0-9]{8})',
          caseSensitive: false,
        ).firstMatch(text);

        if (match == null) {
          return null;
        }

        final selector = match.group(1)!.toLowerCase();
        final errorName =
            _customErrorSelectors[selector] ?? 'UnknownCustomError';
        return MultiEscrowContractException(
          selector: selector,
          errorName: errorName,
          message: text,
          originalError: error,
        );
      });
}

class _CachedTradeEvents {
  final List<EscrowEvent> events;
  final int? highestSeenBlock;
  final bool isTerminal;

  const _CachedTradeEvents({
    required this.events,
    required this.highestSeenBlock,
    required this.isTerminal,
  });
}

extension on FilterOptions {
  String stringify() {
    return 'FilterOptions(address: ${address?.eip55With0x}, topics: $topics, fromBlock: $fromBlock, toBlock: $toBlock)';
  }
}
