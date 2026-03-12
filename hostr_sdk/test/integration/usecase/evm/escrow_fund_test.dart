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
    harness = await IntegrationTestHarness.create(
      name: 'hostr_escrow_fund_it',
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
    'escrow fund emits expected state flow and confirms transaction',
    () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);
      await hostr.auth.signin(trade.guest.privateKey);

      final contractAddress = resolveContractAddress();
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
          amount: negotiateReservation.amount!,
        ),
      );

      await operation.initialize();
      await anvil.setBalance(
        address: hostr.auth
            .getActiveEvmKey(accountIndex: operation.accountIndex)
            .address
            .eip55With0x,
        amountWei: BitcoinAmount.fromInt(BitcoinUnit.bitcoin, 2).getInWei,
      );

      final emittedStates = <OnchainOperationState>[operation.state];
      final sub = operation.stream.listen(emittedStates.add);

      await operation.run();
      emittedStates.add(operation.state);
      await sub.cancel();

      expect(emittedStates.first, isA<OnchainInitialised>());
      expect(operation.state, isA<OnchainTxConfirmed>());
      expect(emittedStates.whereType<OnchainTxConfirmed>(), isNotEmpty);

      final completed = operation.state as OnchainTxConfirmed;
      final completedData = completed.data;
      expect(completedData.transactionInformation, isNotNull);
      final txHash = _extractTxHash(completedData.transactionInformation!);
      expect(txHash, isNotNull);

      expect(completedData.transactionReceipt, isNotNull);
      final receipt = completedData.transactionReceipt!;
      expect(_extractReceiptTxHash(receipt), equals(txHash));
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
