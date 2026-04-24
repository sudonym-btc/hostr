/// Integration tests covering the USDT ↔ DEX swap-in / escrow / swap-out paths.
///
/// Four scenarios:
///   1. Fund escrow with USDT via DEX swap-in (Lightning → tBTC → DEX → USDT → escrow)
///   2. Verify correct USDT amount recorded on-chain after the swap-in
///   3. Arbitrate (release) a USDT escrow trade
///   4. Swap out USDT via DEX hop (USDT → DEX → tBTC → Boltz submarine → Lightning)
@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/datasources/contracts/boltz/TestERC20.g.dart';
import 'package:hostr_sdk/datasources/contracts/escrow/MultiEscrow.g.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/payments/constants.dart';
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../support/evm_test_helpers.dart';
import '../../../support/integration_test_harness.dart';

// ── Chain constants ────────────────────────────────────────────────────────

const _chainId = 412346; // arbitrum-regtest

/// Checksummed USDT address from the test environment config.
String get _usdtAddress => env.evmConfig.chains.first.tokens['USDT']!.address;

/// A 5 USD amount expressed in micro-dollars (USDT 6-decimal units).
DenominatedAmount _usd(int dollars) => DenominatedAmount(
  denomination: 'USD',
  value: BigInt.from(dollars) * BigInt.from(1000000),
  decimals: 6,
);

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1 + 2 — Fund via DEX swap-in and verify on-chain USDT amount
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('USDT DEX escrow fund via swap-in', () {
    late IntegrationTestHarness harness;

    setUpAll(() async {
      await IntegrationTestHarness.clearBoltzPendingEvmTransactions();
      harness = await IntegrationTestHarness.create(
        name: 'hostr_usdt_fund_swap_it',
        seed: DateTime.now().microsecondsSinceEpoch,
        logLevel: Level.warning,
        cleanHydratedStorage: true,
      );
    });

    tearDownAll(() async {
      await harness.dispose();
      IntegrationTestHarness.resetLogLevel();
    });

    test('swap-in state flow completes (fund with USDT)', () async {
      final hostr = harness.hostr;
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);
      await harness.signInAndConnectNwc(
        user: trade.guest.keyPair,
        appNamePrefix: 'usdt-fund-swap-it',
      );

      final escrowService = await _resolveEscrowService(harness);
      final sellerEscrowMethod = await _buildUsdtEscrowMethod(harness, trade);
      final amount = _usd(5); // 5 USD → 5_000_000 USDT units (6-dec)

      final preparer = hostr.escrow.fund(
        EscrowFundParams(
          escrowService: escrowService,
          negotiateReservation: trade.negotiateReservation,
          sellerProfile: trade.sellerProfile,
          sellerEvmAddress: trade.sellerEvmAddress,
          amount: amount,
          sellerEscrowMethod: sellerEscrowMethod,
          dexInputBuffer: SwapInDexBuffer.zero,
        ),
      );

      final swapInParams = await preparer.prepare();
      final configured = preparer.configuredChain;

      final swapIn = configured.swapIn(params: swapInParams);

      final emittedStates = <SwapInState>[swapIn.state];
      final sub = swapIn.stream.listen(emittedStates.add);

      await swapIn.execute();
      emittedStates.add(swapIn.state);
      await sub.cancel();

      // ── State flow assertions ─────────────────────────────────────────
      expect(
        emittedStates.first,
        isA<SwapInInitialised>(),
        reason: 'First emitted state must be SwapInInitialised',
      );
      expect(
        emittedStates.whereType<SwapInLockupTxInMempool>(),
        isNotEmpty,
        reason: 'Boltz lockup transaction must be observed during USDT swap-in',
      );
      expect(
        swapIn.state,
        isA<SwapInCompleted>(),
        reason: 'Swap-in must reach SwapInCompleted terminal state',
      );

      final claimTxHash = (swapIn.state as SwapInCompleted).data.claimTxHash;
      expect(
        claimTxHash,
        isNotNull,
        reason: 'Completed swap-in must carry an on-chain claim tx hash',
      );
    });

    test(
      'on-chain escrow trade has correct USDT token and payment amount',
      () async {
        final hostr = harness.hostr;
        final trade = await harness.seeds.freshTrade(hostHasEvm: true);
        await harness.signInAndConnectNwc(
          user: trade.guest.keyPair,
          appNamePrefix: 'usdt-verify-amount-it',
        );

        final escrowService = await _resolveEscrowService(harness);
        final sellerEscrowMethod = await _buildUsdtEscrowMethod(harness, trade);
        // 5 USD = 5_000_000 in 6-decimal USDT units.
        // scaleToToken(USD/6-dec, USDT/6-dec) → scale=0 → value unchanged.
        const usdDollars = 5;
        final amount = _usd(usdDollars);
        final expectedUsdtUnits = amount.value; // 5_000_000

        final preparer = hostr.escrow.fund(
          EscrowFundParams(
            escrowService: escrowService,
            negotiateReservation: trade.negotiateReservation,
            sellerProfile: trade.sellerProfile,
            sellerEvmAddress: trade.sellerEvmAddress,
            amount: amount,
            sellerEscrowMethod: sellerEscrowMethod,
            dexInputBuffer: SwapInDexBuffer.zero,
          ),
        );

        final swapInParams = await preparer.prepare();
        final configured = preparer.configuredChain;

        final swapIn = configured.swapIn(params: swapInParams);

        await swapIn.execute();

        expect(
          swapIn.state,
          isA<SwapInCompleted>(),
          reason: 'Swap-in must complete before verifying on-chain state',
        );

        // ── On-chain trade assertions ─────────────────────────────────────
        final contract = configured.escrow.getSupportedEscrowContract(
          escrowService,
        );
        final tradeId = trade.negotiateReservation.getDtag()!;
        final onChainTrade = await contract.getTrade(tradeId);

        expect(
          onChainTrade,
          isNotNull,
          reason: 'Trade must be present in the escrow contract',
        );
        expect(
          onChainTrade!.isActive,
          isTrue,
          reason: 'Funded trade must be active',
        );
        // The token field must point to USDT — not native or tBTC.
        expect(
          onChainTrade.token.eip55With0x.toLowerCase(),
          equals(_usdtAddress.toLowerCase()),
          reason:
              'Escrow trade token must be USDT ($_usdtAddress), '
              'not native or tBTC. Got: ${onChainTrade.token.eip55With0x}',
        );
        // paymentAmount must equal 5_000_000 (5 USDT in 6-decimal units).
        // This is the regression guard for the lock-amount scaling bug that
        // previously delivered tBTC-scaled wei instead of USDT units.
        expect(
          onChainTrade.paymentAmount,
          equals(expectedUsdtUnits),
          reason:
              'Payment amount must be $expectedUsdtUnits USDT units (6-dec). '
              'Got: ${onChainTrade.paymentAmount}',
        );

        // ── Wei-perfect: smart account USDT balance should be negligible ──
        // The DEX swap may deliver slightly more USDT than quoted due to
        // Uniswap V3 price improvement. The escrow contract only pulls the
        // exact paymentAmount, so a tiny surplus can remain. Allow up to
        // 1 000 units (0.001 USDT with 6-decimal precision).
        final evmKey = await hostr.auth.hd.getActiveEvmKey();
        final smartAccountAddress = await configured.getAccountAddress(evmKey);
        final usdtBalanceAfter = await configured.getERC20Balance(
          smartAccountAddress,
          EthereumAddress.fromHex(_usdtAddress),
        );
        expect(
          usdtBalanceAfter.value,
          lessThan(BigInt.from(1000)),
          reason:
              'Smart account USDT balance must be < 1000 units (0.001 USDT) '
              'after escrow deposit (got ${usdtBalanceAfter.value})',
        );
      },
    );
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3 — Arbitrate (release) a directly-funded USDT escrow trade
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('USDT escrow arbitration (release)', () {
    late IntegrationTestHarness harness;
    late Web3Client web3;

    setUpAll(() async {
      harness = await IntegrationTestHarness.create(
        name: 'hostr_usdt_arbitrate_it',
        seed: DateTime.now().microsecondsSinceEpoch,
        logLevel: Level.warning,
        cleanHydratedStorage: true,
      );
      web3 = Web3Client(IntegrationTestHarness.anvilRpc, http.Client());
    });

    tearDownAll(() async {
      web3.dispose();
      await harness.dispose();
      IntegrationTestHarness.resetLogLevel();
    });

    test('buyer releases USDT trade to seller and trade is removed', () async {
      final hostr = harness.hostr;
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);

      // Sign in as buyer (guest).  The release actor must be the buyer.
      await hostr.auth.signin(trade.guest.privateKey);

      final escrowService = await _resolveEscrowService(harness);
      final tradeId = trade.negotiateReservation.getDtag()!;

      // Fund the escrow directly with the Boltz USDT token so we bypass
      // the swap-in and focus on the release path.
      await _fundUsdtEscrowDirectly(
        harness: harness,
        web3: web3,
        hostr: hostr,
        trade: trade,
        escrowService: escrowService,
      );

      final chain = hostr.evm.getChainForEscrowService(escrowService);
      final contract = chain.escrow.getSupportedEscrowContract(escrowService);

      // Verify the trade was funded with USDT before releasing.
      final fundedTrade = await contract.getTrade(tradeId);
      expect(
        fundedTrade,
        isNotNull,
        reason: 'Trade must be funded in escrow before release',
      );
      expect(fundedTrade!.isActive, isTrue);
      expect(
        fundedTrade.token.eip55With0x.toLowerCase(),
        equals(_usdtAddress.toLowerCase()),
        reason: 'Funded trade must use the USDT token',
      );

      // ── Execute release ───────────────────────────────────────────────
      final operation = hostr.escrow.release(
        EscrowReleaseParams(escrowService: escrowService, tradeId: tradeId),
      );

      final emittedStates = <OnchainOperationState>[operation.state];
      final sub = operation.stream.listen(emittedStates.add);

      await operation.execute();
      emittedStates.add(operation.state);
      await sub.cancel();

      // ── State assertions ──────────────────────────────────────────────
      expect(
        emittedStates.first,
        isA<OnchainInitialised>(),
        reason: 'First emitted state must be OnchainInitialised',
      );
      expect(
        operation.state,
        isA<OnchainTxConfirmed>(),
        reason: 'Release must reach OnchainTxConfirmed terminal state',
      );
      expect(emittedStates.whereType<OnchainTxConfirmed>(), isNotEmpty);

      final confirmed = operation.state as OnchainTxConfirmed;
      expect(confirmed.data.txHash, isNotNull);
      expect(confirmed.data.transactionReceipt, isNotNull);
      expect(
        isReceiptSuccessful(confirmed.data.transactionReceipt!),
        isTrue,
        reason: 'Release transaction must succeed',
      );

      // ── On-chain post-condition ───────────────────────────────────────
      // The MultiEscrow contract deletes the trade after a successful release.
      final releasedTrade = await contract.getTrade(tradeId);
      expect(
        releasedTrade,
        isNull,
        reason: 'Trade must be removed from the escrow contract after release',
      );
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 4 — Swap out USDT via DEX hop (USDT → tBTC → Boltz submarine → LN)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('USDT swap-out via DEX hop', () {
    late IntegrationTestHarness harness;
    late Web3Client web3;

    setUpAll(() async {
      await IntegrationTestHarness.clearBoltzPendingEvmTransactions();
      harness = await IntegrationTestHarness.create(
        name: 'hostr_usdt_swap_out_it',
        seed: DateTime.now().microsecondsSinceEpoch,
        logLevel: Level.warning,
        cleanHydratedStorage: true,
      );
      web3 = Web3Client(IntegrationTestHarness.anvilRpc, http.Client());
    });

    tearDownAll(() async {
      web3.dispose();
      await harness.dispose();
      IntegrationTestHarness.resetLogLevel();
    });

    test('swaps USDT to Lightning via DEX tBTC hop and completes', () async {
      final hostr = harness.hostr;

      await harness.signInAndConnectNwc(
        user: harness.fundedKeys[0],
        appNamePrefix: 'usdt-swap-out-it',
      );

      final userKey = await hostr.auth.hd.getActiveEvmKey();

      // Fund user's address with gas.
      await harness.anvil.setBalance(
        address: userKey.address.eip55With0x,
        amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
      );

      // Fund the Anvil deployer key (holds initial USDT supply) with gas.
      await harness.anvil.setBalance(
        address: anvilDeployerKey.address.eip55With0x,
        amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
      );

      // Resolve the AA smart account address — the UserOp executes from
      // the smart account, so USDT must live there, not in the raw EOA.
      final smartAccountAddress = await hostr.evm.configuredChains.first
          .getAccountAddress(userKey);

      // Transfer USDT from the deployer to the smart account.
      // The Boltz regtest Docker stack deploys USDT via the deployer key,
      // so the deployer holds the initial supply.
      final usdtContract = TestERC20(
        address: EthereumAddress.fromHex(_usdtAddress),
        client: web3,
      );
      final usdtDecimals = (await usdtContract.decimals()).toInt();

      // 50 USDT — the regtest DEX prices BTC very low (~$1 400/BTC), so 10 USDT
      // only swaps to ~14 000 sats which is below Boltz's 50 000-sat minimum.
      // 50 USDT gives ~70 000 sats, clearing the minimum comfortably.
      final mintAmount = BigInt.from(50) * BigInt.from(10).pow(usdtDecimals);

      await waitForReceipt(
        web3,
        await usdtContract.transfer((
          to: smartAccountAddress,
          value: mintAmount,
        ), credentials: anvilDeployerKey),
      );

      // Verify the transfer landed at the smart account.
      final usdtBalance = await usdtContract.balanceOf((
        account: smartAccountAddress,
      ));
      expect(
        usdtBalance,
        greaterThanOrEqualTo(mintAmount),
        reason: 'User must hold USDT before swap-out',
      );

      // Build a TokenAmount for the full USDT balance.
      final usdtToken = Token(
        chainId: _chainId,
        address: _usdtAddress,
        decimals: usdtDecimals,
      );
      final usdtAmount = TokenAmount(value: mintAmount, token: usdtToken);

      // ── Execute swap-out ──────────────────────────────────────────────
      // The SwapQuoteService detects that usdtToken is not the Boltz bridge
      // token and routes the swap via the UniversalRouter DEX:
      //   USDT → tBTC (DEX) → tBTC lockup → Boltz submarine → Lightning
      final arbChain = hostr.evm.configuredChains.first;

      final swapOut = arbChain.swapOut(
        params: SwapOutParams(
          evmKey: userKey,
          accountIndex: 0,
          amountSpec: AmountSpec.input(usdtAmount),
        ),
      );

      final emittedStates = <SwapOutState>[swapOut.state];
      final sub = swapOut.stream.listen(emittedStates.add);

      await swapOut.execute();
      await sub.cancel();

      // ── State flow assertions ─────────────────────────────────────────
      expect(
        emittedStates.first,
        isA<SwapOutInitialised>(),
        reason: 'First emitted state must be SwapOutInitialised',
      );
      expect(
        emittedStates.any((s) => s is SwapOutAwaitingOnChain),
        isTrue,
        reason: 'Swap-out must reach on-chain funding step',
      );
      expect(
        emittedStates.any((s) => s is SwapOutFunded),
        isTrue,
        reason: 'Swap-out must confirm tBTC lockup on-chain',
      );
      // Use the synchronous state getter for the terminal check — the
      // broadcast StreamController delivers stream events via microtasks so
      // emittedStates.last may lag behind.
      expect(
        swapOut.state,
        isA<SwapOutCompleted>(),
        reason: 'Swap-out must reach SwapOutCompleted terminal state',
      );

      // ── Wei-perfect: smart account USDT balance should be negligible ───
      // The DEX hop converts USDT → tBTC for the Boltz submarine swap.
      // Uniswap V3 may not consume 100% of the input USDT due to tick
      // boundaries or rounding, so a tiny residual can remain. Allow up to
      // 1 000 units (0.001 USDT with 6-decimal precision).
      final usdtBalanceAfter = await arbChain.getERC20Balance(
        smartAccountAddress,
        EthereumAddress.fromHex(_usdtAddress),
      );
      expect(
        usdtBalanceAfter.value,
        lessThan(BigInt.from(1000)),
        reason:
            'Smart account USDT balance must be < 1000 units (0.001 USDT) '
            'after swap-out (got ${usdtBalanceAfter.value})',
      );
    });
  });
}

// ── Shared helpers ─────────────────────────────────────────────────────────

/// Resolves the mock [EscrowService] pointed at the regtest MultiEscrow
/// contract address.
Future<EscrowService> _resolveEscrowService(
  IntegrationTestHarness harness,
) async {
  return (await harness.seeds.factory.buildEscrowServices(
    contractAddress: env.evmConfig.chains.first.escrowContractAddress!,
  )).first;
}

/// Builds a signed [EscrowMethod] for the trade's host that declares:
///   USD → `_usdtAddress` (USDT on arbitrum-regtest, chainId 412346)
///
/// Passing this as [EscrowFundParams.sellerEscrowMethod] causes
/// [EscrowFundPreparer] to resolve USDT as the escrow token and route the
/// swap-in through the UniversalRouter DEX hop.
Future<EscrowMethod> _buildUsdtEscrowMethod(
  IntegrationTestHarness harness,
  TestTrade trade,
) {
  return harness.seeds.entities.escrowMethod(
    signer: trade.host.keyPair,
    usdtAddress: _usdtAddress,
    chainId: _chainId,
  );
}

/// Directly funds the MultiEscrow contract with the Boltz-deployed USDT
/// token, bypassing the swap-in.
///
/// Flow:
///   1. Fund [anvilDeployerKey] with gas (ETH).
///   2. Approve the escrow contract to spend USDT from [anvilDeployerKey].
///   3. Call `createTrade` from [anvilDeployerKey] with the guest's EOA as
///      the declared buyer — matching what [EscrowCall.signer] resolves to
///      when the buyer later calls release/claim.
Future<void> _fundUsdtEscrowDirectly({
  required IntegrationTestHarness harness,
  required Web3Client web3,
  required Hostr hostr,
  required TestTrade trade,
  required EscrowService escrowService,
}) async {
  final chain = hostr.evm.getChainForEscrowService(escrowService);
  final contract = chain.escrow.getSupportedEscrowContract(escrowService);
  final escrowAddress = contract.address;

  final usdtContract = TestERC20(
    address: EthereumAddress.fromHex(_usdtAddress),
    client: web3,
  );
  final usdtDecimals = (await usdtContract.decimals()).toInt();

  // Payment: 5 USDT in 6-decimal units.
  final paymentValue = BigInt.from(5) * BigInt.from(10).pow(usdtDecimals);
  final feeValue = escrowService.escrowFee(
    paymentValue,
    tokenAddress: _usdtAddress,
  );
  final totalNeeded = paymentValue + feeValue;

  // The deployer key holds the initial USDT supply (minted at deployment
  // by the Boltz Docker stack) and acts as the on-chain msg.sender.
  // The declared `buyer` is the guest's HD-derived EOA, matching the key
  // the EscrowCall operations sign with.
  final buyerAddress = (await deriveEvmKey(trade.guest.privateKey)).address;
  final sellerAddress = (await deriveEvmKey(trade.host.privateKey)).address;

  // Fund deployer with gas.
  await harness.anvil.setBalance(
    address: anvilDeployerKey.address.eip55With0x,
    amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
  );

  // Approve the escrow to pull USDT from the deployer.
  await waitForReceipt(
    web3,
    await usdtContract.approve((
      spender: escrowAddress,
      value: totalNeeded,
    ), credentials: anvilDeployerKey),
  );

  // Create the USDT trade on-chain.
  final multiEscrow = MultiEscrow(address: escrowAddress, client: web3);
  final txHash = await multiEscrow.createTrade(
    (
      tradeId: getBytes32(trade.negotiateReservation.getDtag()!),
      buyer: buyerAddress,
      seller: sellerAddress,
      arbiter: EthereumAddress.fromHex(escrowService.evmAddress),
      token: EthereumAddress.fromHex(_usdtAddress),
      paymentAmount: paymentValue,
      bondAmount: BigInt.zero,
      unlockAt: BigInt.from(
        trade.negotiateReservation.end!.millisecondsSinceEpoch ~/ 1000,
      ),
      escrowFee: feeValue,
    ),
    credentials: anvilDeployerKey,
    // ERC-20 createTrade: omit `value` so no native ETH is sent.
    // The contract pulls tokens via transferFrom(msg.sender, ...).
    transaction: Transaction(),
  );

  final receipt = await waitForReceipt(chain.client, txHash);
  expect(
    isReceiptSuccessful(receipt),
    isTrue,
    reason: 'Direct USDT escrow fund must succeed',
  );
}
