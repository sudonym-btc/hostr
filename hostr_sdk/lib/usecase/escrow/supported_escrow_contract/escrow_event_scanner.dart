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

    var lastQueried = _highestSeenBlock(
      logStore,
      cachedHighestSeenBlock: cachedHighestSeenBlock,
    );

    return currentChain.newBlocks().asyncExpand((block) async* {
      final fromBlock = lastQueried != null
          ? BlockNum.exact(lastQueried! + 1)
          : BlockNum.exact(block);

      final logs = await currentChain.getLogs(
        FilterOptions(
          address: eventFilter.address,
          topics: eventFilter.topics,
          fromBlock: fromBlock,
          toBlock: BlockNum.exact(block),
        ),
        batch: false,
      );

      lastQueried = block;
      logStore.addAll(logs);

      for (final log in logs) {
        if (log.transactionHash == null) continue;
        yield await _mapAndCacheEscrowEvent(
          log,
          eventNamesByTopic,
          selectedEscrow,
        );
      }
    });
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
    final block = await _blockForLog(log);
    final txHash = log.transactionHash!;

    switch (eventNamesByTopic[log.topics?.first]) {
      case 'TradeCreated':
        final tradeCreated = TradeCreated(
          _decodeEvent('TradeCreated', log),
          log,
        );
        return EscrowFundedEvent(
          tradeId: bytesToHex(tradeCreated.tradeId),
          block: block,
          escrowService: selectedEscrow,
          chain: chain,
          contract: parentContract,
          transactionHash: txHash,
          amount: await _tokenAmountFromEvent(
            tradeCreated.token,
            tradeCreated.amount,
          ),
          unlockAt: tradeCreated.unlockAt.toInt(),
        );
      case 'Arbitrated':
        final arb = Arbitrated(_decodeEvent('Arbitrated', log), log);
        return EscrowArbitratedEvent(
          tradeId: bytesToHex(arb.tradeId),
          block: block,
          escrowService: selectedEscrow,
          chain: chain,
          contract: parentContract,
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
          chain: chain,
          contract: parentContract,
          transactionHash: txHash,
        );
      case 'Claimed':
        final claimed = Claimed(_decodeEvent('Claimed', log), log);
        return EscrowClaimedEvent(
          tradeId: bytesToHex(claimed.tradeId),
          block: block,
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
          block: block,
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

  Future<BlockInformation> _blockForLog(FilterEvent log) async {
    final receipt = await contract.client.getTransactionByHash(
      log.transactionHash!,
    );
    return contract.client.getBlockInformation(
      blockNumber: receipt!.blockNumber.toBlockParam(),
    );
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
      return rbtcFromWei(amount);
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
