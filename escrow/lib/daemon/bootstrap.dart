import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:escrow/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

/// All the long-lived objects the daemon needs.
class DaemonContext {
  final Hostr hostr;
  final EscrowService escrowService;
  final SupportedEscrowContract contract;
  final Web3Client web3client;

  DaemonContext({
    required this.hostr,
    required this.escrowService,
    required this.contract,
    required this.web3client,
  });
}

/// Allow self-signed certificates so the daemon can connect to local
/// relay/blossom/etc. over TLS without a trusted CA chain.
class PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }
}

/// Bootstrap Hostr, authenticate, build the [EscrowService] descriptor, verify
/// the contract is deployed, and publish the service to the relay.
///
/// Returns a [DaemonContext] with everything the daemon needs.
Future<DaemonContext> bootstrap() async {
  HttpOverrides.global = PermissiveHttpOverrides();
  setCryptoProvider(DartCryptoProvider());

  final String relayUrl =
      Platform.environment['NOSTR_RELAY'] ?? 'wss://relay.hostr.development';
  final String privateKey =
      Platform.environment['PRIVATE_KEY'] ?? MockKeys.escrow.privateKey!;
  final String rpcUrl =
      Platform.environment['RPC_URL'] ?? 'https://anvil.hostr.development';
  final String blossomUrl = Platform.environment['BLOSSOM_URL'] ??
      'https://blossom.hostr.development';
  final String environment = Platform.environment['ENV'] ?? 'dev';
  final String contractAddress;
  try {
    contractAddress = resolveContractAddress();
  } on Object catch (error) {
    print('[daemon] Failed to resolve escrow contract address: $error');
    exit(1);
  }

  final Web3Client web3client = Web3Client(rpcUrl, Client());

  await setupInjection(
    relayUrl: relayUrl,
    rpcUrl: rpcUrl,
    blossomUrl: blossomUrl,
    environment: environment,
  );

  final hostr = getIt<Hostr>();
  await hostr.auth.signin(privateKey);

  final escrowService = EscrowService(
    pubKey: hostr.auth.activeKeyPair!.publicKey,
    tags: EventTags([
      ['d', contractAddress]
    ]),
    content: EscrowServiceContent(
      pubkey: hostr.auth.activeKeyPair!.publicKey,
      evmAddress: (await hostr.auth.hd.getActiveEvmKey()).address.eip55With0x,
      contractAddress: contractAddress,
      contractBytecodeHash: await _resolveMultiEscrowBytecodeHash(
        web3client: web3client,
        contractAddress: contractAddress,
      ),
      chainId: hostr.evm.configuredChains.first.config.chainId,
      maxDuration: Duration(days: 365),
      type: EscrowType.EVM,
      feeBase: 100,
      feePercent: 1,
      minAmount: 5000,
    ),
  );

  final configuredChain = hostr.evm.getChainForEscrowService(escrowService);
  final contract = configuredChain.escrow.getSupportedEscrowContract(
    escrowService,
  );

  await contract.ensureDeployed();
  await hostr.escrows.upsert(escrowService);

  print('[daemon] Escrow service published: ${escrowService.content}');

  return DaemonContext(
    hostr: hostr,
    escrowService: escrowService,
    contract: contract,
    web3client: web3client,
  );
}

Future<String> _resolveMultiEscrowBytecodeHash({
  required Web3Client web3client,
  required String contractAddress,
}) async {
  final runtimeCode = await web3client.getCode(
    EthereumAddress.fromHex(contractAddress),
  );
  return sha256.convert(runtimeCode).toString();
}
