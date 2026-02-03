import 'dart:typed_data';

import 'package:hostr/core/util/main.dart';
import 'package:hostr/data/sources/escrow/MultiEscrow.g.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow_trusts/escrows_trusts.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../auth/auth.dart';
import '../escrows/escrows.dart';
import '../evm/evm.dart';
import '../evm/evm_chain.dart';
import 'constants.dart';

@Singleton()
class PaymentEscrow {
  final CustomLogger logger = CustomLogger();
  final Auth auth;
  final Escrows escrows;
  final EscrowTrusts escrowTrusts;
  final Evm evm;

  PaymentEscrow({
    required this.auth,
    required this.escrows,
    required this.escrowTrusts,
    required this.evm,
  });

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

  Future<String> escrow({
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
    logger.i('Creating escrow for $eventId at $escrowContractAddress');
    logger.i(tuple);
    final balance = await evmChain.client.getBalance(ethKey.address);
    logger.i(
      'Escrow sender balance: ${balance.getValueInUnit(EtherUnit.ether)} RBTC',
    );
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

    // final receipt = await evmChain.client.getTransactionReceipt(escrowTx);
    logger.i(escrowTx);
    return escrowTx;
  }

  Stream<TradeCreated> checkEscrowStatus(
    String reservationRequestId,
    String counterpartyPubkey,
  ) async* {
    logger.i('Checking escrow status for reservation: $reservationRequestId');
    Uint8List idBytes32 = getBytes32(reservationRequestId);
    logger.d(reservationRequestId);
    logger.d('idBytes32: ${idBytes32.length} bytes');
    String hexTopic = getTopicHex(idBytes32);

    EscrowTrust? myTrustedEscrows = await escrowTrusts.trusted(
      auth.activeKeyPair!.publicKey,
    );
    EscrowTrust? theirTrustedEscrows = await escrowTrusts.trusted(
      counterpartyPubkey,
    );

    final myTrustedList = myTrustedEscrows == null
        ? null
        : await myTrustedEscrows.toNip51List();
    final theirTrustedList = theirTrustedEscrows == null
        ? null
        : await theirTrustedEscrows.toNip51List();

    List<Nip51ListElement> trustedEscrows = [
      ...myTrustedList?.elements ?? [],
      ...theirTrustedList?.elements ?? [],
    ];

    logger.d('Trusted escrows: $trustedEscrows');

    if (trustedEscrows.isEmpty) {
      logger.w('No trusted escrows for either party.');
      return;
    }
    for (Nip51ListElement item in trustedEscrows) {
      List<Escrow> escrowServices = await escrows.list(
        Filter(authors: [item.value]),
      );
      for (var escrow in escrowServices) {
        EvmChain? evmChain;
        for (EvmChain chain in evm.supportedEvmChains) {
          BigInt chainId = await chain.getChainId();
          if (chainId.toInt() == escrow.parsedContent.chainId) {
            evmChain = chain;
            break;
          }
        }
        if (evmChain == null) {
          logger.w(
            'No supported EVM chain found for escrow: ${escrow.parsedContent.contractAddress} on chainId: ${escrow.parsedContent.chainId}',
          );
          continue;
        }
        logger.i(
          'Searching for events from escrow: ${escrow.parsedContent.contractAddress}',
        );

        EthereumAddress a = EthereumAddress.fromHex(
          escrow.parsedContent.contractAddress,
        );
        print('parsed address ${a.eip55With0x}');
        final chainId = await evmChain.client.getChainId();
        final code = await evmChain.client.getCode(a);
        final balance = await evmChain.client.getBalance(a);
        logger.d('EVM chainId: $chainId');
        logger.d('Contract code length: ${code.length}');
        logger.d(
          'Contract balance: ${balance.getValueInUnit(EtherUnit.ether)}',
        );
        if (code.isEmpty || code == '0x') {
          logger.w('No contract code at ${a.eip55With0x}; skipping.');
          continue;
        }
        MultiEscrow e = MultiEscrow(address: a, client: evmChain.client);
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
