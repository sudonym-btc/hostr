import 'dart:async';
import 'dart:math';

import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/escrow/MultiEscrow.g.dart';
import '../../../util/main.dart';
import '../../evm/chain/evm_chain.dart';
import '../../payments/constants.dart';
import 'supported_escrow_contract.dart';

/// Handles event-log scanning, live polling, and per-trade event caching
/// for [MultiEscrow] contracts.
///
/// Extracted from [MultiEscrowWrapper] to isolate the event-scanning concern
/// from call-building and on-chain reads.
class EscrowEventScanner {
  static const List<String> _eventNames = [
    'TradeCreated',
    'Arbitrated',
    'Claimed',
    'ReleasedToCounterparty',
  ];

  final MultiEscrow contract;
  final EvmChain? chain;
  final CustomLogger logger;

  /// Back-reference to the wrapper so events carry a [SupportedEscrowContract].
  final SupportedEscrowContract? parentContract;

  final Map<String, CachedTradeEvents> _tradeEvents = {};
  final List<_LiveTradeSubscription> _liveTradeSubscriptions = [];
  StreamSubscription<void>? _liveTradeBlockSub;
  int? _liveTradeLastQueried;

  static const int _maxLiveTradeTopicsPerGetLogs = 75;

  EscrowEventScanner({
    required this.contract,
    required this.chain,
    required this.parentContract,
    required CustomLogger logger,
  }) : logger = logger.scope('escrow-events');

  // ── Public entry point ────────────────────────────────────────────

