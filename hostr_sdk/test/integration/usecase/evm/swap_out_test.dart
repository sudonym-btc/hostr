@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:logger/logger.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;

  setUp(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_swap_out_it',
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
    'swap out emits expected state flow when NWC is connected',
    () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;

      await harness.signInAndConnectNwc(
        user: MockKeys.guest,
        appNamePrefix: 'swap-out-it',
      );

      await anvil.setBalance(
        address: hostr.auth.getActiveEvmKey().address.eip55With0x,
        amountWei: BitcoinAmount.fromInt(BitcoinUnit.sat, 100000).getInWei,
      );

      final swapOut = hostr.evm.rootstock.swapOutAll();

      final emittedStates = <SwapOutState>[swapOut.state];
      final sub = swapOut.stream.listen(emittedStates.add);

      await swapOut.execute();
      await sub.cancel();

      expect(emittedStates.first, isA<SwapOutInitialised>());
      expect(
        emittedStates.any((state) => state is SwapOutAwaitingOnChain),
        isTrue,
      );
      expect(emittedStates.any((state) => state is SwapOutFunded), isTrue);
      expect(emittedStates.last, isA<SwapOutCompleted>());
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  test(
    'swap out fails with expected state flow when NWC is not connected',
    () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;

      await hostr.auth.signin(MockKeys.guest.privateKey!);

      await anvil.setBalance(
        address: hostr.auth.getActiveEvmKey().address.eip55With0x,
        amountWei: BitcoinAmount.fromInt(BitcoinUnit.sat, 100000).getInWei,
      );

      final swapOut = hostr.evm.rootstock.swapOutAll();

      final emittedStates = <SwapOutState>[swapOut.state];
      final sub = swapOut.stream.listen(emittedStates.add);

      final run = swapOut.execute();
      await expectLater(
        swapOut.stream,
        emitsThrough(isA<SwapOutExternalInvoiceRequired>()),
      );

      // Complete the pending external-invoice path with an invalid invoice so
      // operation exits deterministically in tests.
      swapOut.submitExternalInvoice('invalid-invoice');
      await run;
      await sub.cancel();

      expect(emittedStates.first, isA<SwapOutInitialised>());
      expect(swapOut.state, isA<SwapOutFailed>());
      expect(
        emittedStates.any((state) => state is SwapOutExternalInvoiceRequired),
        isTrue,
      );
      expect(
        emittedStates.any((state) => state is SwapOutAwaitingOnChain),
        isFalse,
      );
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );
}
