import 'dart:io';

import 'package:args/args.dart';
import 'package:escrow/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

/// Allow self-signed certificates so the escrow daemon can connect to local
/// relay/blossom/etc. over TLS without a trusted CA chain.
class _PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }
}

void main(List<String> arguments) async {
  HttpOverrides.global = _PermissiveHttpOverrides();
  final String relayUrl =
      Platform.environment['NOSTR_RELAY'] ?? 'wss://relay.hostr.development';
  final String privateKey =
      Platform.environment['PRIVATE_KEY'] ?? MockKeys.escrow.privateKey!;
  final String rpcUrl =
      Platform.environment['RPC_URL'] ?? 'http://localhost:8545';
  final String blossomUrl = Platform.environment['BLOSSOM_URL'] ??
      'https://blossom.hostr.development';
  final String environment = Platform.environment['ENV'] ?? 'dev';
  final String contractAddress = Platform.environment['CONTRACT_ADDR'] ??
      '0x7a2088a1bFc9d81c55368AE168C2C02570cB814F';

  await setupInjection(
    relayUrl: relayUrl,
    rpcUrl: rpcUrl,
    blossomUrl: blossomUrl,
    environment: environment,
  );
  final hostr = getIt<Hostr>();

  await hostr.auth.signin(privateKey);

  final ourProfile = await hostr.metadata
      .getOne(Filter(authors: [hostr.auth.activeKeyPair!.publicKey]));

  final ourEscrowService = EscrowService(
      pubKey: hostr.auth.activeKeyPair!.publicKey,
      tags: EventTags([]),
      content: EscrowServiceContent(
          pubkey: hostr.auth.activeKeyPair!.publicKey,
          evmAddress: hostr.auth.getActiveEvmKey().address.eip55With0x,
          contractAddress: contractAddress,
          contractBytecodeHash: 'MockBytecodeHash',
          chainId: (await hostr.evm.supportedEvmChains[0].client.getChainId())
              .toInt(),
          maxDuration: Duration(days: 365),
          type: EscrowType.EVM));

  print(ourProfile);

  final parser = ArgParser()
    ..addCommand('start')
    ..addCommand('list-pending');

  final fundCmd = parser.addCommand('fund');
  fundCmd
    ..addOption('amount', help: 'Amount to fund the escrow', mandatory: true);

  final arbitrateCmd = parser.addCommand('arbitrate');
  arbitrateCmd
    ..addOption('tradeId',
        help: 'Trade ID string to arbitrate', mandatory: true)
    ..addOption('forward',
        help: 'Forward ratio as double, strictly between 0 and 1',
        mandatory: true);

  final argResults = parser.parse(arguments);

  switch (argResults.command?.name) {
    case 'start':
      print('Starting escrow service');

      final contract = hostr.evm.supportedEvmChains[0]
          .getSupportedEscrowContract(ourEscrowService);
      await contract.ensureDeployed();

      await getIt<Hostr>().escrows.upsert(ourEscrowService);

      break;

    case 'fund':
      final cmd = argResults.command;
      final amount = cmd?['amount'] as String?;
      final swapOp = hostr.evm.supportedEvmChains[0].swapIn(SwapInParams(
          evmKey: hostr.auth.getActiveEvmKey(),
          amount: BitcoinAmount.fromInt(BitcoinUnit.sat, int.parse(amount!))));
      swapOp.execute();
      swapOp.stream
          .doOnData(print)
          .whereType<SwapInPaymentProgress>()
          .map((e) => e.paymentState)
          .whereType<PayExternalRequired>()
          .listen((event) {
        print(
            'Swap event: ${(event.callbackDetails as LightningCallbackDetails).invoice.paymentRequest}');
      });
      break;
    case 'list-pending':
      final contract = hostr.evm
          .getChainForEscrowService(ourEscrowService)
          .getSupportedEscrowContract(ourEscrowService);

      final streamer = contract.allEvents(
          ContractEventsParams(
              arbiterEvmAddress: hostr.auth.getActiveEvmKey().address),
          null);

      streamer.stream.listen(
          (data) => print('Received event: ${(data as dynamic).tradeId}'));
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
    case 'arbitrate':
      final cmd = argResults.command;
      final tradeId = cmd?['tradeId'] as String?;
      final forwardRaw = cmd?['forward'] as String?;
      if (tradeId == null || tradeId.isEmpty || forwardRaw == null) {
        exitCode = 64;
        return;
      }

      final forward = double.tryParse(forwardRaw);
      if (forward == null || forward <= 0 || forward >= 1) {
        print(
            'Invalid forward value. Must be a number strictly between 0 and 1.');
        exitCode = 64;
        return;
      }

      final contract = hostr.evm
          .getChainForEscrowService(ourEscrowService)
          .getSupportedEscrowContract(ourEscrowService);

      final txHash = await contract.arbitrate(
        ContractArbitrateParams(
          tradeId: tradeId,
          forward: forward,
          ethKey: hostr.auth.getActiveEvmKey(),
        ),
      );
      print('Arbitrate tx: $txHash');
      break;
    default:
      print('Unknown command');
  }
}