  /// Scans historical + live event logs for the given [params].
  ///
  /// [ensureDeployed] is called once before the first RPC log fetch so that
  /// the caller can lazily deploy the contract if needed.
  StreamWithStatus<EscrowEvent> allEvents(
    ContractEventsParams params,
    EscrowServiceSelected? selectedEscrow, {
    bool includeLive = true,
    bool batch = true,
    required Future<void> Function() ensureDeployed,
  }) {
    return logger.spanSync('allEvents', () {
      final eventNamesByTopic = _eventNamesByTopic();
      final cachedTrade = params.tradeId != null
          ? _tradeEvents[params.tradeId!]
          : null;

      if (params.tradeId != null && cachedTrade?.isTerminal == true) {
        logger.d(
          'Returning cached terminal events for trade ${params.tradeId}',
        );
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
        'Subscribing to events for trade id at address: '
        '${params.tradeId}, ${contract.self.address}',
      );

      final cachedEvents = cachedTrade?.events ?? const <EscrowEvent>[];
      final logStore = <FilterEvent>[];

      return StreamWithStatus<EscrowEvent>.query(
        query: () async* {
          for (final event in cachedEvents) {
            yield event;
          }

          await ensureDeployed();
          final logs = await _getLogs(
            eventFilter,
            params: params,
            batch: batch,
          );
          logger.d(
            'Fetched ${logs.length} logs for filter: '
            '${eventFilter.stringify()}',
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
        live: includeLive
            ? () => _liveEvents(
                params,
                eventFilter,
                eventNamesByTopic,
                selectedEscrow,
                logStore,
                cachedHighestSeenBlock: cachedTrade?.highestSeenBlock,
              )
            : null,
      );
    });
  }

  // ── Live polling ──────────────────────────────────────────────────

  Stream<EscrowEvent> _liveEvents(
    ContractEventsParams params,
    FilterOptions eventFilter,
    Map<String, String> eventNamesByTopic,
    EscrowServiceSelected? selectedEscrow,
    List<FilterEvent> logStore, {
    int? cachedHighestSeenBlock,
  }) {
    final currentChain = chain;
    if (currentChain == null) {
      logger.w('No EvmChain available — live polling disabled');
      return const Stream.empty();
    }

    final tradeId = params.tradeId;
    if (tradeId != null) {
      return _liveTradeEvents(
        tradeId: tradeId,
        eventFilter: eventFilter,
        eventNamesByTopic: eventNamesByTopic,
        selectedEscrow: selectedEscrow,
        logStore: logStore,
        cachedHighestSeenBlock: cachedHighestSeenBlock,
      );
    }

    var lastQueried = _highestSeenBlock(
      logStore,
      cachedHighestSeenBlock: cachedHighestSeenBlock,
    );

    return currentChain.newBlocks().asyncExpand((block) async* {
      final fromBlock = lastQueried != null
          ? BlockNum.exact(lastQueried! + 1)
          : BlockNum.exact(block);

      final List<FilterEvent> logs;
      try {
        logs = await currentChain.getLogs(
          FilterOptions(
            address: eventFilter.address,
            topics: eventFilter.topics,
            fromBlock: fromBlock,
            toBlock: BlockNum.exact(block),
          ),
          batch: false,
        );
      } catch (error, stackTrace) {
        logger.w(
          'Live escrow event poll failed for block range $fromBlock..$block; '
          'will retry from the same block on the next poll: $error',
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }

      lastQueried = block;
      logStore.addAll(logs);

      for (final log in logs) {
        if (log.transactionHash == null) continue;
        try {
          yield await _mapAndCacheEscrowEvent(
            log,
            eventNamesByTopic,
            selectedEscrow,
          );
        } catch (error, stackTrace) {
          logger.w(
            'Failed to map live escrow event ${log.transactionHash}; '
            'will continue polling: $error',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    });
  }

  Stream<EscrowEvent> _liveTradeEvents({
    required String tradeId,
    required FilterOptions eventFilter,
    required Map<String, String> eventNamesByTopic,
    required EscrowServiceSelected? selectedEscrow,
    required List<FilterEvent> logStore,
    int? cachedHighestSeenBlock,
  }) {
    final currentChain = chain;
    if (currentChain == null) {
      logger.w('No EvmChain available — live trade polling disabled');
      return const Stream.empty();
    }

    late StreamController<EscrowEvent> controller;
    late _LiveTradeSubscription subscription;
    controller = StreamController<EscrowEvent>(
      onListen: () {
        subscription = _LiveTradeSubscription(
          tradeId: tradeId,
          tradeTopic: _tradeIdTopic(tradeId),
          eventFilter: eventFilter,
          eventNamesByTopic: eventNamesByTopic,
          selectedEscrow: selectedEscrow,
          logStore: logStore,
          controller: controller,
        );
        _liveTradeSubscriptions.add(subscription);

        final highestSeenBlock = _highestSeenBlock(
          logStore,
          cachedHighestSeenBlock: cachedHighestSeenBlock,
        );
        if (highestSeenBlock != null) {
          _liveTradeLastQueried = _liveTradeLastQueried == null
              ? highestSeenBlock
              : min(_liveTradeLastQueried!, highestSeenBlock);
        }

        _ensureLiveTradeBlockSubscription(currentChain);
      },
      onCancel: () {
        _liveTradeSubscriptions.remove(subscription);
        if (_liveTradeSubscriptions.isEmpty) {
          _liveTradeBlockSub?.cancel();
          _liveTradeBlockSub = null;
          _liveTradeLastQueried = null;
        }
      },
    );

    return controller.stream;
  }

  void _ensureLiveTradeBlockSubscription(EvmChain currentChain) {
    if (_liveTradeBlockSub != null) return;
    _liveTradeBlockSub = currentChain
        .newBlocks()
        .asyncMap((block) => _pollLiveTradeSubscriptions(currentChain, block))
        .listen(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            logger.w(
              'Live trade block subscription failed: $error',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  Future<void> _pollLiveTradeSubscriptions(
    EvmChain currentChain,
    int block,
  ) async {
    final subscriptions = List<_LiveTradeSubscription>.from(
      _liveTradeSubscriptions,
    );
    if (subscriptions.isEmpty) return;

    final fromBlock = _liveTradeLastQueried != null
        ? BlockNum.exact(_liveTradeLastQueried! + 1)
        : BlockNum.exact(block);
    final toBlock = BlockNum.exact(block);
    final eventTopics = subscriptions
        .expand((subscription) {
          final topics = subscription.eventFilter.topics;
          if (topics == null || topics.isEmpty) return const <String?>[];
          return topics.first;
        })
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final tradeTopics = subscriptions
        .map((subscription) => subscription.tradeTopic)
        .toSet()
        .toList(growable: false);

    final logs = <FilterEvent>[];
    try {
      for (final tradeTopicChunk in _chunks(
        tradeTopics,
        _maxLiveTradeTopicsPerGetLogs,
      )) {
        logs.addAll(
          await currentChain.getLogs(
            FilterOptions(
              address: contract.self.address,
              topics: [eventTopics, tradeTopicChunk],
              fromBlock: fromBlock,
              toBlock: toBlock,
            ),
            batch: false,
          ),
        );
      }
    } catch (error, stackTrace) {
      logger.w(
        'Live escrow trade poll failed for '
        '${subscriptions.length} subscription(s), '
        '${tradeTopics.length} trade topic(s), block range '
        '$fromBlock..$block; will retry from the same block: $error',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    _liveTradeLastQueried = block;

    for (final log in logs) {
      final logTopics = log.topics;
      if (log.transactionHash == null ||
          logTopics == null ||
          logTopics.length < 2) {
        continue;
      }
      final tradeTopic = logTopics[1];
      final targets = subscriptions.where(
        (subscription) => subscription.tradeTopic == tradeTopic,
      );
      for (final target in targets) {
        if (target.controller.isClosed || !target.markSeen(log)) continue;
        target.logStore.add(log);
        try {
          target.controller.add(
            await _mapAndCacheEscrowEvent(
              log,
              target.eventNamesByTopic,
              target.selectedEscrow,
            ),
          );
        } catch (error, stackTrace) {
          logger.w(
            'Failed to map live escrow event ${log.transactionHash}; '
            'will continue polling: $error',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }
  }

  Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
    for (var i = 0; i < values.length; i += size) {
      yield values.sublist(i, min(i + size, values.length));
    }
  }

  // ── Filter building ───────────────────────────────────────────────

  Map<String, String> _eventNamesByTopic() => {
    for (final name in _eventNames) _eventTopic(name): name,
  };

  FilterOptions _buildEventFilter(
    ContractEventsParams params,
    Iterable<String> eventTopics, {
    BlockNum? fromBlock,
  }) {
    // Solidity indexed topic layout:
    //   TradeCreated:                 [sig, tradeId, token, arbiter]
    //   Arbitrated/Claimed/Released:  [sig, tradeId, token]
    //
    // Only TradeCreated has `arbiter` indexed (at topic[3]).
    final hasArbiter = params.arbiterEvmAddress != null;
    final effectiveEventTopics = hasArbiter
        ? [_eventTopic('TradeCreated')]
        : [...eventTopics];

    final topics = <List<String?>>[effectiveEventTopics];

    if (params.tradeId != null) {
      topics.add([_tradeIdTopic(params.tradeId!)]);
    }
    if (hasArbiter) {
      if (params.tradeId == null) {
        topics.add([]); // topic[1]: wildcard for tradeId
      }
      topics.add([]); // topic[2]: wildcard for token
      topics.add([
        _indexedAddressTopic(params.arbiterEvmAddress!),
      ]); // topic[3]: arbiter
    }

    return FilterOptions(
      address: contract.self.address,
      topics: topics,
      fromBlock: fromBlock ?? const BlockNum.exact(0),
    );
  }

  // ── Log fetching ──────────────────────────────────────────────────

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

  BlockNum _effectiveFromBlock(CachedTradeEvents? cachedTrade) {
    if (cachedTrade?.highestSeenBlock == null) {
      return const BlockNum.exact(0);
    }
    return BlockNum.exact(cachedTrade!.highestSeenBlock! + 1);
  }

  // ── Event mapping ─────────────────────────────────────────────────

  Future<EscrowEvent> _mapEscrowEvent(
    FilterEvent log,
    Map<String, String> eventNamesByTopic,
    EscrowServiceSelected? selectedEscrow,
  ) async {
    final blockNum = _blockNumForLog(log);
    final txHash = log.transactionHash!;

    switch (eventNamesByTopic[log.topics?.first]) {
      case 'TradeCreated':
        final tradeCreated = TradeCreated(
          _decodeEvent('TradeCreated', log),
          log,
        );
        return EscrowFundedEvent(
          tradeId: bytesToHex(tradeCreated.tradeId),
          blockNum: blockNum,
          block: null,
          escrowService: selectedEscrow,
          chain: chain,
          contract: parentContract,
          transactionHash: txHash,
          amount: await _tokenAmountFromEvent(
            tradeCreated.token,
            tradeCreated.paymentAmount,
          ),
          bondAmount: tradeCreated.bondAmount > BigInt.zero
              ? await _tokenAmountFromEvent(
                  tradeCreated.token,
                  tradeCreated.bondAmount,
                )
              : null,
          unlockAt: tradeCreated.unlockAt.toInt(),
        );
      case 'Arbitrated':
        final arb = Arbitrated(_decodeEvent('Arbitrated', log), log);
        return EscrowArbitratedEvent(
          tradeId: bytesToHex(arb.tradeId),
          blockNum: blockNum,
          block: null,
          escrowService: selectedEscrow,
          chain: chain,
          contract: parentContract,
          transactionHash: txHash,
          paymentForwarded: arb.paymentFactor.toInt() / 1000,
          bondForwarded: arb.bondFactor.toInt() / 1000,
        );
      case 'ReleasedToCounterparty':
        final released = ReleasedToCounterparty(
          _decodeEvent('ReleasedToCounterparty', log),
          log,
        );
        return EscrowReleasedEvent(
          tradeId: bytesToHex(released.tradeId),
          blockNum: blockNum,
          block: null,
          escrowService: selectedEscrow,
          chain: chain,
          contract: parentContract,
          transactionHash: txHash,
        );
      case 'Claimed':
        final claimed = Claimed(_decodeEvent('Claimed', log), log);
        return EscrowClaimedEvent(
          tradeId: bytesToHex(claimed.tradeId),
          blockNum: blockNum,
          block: null,
          escrowService: selectedEscrow,
          chain: chain,
          contract: parentContract,
          transactionHash: txHash,
        );
      default:
        logger.w(
          'Unknown event found in allEvents stream: ${log.topics?.first}',
        );
        return UnknownEscrowEvent(
          tradeId: '',
          blockNum: blockNum,
          block: null,
          escrowService: selectedEscrow,
          chain: chain,
          contract: parentContract,
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

  // ── Event caching ─────────────────────────────────────────────────

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

    _tradeEvents[tradeId] = CachedTradeEvents(
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

  // ── Helpers ───────────────────────────────────────────────────────

  int _blockNumForLog(FilterEvent log) {
    final blockNum = log.blockNum;
    if (blockNum == null) {
      throw StateError(
        'Escrow log ${log.transactionHash} has no mined block number',
      );
    }
    return blockNum;
  }

  List<dynamic> _decodeEvent(String eventName, FilterEvent log) => contract
      .self
      .events
      .firstWhere((event) => event.name == eventName)
      .decodeResults(log.topics!, log.data!);

  int? _highestSeenBlock(
    List<FilterEvent> logStore, {
    int? cachedHighestSeenBlock,
  }) {
    var highestSeenBlock = cachedHighestSeenBlock;
    final blockNumbers = logStore
        .where((event) => event.blockNum != null)
        .map((event) => event.blockNum!.toInt());

    for (final blockNumber in blockNumbers) {
      highestSeenBlock = highestSeenBlock == null
          ? blockNumber
          : max(highestSeenBlock, blockNumber);
    }

    return highestSeenBlock;
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

  Future<TokenAmount> _tokenAmountFromEvent(
    EthereumAddress token,
    BigInt amount,
  ) async {
    final isNative =
        token.eip55With0x.toLowerCase() ==
        SupportedEscrowContract.zeroAddress.eip55With0x.toLowerCase();
    if (isNative) {
      return rbtcFromWei(amount, chainId: chain?.config.chainId);
    }
    final decimals = await chain?.resolveTokenDecimals(token.eip55With0x);
    if (decimals == null) {
      logger.e(
        'Could not resolve on-chain decimals for ERC-20 '
        '${token.eip55With0x} on chain ${chain?.config.chainId}. '
        'Falling back to 18 decimals — amounts may display incorrectly.',
      );
    }
    return tokenAmountFromEvm(
      token.eip55With0x,
      amount,
      chainId: chain?.config.chainId ?? 30,
      tokenDecimals: decimals,
    );
  }
}

class _LiveTradeSubscription {
  final String tradeId;
  final String tradeTopic;
  final FilterOptions eventFilter;
  final Map<String, String> eventNamesByTopic;
  final EscrowServiceSelected? selectedEscrow;
  final List<FilterEvent> logStore;
  final StreamController<EscrowEvent> controller;
  final Set<String> _seenLogs = {};

  _LiveTradeSubscription({
    required this.tradeId,
    required this.tradeTopic,
    required this.eventFilter,
    required this.eventNamesByTopic,
    required this.selectedEscrow,
    required this.logStore,
    required this.controller,
  }) {
    for (final log in logStore) {
      _seenLogs.add(_logIdentity(log));
    }
  }

  bool markSeen(FilterEvent log) => _seenLogs.add(_logIdentity(log));

  static String _logIdentity(FilterEvent log) {
    return [
      log.blockHash,
      log.transactionHash,
      log.logIndex,
      log.topics?.first,
    ].join(':');
  }
}

/// In-memory cache of decoded events for a single trade.
class CachedTradeEvents {
  final List<EscrowEvent> events;
  final int? highestSeenBlock;
  final bool isTerminal;

  const CachedTradeEvents({
    required this.events,
    required this.highestSeenBlock,
    required this.isTerminal,
  });
}

extension FilterOptionsStringify on FilterOptions {
  String stringify() =>
      'FilterOptions(address: ${address?.eip55With0x}, '
      'topics: $topics, fromBlock: $fromBlock, toBlock: $toBlock)';
}
