@Tags(['integration', 'docker'])
library;

import 'dart:math';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;

  setUpAll(() async {
    await IntegrationTestHarness.clearBoltzPendingEvmTransactions();
    harness = await IntegrationTestHarness.create(
      name: 'hostr_swap_in_it',
      logLevel: Level.warning,
    );
  });

  tearDownAll(() async {
    await harness.dispose();
    IntegrationTestHarness.resetLogLevel();
  });

  test(
    'swap in emits expected state flow when NWC is connected',
    () async {
      try {
        final hostr = harness.hostr;
        final evm = hostr.evm;
        await harness.signInAndConnectNwc(
          user: harness.seeds.deriveKeyPair(Random().nextInt(1000000)),
          appNamePrefix: 'swap-in-it',
        );
        final swapLimits = await evm.rootstock.getSwapInLimits();
        final amount =
            swapLimits.min + BitcoinAmount.fromInt(BitcoinUnit.sat, 1000);

        final swapIn = evm.rootstock.swapIn(
          SwapInParams(
            evmKey: await hostr.auth.hd.getActiveEvmKey(),
            accountIndex: 0,
            amount: amount,
          ),
        );

        final emittedStates = <SwapInState>[swapIn.state];
        final sub = swapIn.stream.listen(emittedStates.add);

        await swapIn.execute();
        await sub.cancel();

        expect(emittedStates.first, isA<SwapInInitialised>());
        expect(
          emittedStates.any((state) => state is SwapInRequestCreated),
          isTrue,
        );
        expect(
          emittedStates.any((state) => state is SwapInAwaitingOnChain),
          isTrue,
        );

        final externalPaymentRequested = emittedStates
            .whereType<SwapInPaymentProgress>()
            .any((state) => state.paymentState is PayExternalRequired);
        expect(externalPaymentRequested, isFalse);

        expect(swapIn.state, isA<SwapInCompleted>());
      } finally {
        // no-op: closed by harness in tearDown
      }
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );
}
