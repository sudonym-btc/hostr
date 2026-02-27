@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:logger/logger.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;

  setUpAll(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_swap_in_it',
      logLevel: Level.debug,
    );
    await harness.signInAndConnectNwc(
      user: MockKeys.guest,
      appNamePrefix: 'swap-in-it',
    );
  });

  tearDownAll(() {
    IntegrationTestHarness.resetLogLevel();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test(
    'swap in emits expected state flow when NWC is connected',
    () async {
      try {
        final hostr = harness.hostr;
        final evm = hostr.evm;
        final minimumSwapIn = await evm.rootstock.getMinimumSwapIn();
        final amount =
            minimumSwapIn + BitcoinAmount.fromInt(BitcoinUnit.sat, 1000);

        final swapIn = evm.rootstock.swapIn(
          SwapInParams(evmKey: hostr.auth.getActiveEvmKey(), amount: amount),
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

        expect(emittedStates.last, isA<SwapInCompleted>());
      } finally {
        // no-op: closed by harness in tearDown
      }
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );
}
