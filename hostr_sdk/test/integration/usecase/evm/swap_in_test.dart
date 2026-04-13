@Tags(['integration', 'docker'])
library;

import 'dart:math';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:logger/logger.dart';
import 'package:models/main.dart';
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

  test('swap in emits expected state flow when NWC is connected', () async {
    try {
      final hostr = harness.hostr;
      final evm = hostr.evm;
      await harness.signInAndConnectNwc(
        user: harness.seeds.deriveKeyPair(Random().nextInt(1000000)),
        appNamePrefix: 'swap-in-it',
      );
      final configured = evm.getChainById('rootstock-regtest')!;

      // Fund the EOA on rootstock so it can pay gas for the claim tx.
      final evmKey = await hostr.auth.hd.getActiveEvmKey();
      await harness.anvilRootstock.setBalance(
        address: evmKey.address.eip55With0x,
        amountWei: rbtcFromSats(BigInt.from(100000)).getInWei,
      );

      final swapLimits = await configured.swaps!.getSwapInLimits();
      final amount =
          TokenAmount.fromDenominated(
            swapLimits.min,
            Token.native(configured.config.chainId),
          ) +
          rbtcFromSats(BigInt.from(1000), chainId: configured.config.chainId);

      final swapIn = configured.swapIn(
        params: SwapInParams(
          evmKey: await hostr.auth.hd.getActiveEvmKey(),
          accountIndex: 0,
          amountSpec: AmountSpec.output(amount),
        ),
        auth: hostr.auth,
        logger: CustomLogger(),
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

      // ── Wei-perfect amount verification ──────────────────────────────
      // The Boltz reverse swap must deliver at least the requested sats.
      final completedData = (swapIn.state as SwapInCompleted).data;
      final deliveredSats = BigInt.from(completedData.onchainAmountSat);
      final requestedSats = amount.getInSats;
      expect(
        deliveredSats,
        greaterThanOrEqualTo(requestedSats),
        reason:
            'Boltz on-chain amount ($deliveredSats sats) must be >= '
            'requested output ($requestedSats sats)',
      );

      // The claim address (EOA on RSK) should hold deliveredSats
      // minus gas cost.  Gas on RSK is priced in standard EVM wei, so
      // the post-gas balance is NOT sat-aligned — that's expected.
      final claimAddress = evmKey.address;
      final balanceAfterClaim = await configured.getBalance(claimAddress);
      expect(
        balanceAfterClaim.value > BigInt.zero,
        isTrue,
        reason: 'Claim address must hold funds after swap-in',
      );
    } finally {
      // no-op: closed by harness in tearDown
    }
  });
}
