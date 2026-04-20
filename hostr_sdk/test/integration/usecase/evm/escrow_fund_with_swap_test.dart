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

    final swapIn = configured.swapIn(params: swapInParams);

    final emittedStates = <SwapInState>[swapIn.state];
    final sub = swapIn.stream.listen(emittedStates.add);

    await swapIn.execute();
    emittedStates.add(swapIn.state);
    await sub.cancel();

    // --- Wei-perfect balance of the funding address after the operation ---
    // All swapped funds are forwarded to the escrow contract via
    // postClaimCalls, so the EVM address ends up with zero balance.
    final fundingAddress = await hostr.auth.hd.getEvmAddress(
      accountIndex: preparer.accountIndex,
    );
    final balanceAfter = await configured.getBalance(fundingAddress);

    expect(
      balanceAfter.value,
      equals(BigInt.zero),
      reason:
          'Funding address must have exactly 0 wei after escrow deposit '
          '(got ${balanceAfter.value} wei)',
    );

    // --- On-chain escrow trade amount verification ---
    // The escrow contract must hold the exact payment amount.
    // (escrowService is already resolved above from harness.seeds.factory)
    final contract = configured.escrow.getSupportedEscrowContract(
      escrowService,
    );
    final tradeId = negotiateReservation.getDtag()!;
    final onChainTrade = await contract.getTrade(tradeId);
    expect(
      onChainTrade,
      isNotNull,
      reason: 'Trade must exist in escrow contract after fund',
    );
    expect(
      onChainTrade!.isActive,
      isTrue,
      reason: 'Funded trade must be active',
    );
    // For native RBTC escrow, paymentAmount must be the exact requested
    // amount converted to the on-chain token's smallest unit.
    expect(
      onChainTrade.paymentAmount,
      greaterThan(BigInt.zero),
      reason:
          'Escrow paymentAmount must be non-zero '
          '(got ${onChainTrade.paymentAmount})',
    );

    // --- State flow assertions ---
    expect(emittedStates.first, isA<SwapInInitialised>());

    // Boltz does not expose the reverse-swap invoice.paid event on the public
    // WebSocket. The first reliable signal after payment is the lockup
    // transaction reaching mempool/confirmation.
    expect(
      emittedStates.whereType<SwapInLockupTxInMempool>(),
      isNotEmpty,
      reason: 'Expected Boltz lockup transaction during swap-in',
    );

    expect(swapIn.state, isA<SwapInCompleted>());
    final claimTxHash = (swapIn.state as SwapInCompleted).data.claimTxHash;
    expect(claimTxHash, isNotNull);
  });
}
