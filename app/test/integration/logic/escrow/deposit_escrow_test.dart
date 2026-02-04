import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await getIt.reset();
    configureInjection(Env.test);
    await getIt<Hostr>().auth.signin(MockKeys.guest.privateKey!);
  });

  tearDownAll(() async {
    await getIt<Hostr>().dispose();
    await getIt.reset();
  });

  test('escrow deposit creates on-chain trade', () async {
    final contractAddress = Platform.environment['CONTRACT_ADDR'];
    if (contractAddress == null || contractAddress.isEmpty) {
      return;
    }

    final hostr = getIt<Hostr>();
    final evmChain = hostr.evm.supportedEvmChains.first;
    final sellerAddress = getEvmCredentials(
      MockKeys.hoster.privateKey!,
    ).address.eip55With0x;
    final escrowAddress = getEvmCredentials(
      MockKeys.escrow.privateKey!,
    ).address.eip55With0x;

    final txHash = await hostr.payments.escrow.escrow(
      eventId: 'escrow-${DateTime.now().millisecondsSinceEpoch}',
      amount: Amount(currency: Currency.BTC, value: 0.00001),
      sellerEvmAddress: sellerAddress,
      escrowEvmAddress: escrowAddress,
      escrowContractAddress: contractAddress,
      timelock: 200,
      evmChain: evmChain,
    );

    expect(txHash, isNotEmpty);

    final receipt = await _waitForReceipt(evmChain.client, txHash);
    expect(receipt, isNotNull);
    expect(receipt!.status, isTrue);
  }, skip: _skipIfNoContract());
}

String? _skipIfNoContract() {
  final contractAddress = Platform.environment['CONTRACT_ADDR'];
  if (contractAddress == null || contractAddress.isEmpty) {
    return 'Set CONTRACT_ADDR to a deployed MultiEscrow address.';
  }
  return null;
}

Future<TransactionReceipt?> _waitForReceipt(
  Web3Client client,
  String hash,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    final receipt = await client.getTransactionReceipt(hash);
    if (receipt != null) {
      return receipt;
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
  return null;
}
