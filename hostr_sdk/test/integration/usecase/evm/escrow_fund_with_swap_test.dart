@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;

  setUpAll(() async {
    await IntegrationTestHarness.clearBoltzPendingEvmTransactions();
    harness = await IntegrationTestHarness.create(
      name: 'hostr_escrow_fund_swap_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.warning,
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

      final contractAddress = resolveContractAddress();
      final escrowService =
          (await harness.seeds.factory.buildEscrowServices(
            contractAddress: contractAddress,
          )).first;
      final negotiateReservation = trade.negotiateReservation;
      final sellerProfile = trade.sellerProfile;

      final operation = hostr.escrow.fund(
        EscrowFundParams(
          escrowService: escrowService,
          negotiateReservation: negotiateReservation,
          sellerProfile: sellerProfile,
          amount: negotiateReservation.amount!,
        ),
      );

      final emittedStates = <OnchainOperationState>[operation.state];
      final sub = operation.stream.listen(emittedStates.add);

      await operation.execute();
      emittedStates.add(operation.state);
      await sub.cancel();

      // --- Log the balance of the funding address after the operation ---
      final completedData = operation.state.data!;
      final fundingAddress = await hostr.auth.hd.getEvmAddress(
        accountIndex: completedData.accountIndex,
      );
      final balanceAfter = await hostr.evm.rootstock.getBalance(fundingAddress);

      expect(balanceAfter.getInSats.toInt(), equals(0));

      // --- State flow assertions ---
      expect(emittedStates.first, isA<OnchainInitialised>());

      // A swap-in must have been triggered because we started with zero EVM
      // balance. Verify at least one EscrowFundSwapProgress state appeared.
      expect(
        emittedStates.whereType<OnchainSwapProgress>(),
        isNotEmpty,
        reason: 'Expected swap-in to be triggered (zero EVM balance)',
      );

      expect(operation.state, isA<OnchainTxConfirmed>());
      expect(emittedStates.whereType<OnchainTxConfirmed>(), isNotEmpty);

      final completed = operation.state as OnchainTxConfirmed;
      final confirmedData = completed.data;
      expect(confirmedData.transactionInformation, isNotNull);
      final txHash = _extractTxHash(confirmedData.transactionInformation!);
      expect(txHash, isNotNull);

      expect(confirmedData.transactionReceipt, isNotNull);
      final receipt = confirmedData.transactionReceipt!;
      expect(_extractReceiptTxHash(receipt), equals(txHash));
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

String? _extractReceiptTxHash(TransactionReceipt receipt) {
  final dynamic hash = (receipt as dynamic).transactionHash;
  if (hash == null) return null;
  if (hash is String) return hash;
  if (hash is List<int>) return bytesToHex(hash, include0x: true);
  final normalized = hash.toString();
  if (normalized.isEmpty) return null;
  return normalized;
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
