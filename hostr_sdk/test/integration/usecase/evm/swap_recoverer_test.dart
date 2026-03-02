@Tags(['integration', 'docker'])
library;

import 'dart:math';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;

  setUp(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_swap_recoverer_it',
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

  test('recoverAll returns 0 when store is empty', () async {
    await harness.signInAndConnectNwc(
      user: harness.seeds.deriveKeyPair(Random().nextInt(1000000)),
      appNamePrefix: 'swap-recover-empty',
    );

    final recoverer = getIt<SwapRecoverer>();
    final resolved = await recoverer.recoverAll();

    expect(resolved, 0);
  });

  test(
    'recoverAll skips already-terminal swap-in',
    () async {
      final hostr = harness.hostr;

      await harness.signInAndConnectNwc(
        user: harness.seeds.deriveKeyPair(Random().nextInt(1000000)),
        appNamePrefix: 'swap-recover-terminal',
      );

      // Run a full swap-in to completion so the store has a terminal entry.
      final swapLimits = await hostr.evm.rootstock.getSwapInLimits();
      final amount =
          swapLimits.min + BitcoinAmount.fromInt(BitcoinUnit.sat, 1000);

      final swapIn = hostr.evm.rootstock.swapIn(
        SwapInParams(
          evmKey: hostr.auth.getActiveEvmKey(),
          accountIndex: 0,
          amount: amount,
        ),
      );

      await swapIn.execute();
      expect(swapIn.state, isA<SwapInCompleted>());

      // Now recover — should find the terminal entry and skip it.
      final recoverer = getIt<SwapRecoverer>();
      final resolved = await recoverer.recoverAll();

      expect(resolved, 0);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'recoverAll recovers swap-in from funded state',
    () async {
      final hostr = harness.hostr;

      await harness.signInAndConnectNwc(
        user: harness.seeds.deriveKeyPair(Random().nextInt(1000000)),
        appNamePrefix: 'swap-recover-funded',
      );

      // 1. Run a full swap-in to completion.
      final swapLimits = await hostr.evm.rootstock.getSwapInLimits();
      final amount =
          swapLimits.min + BitcoinAmount.fromInt(BitcoinUnit.sat, 1000);

      final swapIn = hostr.evm.rootstock.swapIn(
        SwapInParams(
          evmKey: hostr.auth.getActiveEvmKey(),
          accountIndex: 0,
          amount: amount,
        ),
      );

      await swapIn.execute();
      expect(swapIn.state, isA<SwapInCompleted>());

      final completedData = (swapIn.state as SwapInCompleted).data;

      // 2. Rewrite the store entry to "funded" — simulating a crash after
      //    Boltz locked on-chain but before we claimed.
      final store = getIt<OperationStateStore>();
      final fundedState = SwapInFunded(
        completedData.copyWith(
          claimTxHash: null,
          lastBoltzStatus: 'transaction.confirmed',
        ),
      );
      await store.write('swap_in', completedData.boltzId, fundedState.toJson());

      // Verify it was written as non-terminal.
      final stored = await store.read('swap_in', completedData.boltzId);
      expect(stored?['state'], 'funded');
      expect(stored?['isTerminal'], false);

      // 3. Recover — the claim event is already on-chain, so recovery should
      //    find it and advance to completed.
      final recoverer = getIt<SwapRecoverer>();
      final resolved = await recoverer.recoverAll();

      expect(resolved, 1);

      // Verify the store entry is now terminal.
      final recovered = await store.read('swap_in', completedData.boltzId);
      expect(recovered?['isTerminal'], true);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
