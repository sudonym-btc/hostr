@Tags(['integration', 'docker'])
library;

import 'dart:io';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;

  setUpAll(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_escrow_fund_swap_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.debug,
      cleanHydratedStorage: true,
    );
  });

  tearDownAll(() {
    IntegrationTestHarness.resetLogLevel();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test(
    'escrow fund with swap-in emits expected state flow and confirms transaction',
    () async {
      final hostr = harness.hostr;
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);
      await harness.anvil.setAutomine(true);
      await harness.signInAndConnectNwc(
        user: trade.guest.keyPair,
        appNamePrefix: 'escrow-fund-swap-it',
      );

      // Do NOT pre-fund the EVM address — the operation must detect
      // insufficient balance and trigger a swap-in (Lightning → Boltz →
      // RIF Relay → EVM) before depositing to the escrow contract.

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

      // --- Log the balance of the funding address after the operation ---
      final completedData = operation.state.data!;
      final fundingAddress = hostr.auth.getEvmAddress(
        accountIndex: completedData.accountIndex,
      );
      final balanceAfter = await hostr.evm.rootstock.getBalance(fundingAddress);
      print(
        'Balance of funding address ($fundingAddress, '
        'index ${completedData.accountIndex}) after escrow fund: '
        '(${balanceAfter.getInSats} sats)',
      );

      // --- State flow assertions ---
      expect(emittedStates.first, isA<EscrowFundInitialised>());

      // A swap-in must have been triggered because we started with zero EVM
      // balance. Verify at least one EscrowFundSwapProgress state appeared.
      expect(
        emittedStates.whereType<EscrowFundSwapProgress>(),
        isNotEmpty,
        reason: 'Expected swap-in to be triggered (zero EVM balance)',
      );

      expect(operation.state, isA<EscrowFundCompleted>());
      expect(emittedStates.whereType<EscrowFundCompleted>(), isNotEmpty);

      final completed = operation.state as EscrowFundCompleted;
      expect(completed.transactionInformation, isNotNull);
      final txHash = _extractTxHash(completed.transactionInformation!);
      expect(txHash, isNotNull);

      final receipt = await hostr.evm.rootstock.awaitReceipt(txHash!);
      expect(_isReceiptSuccessful(receipt), isTrue);
    },
    timeout: const Timeout(Duration(seconds: 60)),
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
