import 'dart:math';

import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/escrow/MultiEscrow.g.dart';
import '../../../util/main.dart';
import '../../payments/constants.dart';
import 'supported_escrow_contract.dart';

class MultiEscrowWrapper extends SupportedEscrowContract<MultiEscrow> {
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
    String transactionHash = await contract.createTrade(
      depositArgs(params),
      credentials: params.ethKey,
      transaction: Transaction(value: params.amount.toEtherAmount()),
    );
    return (await client.getTransactionByHash(
      transactionHash,
    ))!; // @todo awaitTransaction should really be added to web3dart client directly, instead of EvmChain class
  }

  @override
  arbitrate(ContractArbitrateParams params) async {
    return await contract.arbitrate(
      arbitrateArgs(params),
      credentials: params.ethKey,
    );
  }

  @override
  Future<BitcoinAmount> estimateDespositFee(
    ContractFundEscrowParams params,
  ) async {
    // We cannot estimateGas, because it'll error if the sender doesn't have enough balance.
    // final function = contract.self.function('createTrade');
    // final (:tradeId, :buyer, :seller, :arbiter, :timelock, :escrowFee) =
    //     depositArgs(params);
    // final args = [tradeId, buyer, seller, arbiter, timelock, escrowFee];
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
  depositArgs(ContractFundEscrowParams params) {
    return (
      tradeId: getBytes32(params.tradeId),

      /// Our address derived from our nostr private key
      buyer: params.ethKey.address,

      /// Seller address derived from their nostr pubkey
      seller: EthereumAddress.fromHex(params.sellerEvmAddress),

      /// Arbiter public key from their nostr advertisement
      arbiter: EthereumAddress.fromHex(params.arbiterEvmAddress),

      // @todo: calculate from current time and reservationRequest.end
      timelock: BigInt.from(params.timelock),
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
    logger.d('Subscribing to events for : $params');
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
            receipt!.value.getInWei,
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
      queryFn: () => contract.client
          .getLogs(eventFilter)
          .then((logs) {
            logStore.addAll(logs);
            return logs;
          })
          .asStream()
          .asyncExpand((logs) => Stream.fromIterable(logs))
          .where((log) => log.transactionHash != null)
          .asyncMap(mapper),
      liveFn: () => contract.client
          .events(
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
}
