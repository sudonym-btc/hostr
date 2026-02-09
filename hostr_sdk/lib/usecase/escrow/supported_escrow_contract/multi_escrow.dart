import 'dart:math';

import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/escrow/MultiEscrow.g.dart';
import '../../../util/main.dart';
import '../../payments/constants.dart';
import 'supported_escrow_contract.dart';

class MultiEscrowWrapper extends SupportedEscrowContract<MultiEscrow> {
  CustomLogger logger = CustomLogger();
  MultiEscrowWrapper({required super.client, required super.address})
    : super(
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
  StreamWithStatus<FundedEvent> fundedEvents(String tradeId) {
    final tradeCreatedEvent = contract.self.events.firstWhere(
      (x) => x.name == 'TradeCreated',
    );
    final eventFilter = FilterOptions.events(
      contract: contract.self,
      event: tradeCreatedEvent,
      fromBlock: BlockNum.genesis(),
    );
    eventFilter.topics!.add([
      bytesToHex(getBytes32(tradeId), padToEvenLength: true, include0x: true),
    ]);

    List<FilterEvent> logStore = [];

    return StreamWithStatus<FundedEvent>(
      queryFn: () => contract.client
          .getLogs(eventFilter)
          .then((logs) {
            logStore = logs;
            return logs;
          })
          .asStream()
          .asyncExpand((logs) => Stream.fromIterable(logs))
          .where((log) => log.transactionHash != null)
          .map((log) => FundedEvent(transactionHash: log.transactionHash!)),
      liveFn: () => contract.client
          .events(
            FilterOptions(
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
          .map((log) => FundedEvent(transactionHash: log.transactionHash!)),
    );

    // To map a log into the relevant event:
    // .map((FilterEvent result) {
    // final decoded = tradeCreatedEvent.decodeResults(
    //   result.topics!,
    //   result.data!,
    // );
    // return TradeCreated(decoded, result);
    // });
  }
}
