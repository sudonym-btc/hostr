import 'dart:typed_data';

import 'package:hostr/core/util/main.dart';
import 'package:hostr/data/sources/escrow/MultiEscrow.g.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../auth/auth.dart';
import '../escrows/escrows.dart';
import '../evm/evm_chain.dart';
import 'constants.dart';

class PaymentEscrow {
  final CustomLogger logger = CustomLogger();
  final Auth auth;
  final Escrows escrows;

  PaymentEscrow({required this.auth, required this.escrows});

  listEvents({required EvmChain evmChain, required Escrow escrow}) async {
    MultiEscrow e = MultiEscrow(
      address: EthereumAddress.fromHex(escrow.parsedContent.contractAddress),
      client: evmChain.client,
    );
    // List past events
    final filter = FilterOptions.events(
      contract: e.self,
      event: e.self.events.firstWhere((x) => x.name == 'DebugLog'),
      fromBlock: BlockNum.exact(449),
      toBlock: BlockNum.current(),
    );

    final logs = await evmChain.client.getLogs(filter);
    for (var log in logs) {
      // logger.i('Past Trade created: $log');
    }

    // e.tradeCreatedEvents(fromBlock: BlockNum.genesis()).listen((event) {
    //   logger.i('Trade created: $event');
    // });
  }

  Future<void> escrow({
    required String eventId,
    required Amount amount,
    required String sellerEvmAddress,
    required String escrowEvmAddress,
    required String escrowContractAddress,
    required int timelock,
    required EvmChain evmChain,
  }) async {
    KeyPair key = auth.activeKeyPair!;
    EthPrivateKey ethKey = getEvmCredentials(key.privateKey!);

    MultiEscrow e = MultiEscrow(
      address: EthereumAddress.fromHex(escrowContractAddress),
      client: evmChain.client,
    );
    var tuple = (
      tradeId: getBytes32(eventId),
      timelock: BigInt.from(timelock),

      /// Arbiter public key from their nostr advertisement
      arbiter: EthereumAddress.fromHex(escrowEvmAddress),

      /// Seller address derived from their nostr pubkey
      seller: EthereumAddress.fromHex(sellerEvmAddress),

      /// Our address derived from our nostr private key
      buyer: ethKey.address,
      escrowFee: BigInt.from(100),
    );
    logger.i('Creating escrow for $eventId');
    logger.i(tuple);
    String escrowTx = await e.createTrade(
      tuple,
      credentials: ethKey,
      transaction: Transaction(
        value: EtherAmount.fromBigInt(
          EtherUnit.wei,
          BigInt.from(amount.value * btcSatoshiFactor) * satoshiWeiFactor,
        ),
      ),
    );

    final receipt = await evmChain.client.getTransactionReceipt(escrowTx);
    logger.i(receipt);
  }

  Stream<TradeCreated> checkEscrowStatus(
    String reservationRequestId, {
    required EvmChain evmChain,
  }) async* {
    logger.i('Checking escrow status for reservation: $reservationRequestId');
    Uint8List idBytes32 = getBytes32(reservationRequestId);
    String hexTopic = getTopicHex(idBytes32);

    Nip51List? trustedEscrows = await escrows.trusted(
      auth.activeKeyPair?.publicKey,
    );
    if (trustedEscrows == null) {
      return;
    }
    for (Nip51ListElement item in trustedEscrows.elements) {
      List<Escrow> escrowServices = await escrows.list(
        Filter(authors: [item.value]),
      );
      for (var escrow in escrowServices) {
        logger.i(
          'Searching for events from escrow: ${escrow.parsedContent.contractAddress}',
        );
        MultiEscrow e = MultiEscrow(
          address: EthereumAddress.fromHex(
            escrow.parsedContent.contractAddress,
          ),
          client: evmChain.client,
        );

        Trades x = await e.trades(($param9: idBytes32));
        logger.i('Current trade: $x');
        final tradeCreatedEvent = e.self.events.firstWhere(
          (x) => x.name == 'TradeCreated',
        );
        final sig = bytesToHex(
          tradeCreatedEvent.signature,
          padToEvenLength: true,
          include0x: true,
        );
        logger.i('Log sig $sig');
        final filter = FilterOptions(
          topics: [
            [
              // TODO include other event type signatures
              sig,
            ], // Topic 0: event signature.
            // Topic 1: tradeId indexed parameter.
            [hexTopic],
          ],
          fromBlock: BlockNum.exact(0),
          toBlock: BlockNum.exact(await evmChain.client.getBlockNumber()),
        );

        final logs = await evmChain.client.getLogs(filter);
        logger.i('Filtered logs: ${logs.length} for hexTopic $hexTopic');

        final tradeCreated = logs.map((FilterEvent result) {
          logger.i('trade log topics: ${result.topics}');
          final decoded = tradeCreatedEvent.decodeResults(
            result.topics!,
            result.data!,
          );
          return TradeCreated(decoded, result);
        }).toList();
        logger.i('Decoded ${tradeCreated.length} TradeCreated events');
      }
    }
  }
}
