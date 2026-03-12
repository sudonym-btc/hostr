@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;

  setUp(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_escrow_fund_recoverer_it',
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

  // @todo: 00:52 [WARNING] timed out connecting to relay wss://relay.hostr.development happens because we login and then close connections immediately.
  // When we launch app fresh on ios we get same error. Could auth be triggering twice or hostr.dispose be being called from somewhere?
  test('recoverAll returns 0 when store is empty', () async {
    final trade = await harness.seeds.freshTrade(hostHasEvm: true);
    await harness.hostr.auth.signin(trade.guest.privateKey);

    final recoverer = getIt<EscrowFundRecoverer>();
    final resolved = await recoverer.recoverAll();

    expect(resolved, 0);
  });

  test(
    'recoverAll skips already-terminal escrow fund',
    () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);
      await hostr.auth.signin(trade.guest.privateKey);

      final contractAddress = resolveContractAddress();
      final escrowService = harness.seeds.factory
          .buildEscrowServices(contractAddress: contractAddress)
          .first;

      final operation = hostr.escrow.fund(
        EscrowFundParams(
          escrowService: escrowService,
          negotiateReservation: trade.negotiateReservation,
          sellerProfile: trade.sellerProfile,
          amount: trade.negotiateReservation.amount!,
        ),
      );

      // Pre-fund the resolved signer so no swap-in is needed — keeps the test fast.
      await operation.initialize();
      await anvil.setBalance(
        address: hostr.auth
            .getActiveEvmKey(accountIndex: operation.accountIndex)
            .address
            .eip55With0x,
        amountWei: BitcoinAmount.fromInt(BitcoinUnit.bitcoin, 2).getInWei,
      );

      await operation.run();
      expect(operation.state, isA<OnchainTxConfirmed>());

      // Store should have a terminal entry now.
      final recoverer = getIt<EscrowFundRecoverer>();
      final resolved = await recoverer.recoverAll();

      expect(resolved, 0);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'recoverAll recovers escrow fund from depositing state',
    () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);
      await hostr.auth.signin(trade.guest.privateKey);

      final contractAddress = resolveContractAddress();
      final escrowService = harness.seeds.factory
          .buildEscrowServices(contractAddress: contractAddress)
          .first;

      final operation = hostr.escrow.fund(
        EscrowFundParams(
          escrowService: escrowService,
          negotiateReservation: trade.negotiateReservation,
          sellerProfile: trade.sellerProfile,
          amount: trade.negotiateReservation.amount!,
        ),
      );

      // Pre-fund the resolved signer so no swap-in is needed.
      await operation.initialize();
      await anvil.setBalance(
        address: hostr.auth
            .getActiveEvmKey(accountIndex: operation.accountIndex)
            .address
            .eip55With0x,
        amountWei: BitcoinAmount.fromInt(BitcoinUnit.bitcoin, 2).getInWei,
      );

      await operation.run();
      expect(operation.state, isA<OnchainTxConfirmed>());

      final completedData =
          (operation.state as OnchainTxConfirmed).data as EscrowFundData;

      // Rewrite the store entry to "txBroadcast" with the known tx hash —
      // simulating a crash after the deposit tx was broadcast but before
      // the receipt was confirmed.
      final store = getIt<OperationStateStore>();
      final depositingState = OnchainTxBroadcast(completedData);
      await store.write(
        'escrow_fund',
        completedData.tradeId,
        depositingState.toJson(),
      );

      // Verify it was written as non-terminal.
      final stored = await store.read('escrow_fund', completedData.tradeId);
      expect(stored?['state'], 'txBroadcast');
      expect(stored?['isTerminal'], false);

      // Recover — the deposit tx is already on-chain, so the recoverer should
      // find the receipt and mark the operation completed.
      final recoverer = getIt<EscrowFundRecoverer>();
      final resolved = await recoverer.recoverAll();

      expect(resolved, 1);

      // Verify the store entry is now terminal.
      final recovered = await store.read('escrow_fund', completedData.tradeId);
      expect(recovered?['isTerminal'], true);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test('recoverAll returns 0 when nested swap is not yet complete', () async {
    final trade = await harness.seeds.freshTrade(hostHasEvm: true);
    await harness.hostr.auth.signin(trade.guest.privateKey);

    // Manually seed a SwapProgress state with a fake swap ID that doesn't
    // exist in the swap_in namespace — the recoverer should recognise the
    // swap is not ready and skip it.
    final store = getIt<OperationStateStore>();
    final fakeData = EscrowFundData(
      tradeId: 'fake-trade-id',
      reservedAmountWeiHex: BigInt.from(100000).toRadixString(16),
      sellerEvmAddress: '0x0000000000000000000000000000000000000001',
      arbiterEvmAddress: '0x0000000000000000000000000000000000000002',
      contractAddress: resolveContractAddress(),
      chainId: 33,
      unlockAt:
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
          1000,
      accountIndex: 0,
      swapId: 'nonexistent-swap-id',
    );
    final swapProgressState = OnchainSwapProgress(fakeData);
    await store.write(
      'escrow_fund',
      fakeData.tradeId,
      swapProgressState.toJson(),
    );

    final recoverer = getIt<EscrowFundRecoverer>();
    final resolved = await recoverer.recoverAll();

    // The swap is not complete, so the recoverer should NOT resolve this entry.
    expect(resolved, 0);
  });
}
