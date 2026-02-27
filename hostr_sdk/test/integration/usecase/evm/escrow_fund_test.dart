@Tags(['integration', 'docker'])
library;

import 'dart:io';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:logger/logger.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;

  setUpAll(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_escrow_fund_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.warning,
      cleanHydratedStorage: true,
    );
    await harness.signInAndConnectNwc(
      user: MockKeys.guest,
      appNamePrefix: 'escrow-fund-it',
    );
  });

  tearDownAll(() {
    IntegrationTestHarness.resetLogLevel();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test(
    'escrow fund emits expected state flow and confirms transaction',
    () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);

      await hostr.auth.signin(trade.guest.privateKey);

      await anvil.setBalance(
        address: hostr.auth.getActiveEvmKey().address.eip55With0x,
        amountWei: BigInt.parse('2000000000000000000'),
      );

      final contractAddress = _resolveContractAddress();
      final escrowService = harness.seeds.factory
          .buildEscrowServices(contractAddress: contractAddress)
          .first;
      final negotiateReservation = trade.negotiateReservation;
      final sellerProfile = trade.sellerProfile;

      final operation = hostr.escrow.fund(
        EscrowFundParams(
          escrowService: escrowService,
          negotiateReservation: negotiateReservation,
          sellerProfile: sellerProfile,
          amount: negotiateReservation.parsedContent.amount!,
        ),
      );

      final emittedStates = <EscrowFundState>[operation.state];
      final sub = operation.stream.listen(emittedStates.add);

      await operation.execute();
      emittedStates.add(operation.state);
      await sub.cancel();

      expect(emittedStates.first, isA<EscrowFundInitialised>());
      expect(operation.state, isA<EscrowFundCompleted>());
      expect(emittedStates.whereType<EscrowFundCompleted>(), isNotEmpty);

      final completed = operation.state as EscrowFundCompleted;
      final txHash = _extractTxHash(completed.transactionInformation);
      expect(txHash, isNotNull);

      final receipt = await hostr.evm.rootstock.awaitReceipt(txHash!);
      expect(_isReceiptSuccessful(receipt), isTrue);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

String? _extractTxHash(TransactionInformation tx) {
  final dynamic d = tx;
  final hash = d.hash?.toString() ?? d.id?.toString();
  if (hash == null || hash.isEmpty) return null;
  return hash;
}

bool _isReceiptSuccessful(TransactionReceipt receipt) {
  final dynamic status = (receipt as dynamic).status;
  if (status == null) return true;
  if (status is bool) return status;
  if (status is int) return status == 1;
  if (status is BigInt) return status == BigInt.one;
  final normalized = status.toString().toLowerCase();
  return normalized == '1' || normalized == '0x1' || normalized == 'true';
}

String _resolveContractAddress() {
  final fromEnv = Platform.environment['CONTRACT_ADDR'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

  final contractFile = File('docker/data/escrow/contract_addr');
  if (contractFile.existsSync()) {
    final fromFile = contractFile.readAsStringSync().trim();
    if (fromFile.isNotEmpty) return fromFile;
  }

  // Hardhat anvil default from current local stack deployment.
  return '0x7a2088a1bFc9d81c55368AE168C2C02570cB814F';
}
