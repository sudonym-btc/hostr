import 'dart:typed_data';

import 'package:hostr/core/util/main.dart';
import 'package:hostr/data/sources/escrow/MultiEscrow.g.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow/escrow_cubit.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow_trusts/escrows_trusts.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../auth/auth.dart';
import '../escrows/escrows.dart';
import '../evm/evm.dart';
import '../evm/evm_chain.dart';
import '../payments/constants.dart';

@Singleton()
class EscrowUseCase {
  final CustomLogger logger = CustomLogger();
  final Auth auth;
  final Escrows escrows;
  final EscrowTrusts escrowTrusts;
  final Evm evm;

  EscrowUseCase({
    required this.auth,
    required this.escrows,
    required this.escrowTrusts,
    required this.evm,
  });

  EscrowCubit escrow(EscrowCubitParams params) {
    return EscrowCubit(params);
  }

  Stream<TradeCreated> checkEscrowStatus(
    String tradeId,
    String counterpartyPubkey,
  ) async* {
    logger.i('Checking escrow status for reservation: $tradeId');
    Uint8List idBytes32 = getBytes32(tradeId);
    // logger.d(reservationRequestId);
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
        final chainId = await evmChain.client.getChainId();
        final code = await evmChain.client.getCode(a);
        final balance = await evmChain.client.getBalance(a);
        // logger.d('EVM chainId: $chainId');
        // logger.d('Contract code length: ${code.length}');
        // logger.d(
        //   'Contract balance: ${balance.getValueInUnit(EtherUnit.ether)}',
        // );
        if (code.isEmpty || code == '0x') {
          logger.w('No contract code at ${a.eip55With0x}; skipping.');
          continue;
        }
        MultiEscrow e = MultiEscrow(address: a, client: evmChain.client);
        // Trades x = await e.trades(($param9: idBytes32));
        // logger.i('Current trade: $x');
        final tradeCreatedEvent = e.self.events.firstWhere(
          (x) => x.name == 'TradeCreated',
        );
        final sig = bytesToHex(
          tradeCreatedEvent.signature,
          padToEvenLength: true,
          include0x: true,
        );
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

        // listEvents(evmChain: evmChain, escrow: escrow);

        final logs = await evmChain.client.getLogs(filter);
        // logger.i('Filtered logs: ${logs.length} for hexTopic $hexTopic');

        final tradeCreated = logs.map((FilterEvent result) {
          logger.i('trade log topics: ${result}');
          final decoded = tradeCreatedEvent.decodeResults(
            result.topics!,
            result.data!,
          );
          return TradeCreated(decoded, result);
        }).toList();
        logger.i('Decoded ${tradeCreated.length} TradeCreated events');
        for (var trade in tradeCreated) {
          yield trade;
        }
        yield* e
            .tradeCreatedEvents(
              fromBlock: logs.isEmpty
                  ? BlockNum.current()
                  : BlockNum.exact(
                      logs
                          .reduce(
                            (value, element) =>
                                value.blockNum!.toInt() <
                                    element.blockNum!.toInt()
                                ? value
                                : element,
                          )
                          .blockNum!,
                    ),
            )
            .doOnError((error, stackTrace) {
              logger.e(
                'TradeCreated stream error',
                error: error,
                stackTrace: stackTrace,
              );
            })
            .doOnDone(() {
              logger.w('TradeCreated stream closed');
            })
            .where((event) {
              return bytesToHex(event.tradeId, padToEvenLength: true) ==
                  hexTopic;
            });
      }
    }
  }
}
