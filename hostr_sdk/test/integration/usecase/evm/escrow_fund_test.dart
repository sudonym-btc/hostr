@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../../../support/evm_test_helpers.dart';
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
      await harness.signInAndConnectNwc(
        user: trade.guest.keyPair,
        appNamePrefix: 'escrow-fund-it',
      );

      final escrowService = (await harness.seeds.factory.buildEscrowServices(
        contractAddress: env.evmConfig.chains.first.escrowContractAddress!,
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

      await operation.initialize();
      final evmKey = await hostr.auth.hd.getActiveEvmKey(
        accountIndex: operation.accountIndex,
      );
      final configuredChain = hostr.evm.getChainByChainId(
        env.evmConfig.chains.first.chainId,
      )!;
      final fundingAddress = await configuredChain.getAccountAddress(evmKey);
      await anvil.setBalance(
        address: fundingAddress.eip55With0x,
        amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
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
      final txHash = extractTxHash(completedData.transactionInformation!);
      expect(txHash, isNotNull);

      expect(completedData.transactionReceipt, isNotNull);
      final receipt = completedData.transactionReceipt!;
      expect(extractReceiptTxHash(receipt), equals(txHash));
      expect(isReceiptSuccessful(receipt), isTrue);
    },
  );
}
