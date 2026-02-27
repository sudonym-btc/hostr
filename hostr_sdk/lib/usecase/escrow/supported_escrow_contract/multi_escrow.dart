import 'dart:math';

import 'package:models/main.dart';
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
  };

  final CustomLogger logger;
  MultiEscrowWrapper({
    required super.client,
    required super.address,
    required this.logger,
  }) : super(
         contract: MultiEscrow(address: address, client: client),
       );

  @override
  Future<TransactionInformation> deposit(
    ContractFundEscrowParams params,
  ) async {
    await ensureDeployed();
    String transactionHash = await _withDecodedCustomError(() {
      return contract.createTrade(
        depositArgs(params),
        credentials: params.ethKey,
        transaction: Transaction(value: params.amount.toEtherAmount()),
      );
    });
    return (await client.getTransactionByHash(
      transactionHash,
    ))!; // @todo awaitTransaction should really be added to web3dart client directly, instead of EvmChain class
  }

  @override
  Future<OnChainTrade?> getTrade(String tradeId) async {
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
  }

  @override
  Future<bool> canClaim(ContractClaimEscrowParams params) async {
    await ensureDeployed();
    final activeTrade = await _withDecodedCustomError(() {
      return contract.activeTrade((tradeId: getBytes32(params.tradeId)));
    });

    print('Active trade for ${params.tradeId}: $activeTrade');

    if (!activeTrade.isActive) {
      return false;
    }

    final trade = _extractTrade(activeTrade.trade);
    print('Decoded trade: $trade');
    if (trade == null) {
      logger.w('Could not decode active trade for ${params.tradeId}');
      return false;
    }

    print(
      'trade unlockAt: ${trade.unlockAt}, current time: ${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    );

    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >
        trade.unlockAt.toInt();
  }

  @override
  Future<TransactionInformation> claim(ContractClaimEscrowParams params) async {
    await ensureDeployed();
    final transactionHash = await _withDecodedCustomError(() {
      return contract.claim((
        tradeId: getBytes32(params.tradeId),
      ), credentials: params.ethKey);
    });
    return (await client.getTransactionByHash(transactionHash))!;
  }

  @override
  arbitrate(ContractArbitrateParams params) async {
    await ensureDeployed();
    return await _withDecodedCustomError(() {
      return contract.arbitrate(
        arbitrateArgs(params),
        credentials: params.ethKey,
      );
    });
  }

  @override
  Future<BitcoinAmount> estimateDespositFee(
    ContractFundEscrowParams params,
  ) async {
    // We cannot estimateGas, because it'll error if the sender doesn't have enough balance.
    // final function = contract.self.function('createTrade');
    // final (:tradeId, :buyer, :seller, :arbiter, :unlockAt, :escrowFee) =
    //     depositArgs(params);
    // final args = [tradeId, buyer, seller, arbiter, unlockAt, escrowFee];
    // final gasLimit = await contract.client.estimateGas(
    //   sender: params.ethKey.address,
    //   to: contract.self.address,
    //   data: function.encodeCall(args),
    //   value: EtherAmount.fromInt(EtherUnit.wei, 0),
    // );
    final gasPrice = await contract.client.getGasPrice();
    final gasLimit = BigInt.from(200000);
    final feeWei = gasPrice.getInWei * gasLimit;
    return BitcoinAmount.inWei(feeWei);
  }

  @override
  Future<BitcoinAmount> estimateClaimFee(
    ContractClaimEscrowParams params,
  ) async {
    final gasPrice = await contract.client.getGasPrice();
    final gasLimit = BigInt.from(200000);
    final feeWei = gasPrice.getInWei * gasLimit;
    return BitcoinAmount.inWei(feeWei);
  }

  @override
  depositArgs(ContractFundEscrowParams params) {
    return (
      tradeId: getBytes32(params.tradeId),

      /// Our address derived from our nostr private key
      buyer: params.ethKey.address,

      /// Seller address derived from their nostr pubkey
      seller: EthereumAddress.fromHex(params.sellerEvmAddress),

      /// Arbiter public key from their nostr advertisement
      arbiter: EthereumAddress.fromHex(params.arbiterEvmAddress),

      unlockAt: BigInt.from(params.unlockAt),
      escrowFee: BigInt.from(params.escrowFee ?? 0),
    );
  }

  @override
  arbitrateArgs(ContractArbitrateParams params) {
    final scaledForward = BigInt.from((params.forward * 1000).round());
    return (tradeId: getBytes32(params.tradeId), factor: scaledForward);
  }

  @override
  StreamWithStatus<EscrowEvent> allEvents(
    ContractEventsParams params,
    EscrowServiceSelected? selectedEscrow,
  ) {
    logger.d(
      'Subscribing to events for trade id at address: ${params.tradeId}, ${contract.self.address}',
    );
    final List<String> eventNames = [
      'TradeCreated',
      'Arbitrated',
      'Claimed',
      'ReleasedToCounterparty',
    ];
    final Map<String, String> eventToSignature = {};

    for (final e in eventNames) {
      final event = contract.self.events.firstWhere((x) => x.name == e);
      eventToSignature[e] = bytesToHex(
        event.signature,
        padToEvenLength: true,
        include0x: true,
      );
    }

    String indexedAddressTopic(EthereumAddress address) {
      return '0x${address.without0x.padLeft(64, '0')}';
    }

    final List<List<String?>> topics = [
      [...eventToSignature.values],
    ];
    if (params.tradeId != null) {
      topics.add([
        bytesToHex(
          getBytes32(params.tradeId!),
          padToEvenLength: true,
          include0x: true,
        ),
      ]);
    }
    if (params.arbiterEvmAddress != null) {
      if (params.tradeId == null) {
        // Wildcard topic1 so topic2 can match arbiter.
        topics.add([]);
      }
      topics.add([indexedAddressTopic(params.arbiterEvmAddress!)]);
    }

    final eventFilter = FilterOptions(
      address: contract.self.address,
      topics: topics,
      fromBlock: BlockNum.genesis(),
    );

    List<FilterEvent> logStore = [];
    Future<EscrowEvent> mapper(FilterEvent log) async {
      final receipt = await contract.client.getTransactionByHash(
        log.transactionHash!,
      );
      final block = await contract.client.getBlockInformation(
        blockNumber: receipt!.blockNumber.toString(),
      );
      if (log.topics![0] == eventToSignature['TradeCreated']) {
        final decoded = contract.self.events
            .firstWhere((e) => e.name == 'TradeCreated')
            .decodeResults(log.topics!, log.data!);

        return EscrowFundedEvent(
          tradeId: bytesToHex(TradeCreated(decoded, log).tradeId),
          block: block,
          escrowService: selectedEscrow,
          transactionHash: log.transactionHash!,
          amount: BitcoinAmount.fromBigInt(
            BitcoinUnit.wei,
            receipt.value.getInWei,
          ),
        ); // @todo: return TradeCreatedEvent with decoded params
      } else if (log.topics![0] == eventToSignature['Arbitrated']) {
        final decoded = contract.self.events
            .firstWhere((e) => e.name == 'Arbitrated')
            .decodeResults(log.topics!, log.data!);
        return EscrowArbitratedEvent(
          block: block,
          escrowService: selectedEscrow,
          transactionHash: log.transactionHash!,
          forwarded: Arbitrated(decoded, log).fractionForwarded.toInt() / 1000,
        );
      } else if (log.topics![0] == eventToSignature['ReleasedToCounterparty']) {
        return EscrowReleasedEvent(
          block: block,
          escrowService: selectedEscrow,
          transactionHash: log.transactionHash!,
        );
      } else if (log.topics![0] == eventToSignature['Claimed']) {
        return EscrowClaimedEvent(
          block: block,
          escrowService: selectedEscrow,
          transactionHash: log.transactionHash!,
        );
      } else {
        logger.w('Unknown event found in allEvents stream: ${log.topics![0]}');
        return UnknownEscrowEvent(block: block, escrowService: selectedEscrow);
      }
    }

    return StreamWithStatus<EscrowEvent>(
      queryFn: () => ensureDeployed()
          .then((_) => contract.client.getLogs(eventFilter))
          .asStream()
          .map((logs) {
            print('Fetched ${logs.length} logs for filter: $eventFilter');
            logStore.addAll(logs);
            return logs;
          })
          .asyncExpand((logs) => Stream.fromIterable(logs))
          .where((log) => log.transactionHash != null)
          .asyncMap(mapper),
      liveFn: () => ensureDeployed()
          .asStream()
          .asyncExpand(
            (_) => contract.client.events(
              FilterOptions(
                address: eventFilter.address,
                topics: eventFilter.topics,
                fromBlock: logStore.isEmpty
                    ? BlockNum.current()
                    : BlockNum.exact(
                        logStore
                                .where((e) => e.blockNum != null)
                                .map((e) => e.blockNum!.toInt())
                                .reduce(max) +
                            1,
                      ),
              ),
            ),
          )
          .where((log) => log.transactionHash != null)
          .asyncMap(mapper),
    );
  }

  @override
  listTrades(ContractListTradesParams params) {
    // TODO: implement listTrades
    throw UnimplementedError();
  }

  Trades? _extractTrade(dynamic trade) {
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
  }

  Future<T> _withDecodedCustomError<T>(Future<T> Function() action) async {
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
  }

  MultiEscrowContractException? _decodeCustomError(Object error) {
    final text = error.toString();
    final match = RegExp(
      r'custom error\s*:??\s*(0x[a-fA-F0-9]{8})',
      caseSensitive: false,
    ).firstMatch(text);

    if (match == null) {
      return null;
    }

    final selector = match.group(1)!.toLowerCase();
    final errorName = _customErrorSelectors[selector] ?? 'UnknownCustomError';
    return MultiEscrowContractException(
      selector: selector,
      errorName: errorName,
      message: text,
      originalError: error,
    );
  }
}
