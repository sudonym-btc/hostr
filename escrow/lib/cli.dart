import 'dart:io';

import 'package:args/args.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart' show Env;
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import 'package:http/http.dart' as http;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:web3dart/web3dart.dart';

void main(List<String> arguments) async {
  final String relayUrl =
      Platform.environment['NOSTR_RELAY'] ?? 'ws://relay.hostr.development';
  final String privateKey =
      Platform.environment['PRIVATE_KEY'] ?? MockKeys.escrow.privateKey!;
  final String rpcUrl =
      Platform.environment['RPC_URL'] ?? 'http://localhost:8545';
  final String contractAddress = Platform.environment['CONTRACT_ADDR'] ??
      '0x7a2088a1bFc9d81c55368AE168C2C02570cB814F';
    final String blossomUrl =
      Platform.environment['HOSTR_BLOSSOM'] ?? 'http://blossom.hostr.development';
    final String hostrEnv = Platform.environment['HOSTR_ENV'] ?? Env.dev;
    final int chainId =
      int.tryParse(Platform.environment['CHAIN_ID'] ?? '') ?? 33;
    final String boltzApiUrl =
      Platform.environment['BOLTZ_API_URL'] ?? 'http://localhost:9001/v2';
    final String rifRelayUrl =
      Platform.environment['RIF_RELAY_URL'] ?? 'http://localhost:8090';
    final String rifRelayCallVerifier =
      Platform.environment['RIF_RELAY_CALL_VERIFIER'] ??
      '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707';
    final String rifRelayDeployVerifier =
      Platform.environment['RIF_RELAY_DEPLOY_VERIFIER'] ??
      '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';
    final String rifSmartWalletFactoryAddress =
      Platform.environment['RIF_SMART_WALLET_FACTORY_ADDRESS'] ??
      '0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE';

    final HostrConfig hostrConfig = HostrConfig(
    bootstrapRelays: [relayUrl],
    bootstrapBlossom: [blossomUrl],
    rootstockConfig: CliRootstockConfig(
      chainId: chainId,
      rpcUrl: rpcUrl,
      boltz: CliBoltzConfig(
      apiUrl: boltzApiUrl,
      rifRelayUrl: rifRelayUrl,
      rifRelayCallVerifier: rifRelayCallVerifier,
      rifRelayDeployVerifier: rifRelayDeployVerifier,
      rifSmartWalletFactoryAddress: rifSmartWalletFactoryAddress,
      ),
    ),
    );

    final Hostr hostrSdk = Hostr(config: hostrConfig, environment: hostrEnv);
    await _printSupportedEvmChains(hostrSdk);

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
              kind: kNostrKindEscrowService,
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

Future<void> _printSupportedEvmChains(Hostr hostrSdk) async {
  final supportedContracts =
      SupportedEscrowContractRegistry.supportedContractNames;
  print('Supported EVM chains and escrow wrappers:');
  for (final chain in hostrSdk.evm.supportedEvmChains) {
    final chainId = (await chain.getChainId()).toInt();
    final wrappers = supportedContracts.isEmpty
        ? 'none'
        : supportedContracts.join(', ');
    print('- ${chain.runtimeType} (chainId: $chainId): $wrappers');
  }
}

class CliRootstockConfig extends RootstockConfig {
  @override
  final int chainId;
  @override
  final String rpcUrl;
  @override
  final BoltzConfig boltz;

  CliRootstockConfig({
    required this.chainId,
    required this.rpcUrl,
    required this.boltz,
  });
}

class CliBoltzConfig extends BoltzConfig {
  @override
  final String apiUrl;
  @override
  final String rifRelayUrl;
  @override
  final String rifRelayCallVerifier;
  @override
  final String rifRelayDeployVerifier;
  @override
  final String rifSmartWalletFactoryAddress;

  CliBoltzConfig({
    required this.apiUrl,
    required this.rifRelayUrl,
    required this.rifRelayCallVerifier,
    required this.rifRelayDeployVerifier,
    required this.rifSmartWalletFactoryAddress,
  });
}
