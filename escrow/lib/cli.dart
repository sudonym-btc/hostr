import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:web3dart/web3dart.dart';

import 'contracts/MultiEscrow.g.dart';

void main(List<String> arguments) async {
  final String relayUrl =
      Platform.environment['NOSTR_RELAY'] ?? 'ws://relay.hostr.development';
  final String privateKey =
      Platform.environment['PRIVATE_KEY'] ?? MockKeys.escrow.privateKey!;
  final String rpcUrl =
      Platform.environment['RPC_URL'] ?? 'http://localhost:8545';
  final String contractAddress = Platform.environment['CONTRACT_ADDR'] ??
      '0x7a2088a1bFc9d81c55368AE168C2C02570cB814F';
  Web3Client _web3client = Web3Client(rpcUrl, http.Client());
  MultiEscrow multiEscrow = MultiEscrow(
      address: EthereumAddress.fromHex(contractAddress), client: _web3client);

  Ndk ndk = Ndk(NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      engine: NdkEngine.JIT,
      defaultQueryTimeout: Duration(seconds: 10),
      bootstrapRelays: [relayUrl]));

  KeyPair keyPair = Bip340.fromPrivateKey(privateKey);

  final parser = ArgParser()
    ..addCommand('start')
    ..addCommand('list-pending')
    ..addCommand('take-action');

  final argResults = parser.parse(arguments);

  switch (argResults.command?.name) {
    case 'start':
      print('Starting escrow service');
      print({
        'privateKey': privateKey,
        'relayUrl': relayUrl,
        'rpcUrl': rpcUrl,
        'contractAddress': contractAddress
      });
      await ndk.broadcast.broadcast(
          nostrEvent: Nip01Event(
              pubKey: keyPair.publicKey,
              kind: kNostrKindEscrow,
              tags: [],
              content: EscrowContent(
                      pubkey: keyPair.publicKey,
                      contractAddress: contractAddress,
                      chainId: (await _web3client.getChainId()).toInt(),
                      type: EscrowType.ROOTSTOCK,
                      maxDuration: Duration(days: 365 * 2))
                  .toString())
            ..sign(privateKey));
      print('Broadcast escrow event');
      // multiEscrow
      //     .tradeCreatedEvents(fromBlock: BlockNum.current())
      //     .listen((event) {
      //   print('Trade created: ${event}');
      // });
      break;
    case 'list-pending':
      break;
    case 'list-active':
      break;
    case 'list-closed':
      break;
    case 'create-service':
      break;
    case 'update-service':
      break;
    case 'delete-service':
      break;
    case 'resolve':
      break;
    default:
      print('Unknown command');
  }
}
