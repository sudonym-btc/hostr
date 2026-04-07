@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

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

  test('escrow fund with swap-in executes and completes', () async {
    final hostr = harness.hostr;
    final trade = await harness.seeds.freshTrade(hostHasEvm: true);
    await harness.anvil.setAutomine(true);
    await harness.signInAndConnectNwc(
      user: trade.guest.keyPair,
      appNamePrefix: 'escrow-fund-swap-it',
    );

    // EscrowFundPreparer is stateless — it always builds SwapInParams with
    // postClaimCalls (approve + createTrade) for the escrow deposit.
    // The EVM address is NOT pre-funded; funds arrive via the Boltz swap-in.

    final escrowService = (await harness.seeds.factory.buildEscrowServices(
      contractAddress: env.evmConfig.chains.first.escrowContractAddress!,
    )).first;
    final negotiateReservation = trade.negotiateReservation;
    final sellerProfile = trade.sellerProfile;

    final preparer = hostr.escrow.fund(
      EscrowFundParams(
        escrowService: escrowService,
        negotiateReservation: negotiateReservation,
        sellerProfile: sellerProfile,
        amount: negotiateReservation.amount!,
      ),
    );

    // prepare() resolves the signer and returns SwapInParams with
    // postClaimCalls set to the escrow deposit calls.
    final swapInParams = await preparer.prepare();
    final configured = preparer.configuredChain;

    final swapIn = configured.swapIn(
      params: swapInParams,
      auth: hostr.auth,
      logger: CustomLogger(),
    );

    final emittedStates = <SwapInState>[swapIn.state];
    final sub = swapIn.stream.listen(emittedStates.add);

    await swapIn.execute();
    emittedStates.add(swapIn.state);
    await sub.cancel();

    // --- Balance of the funding address after the operation ---
    // All swapped funds are forwarded to the escrow contract via
    // postClaimCalls, so the EVM address ends up with zero balance.
    final fundingAddress = await hostr.auth.hd.getEvmAddress(
      accountIndex: preparer.accountIndex,
    );
    final balanceAfter = await configured.getBalance(fundingAddress);

    expect(balanceAfter.getInSats.toInt(), equals(0));

    // --- State flow assertions ---
    expect(emittedStates.first, isA<SwapInInitialised>());

    // The Lightning invoice must have been paid as part of the swap-in.
    expect(
      emittedStates.whereType<SwapInInvoicePaid>(),
      isNotEmpty,
      reason: 'Expected Lightning invoice to be paid during swap-in',
    );

    expect(swapIn.state, isA<SwapInCompleted>());
    final claimTxHash = (swapIn.state as SwapInCompleted).data.claimTxHash;
    expect(claimTxHash, isNotNull);
  });
}
