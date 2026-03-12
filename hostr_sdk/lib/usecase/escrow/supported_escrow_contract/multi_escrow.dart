import 'dart:math';

import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/escrow/MultiEscrow.g.dart';
import '../../../util/main.dart';
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
  MultiEscrowWrapper({
    required super.client,
    required super.address,
    super.rifRelay,
    required CustomLogger logger,
  }) : logger = logger.scope('multi-escrow'),
       super(
         contract: MultiEscrow(address: address, client: client),
         supportsClaimSwapAndFund: true,
       );

  @override
  ContractCallIntent fund(ContractFundEscrowParams params) =>
      logger.spanSync('fund', () {
        final (:tradeId, :buyer, :seller, :arbiter, :unlockAt, :escrowFee) =
            fundArgs(params);
        return buildIntent(
          functionName: 'createTrade',
          args: [tradeId, buyer, seller, arbiter, unlockAt, escrowFee],
          from: params.ethKey.address,
          methodName: 'createTrade',
          value: params.amount.toEtherAmount(),
          gasPrice: params.gasEstimate?.gasPrice,
          maxGas: params.gasEstimate?.gasLimit.toInt(),
        );
      });

  @override
  Future<ContractCallIntent> fundRelayed(
    ContractFundEscrowParams params,
  ) async => fund(params);

  @override
  ContractCallIntent claim(ContractClaimEscrowParams params) =>
      logger.spanSync('claim', () {
        return buildIntent(
          functionName: 'claim',
          args: [getBytes32(params.tradeId)],
          from: params.ethKey.address,
          methodName: 'claim',
        );
      });

  @override
  Future<ContractCallIntent> claimRelayed(ContractClaimEscrowParams params) =>
      logger.span('claimRelayed', () {
        return buildAuthorizedRelayIntent(
          tradeId: getBytes32(params.tradeId),
          ethKey: params.ethKey,
          authorizationHashFn: contract.hashClaimAuthorization,
          functionName: 'claim',
          methodName: 'claimRelayed',
        );
      });

  @override
  ContractCallIntent claimSwapAndFund(
    ContractClaimAndFundEscrowParams params,
  ) => logger.spanSync('claimAndFund', () {
    final sender = params.fundParams.ethKey.address;
    final estimatedMaxGas = params.fundParams.gasEstimate?.gasLimit.toInt();
    final claimAndFundMaxGas = estimatedMaxGas == null
        ? null
        : max(estimatedMaxGas * 2, 500000);
    logger.i(
      'claimAndFund sender=${sender.eip55With0x} '
      'buyer=${params.fundParams.ethKey.address.eip55With0x} '
      'seller=${params.fundParams.sellerEvmAddress} '
      'arbiter=${params.fundParams.arbiterEvmAddress} '
      'swapContract=${params.swapContract.eip55With0x} '
      'amount=${params.claimArgs.amount} '
      'gasPrice=${params.fundParams.gasEstimate?.gasPrice.getInWei} '
      'estimatedMaxGas=${params.fundParams.gasEstimate?.gasLimit} '
      'claimAndFundMaxGas=$claimAndFundMaxGas',
    );

    return buildIntent(
      functionName: 'claimSwapAndFund',
      args: [
        [
          params.swapContract,
          params.claimArgs.preimage,
          params.claimArgs.amount,
          params.claimArgs.refundAddress,
          params.claimArgs.timelock,
          params.claimArgs.v,
          params.claimArgs.r,
          params.claimArgs.s,
        ],
        [
          getBytes32(params.fundParams.tradeId),
          params.fundParams.ethKey.address,
          EthereumAddress.fromHex(params.fundParams.sellerEvmAddress),
          EthereumAddress.fromHex(params.fundParams.arbiterEvmAddress),
          BigInt.from(params.fundParams.unlockAt),
          params.fundParams.escrowFee?.getInWei ?? BigInt.zero,
        ],
      ],
      from: sender,
      methodName: 'claimSwapAndFund',
      gasPrice: params.fundParams.gasEstimate?.gasPrice,
      maxGas: claimAndFundMaxGas,
    );
  });

  @override
  Future<ContractCallIntent> claimSwapAndFundRelayed(
    ContractClaimAndFundEscrowParams params,
  ) async => claimSwapAndFund(params);

  @override
  ContractCallIntent arbitrate(ContractArbitrateParams params) =>
      logger.spanSync('arbitrate', () {
        final function = contract.self.abi.functions.firstWhere(
          (f) => f.name == 'arbitrate',
        );
        final (:tradeId, :factor) = arbitrateArgs(params);
        final data = function.encodeCall([tradeId, factor]);
        return ContractCallIntent(
          to: contract.self.address,
          data: data,
          value: EtherAmount.zero(),
          from: params.ethKey.address,
          methodName: 'arbitrate',
        );
      });

  @override
  ContractCallIntent release(ContractReleaseEscrowParams params) =>
      logger.spanSync('release', () {
        return buildIntent(
          functionName: 'releaseToCounterparty',
          args: [getBytes32(params.tradeId)],
          from: params.ethKey.address,
          methodName: 'releaseToCounterparty',
        );
      });

  @override
  Future<ContractCallIntent> releaseRelayed(
    ContractReleaseEscrowParams params,
  ) => logger.span('releaseRelayed', () {
    return buildAuthorizedRelayIntent(
      tradeId: getBytes32(params.tradeId),
      ethKey: params.ethKey,
      authorizationHashFn: contract.hashReleaseAuthorization,
      functionName: 'releaseToCounterparty',
      methodName: 'releaseToCounterpartyRelayed',
    );
  });

  @override
  fundArgs(ContractFundEscrowParams params) =>
      logger.spanSync('depositArgs', () {
        return (
          tradeId: getBytes32(params.tradeId),

          /// Our address derived from our nostr private key
          buyer: params.ethKey.address,

          /// Seller address derived from their nostr pubkey
          seller: EthereumAddress.fromHex(params.sellerEvmAddress),

          /// Arbiter public key from their nostr advertisement
          arbiter: EthereumAddress.fromHex(params.arbiterEvmAddress),

          unlockAt: BigInt.from(params.unlockAt),
          escrowFee: params.escrowFee?.getInWei ?? BigInt.zero,
        );
      });

  @override
  arbitrateArgs(ContractArbitrateParams params) =>
      logger.spanSync('arbitrateArgs', () {
        final scaledForward = BigInt.from((params.forward * 1000).round());
        return (tradeId: getBytes32(params.tradeId), factor: scaledForward);
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
  Future<bool> canClaim(ContractClaimEscrowParams params) =>
      logger.span('canClaim', () async {
        await ensureDeployed();
        final activeTrade = await _withDecodedCustomError(() {
          return contract.activeTrade((tradeId: getBytes32(params.tradeId)));
        });

        if (!activeTrade.isActive) {
          return false;
        }

        final trade = _extractTrade(activeTrade.trade);
        if (trade == null) {
          logger.w('Could not decode active trade for ${params.tradeId}');
          return false;
        }

        return DateTime.now().millisecondsSinceEpoch ~/ 1000 >
            trade.unlockAt.toInt();
      });

  @override
  Future<bool> canRelease(ContractReleaseEscrowParams params) =>
      logger.span('canRelease', () async {
        await ensureDeployed();
        final activeTrade = await _withDecodedCustomError(() {
          return contract.activeTrade((tradeId: getBytes32(params.tradeId)));
        });

        if (!activeTrade.isActive) {
          return false;
        }

        final trade = _extractTrade(activeTrade.trade);
        if (trade == null) {
          logger.w('Could not decode active trade for ${params.tradeId}');
          return false;
        }

        final actor = params.ethKey.address;
        return actor == trade.buyer || actor == trade.seller;
      });

  @override
  StreamWithStatus<EscrowEvent> allEvents(
    ContractEventsParams params,
    EscrowServiceSelected? selectedEscrow, {
    bool includeLive = true,
  }) => logger.spanSync('allEvents', () {
    final eventNamesByTopic = _eventNamesByTopic();
    final eventFilter = _buildEventFilter(params, eventNamesByTopic.keys);
    logger.d(
      'Subscribing to events for trade id at address: ${params.tradeId}, ${contract.self.address}',
    );

    final logStore = <FilterEvent>[];

    return StreamWithStatus<EscrowEvent>.query(
      query: () => ensureDeployed()
          .then((_) => contract.client.getLogs(eventFilter))
          .asStream()
          .doOnData((logs) {
            logger.d(
              'Fetched ${logs.length} logs for filter: ${eventFilter.stringify()}',
            );
            logStore.addAll(logs);
          })
          .asyncExpand((logs) => Stream.fromIterable(logs))
          .where((log) => log.transactionHash != null)
          .asyncMap(
            (log) => _mapEscrowEvent(log, eventNamesByTopic, selectedEscrow),
          ),
      live: includeLive == true
          ? () => contract.client
                .events(
                  FilterOptions(
                    address: eventFilter.address,
                    topics: eventFilter.topics,
                    fromBlock: _nextLiveBlock(logStore),
                  ),
                )
                .where((log) => log.transactionHash != null)
                .asyncMap(
                  (log) =>
                      _mapEscrowEvent(log, eventNamesByTopic, selectedEscrow),
                )
          : null,
    );
  });

  Map<String, String> _eventNamesByTopic() => {
    for (final name in _eventNames) _eventTopic(name): name,
  };

  FilterOptions _buildEventFilter(
    ContractEventsParams params,
    Iterable<String> eventTopics,
  ) {
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
      fromBlock: BlockNum.genesis(),
    );
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

  BlockNum _nextLiveBlock(List<FilterEvent> logStore) {
    final blockNumbers = logStore
        .where((event) => event.blockNum != null)
        .map((event) => event.blockNum!.toInt());
    if (blockNumbers.isEmpty) {
      return BlockNum.current();
    }
    return BlockNum.exact(blockNumbers.reduce(max) + 1);
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

extension on FilterOptions {
  String stringify() {
    return 'FilterOptions(address: ${address?.eip55With0x}, topics: $topics, fromBlock: $fromBlock, toBlock: $toBlock)';
  }
}
