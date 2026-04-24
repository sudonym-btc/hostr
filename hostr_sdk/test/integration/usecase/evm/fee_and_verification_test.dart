/// Integration tests for swap-in, swap-out, and escrow-fund operations
/// covering both native (RBTC) and ERC-20 (tBTC) tokens.
///
/// Each test verifies the fee breakdown returned by `estimateFees()` for
/// sanity: gas fees > 0, swap fees > 0 where applicable, and escrow fees > 0
/// for escrow operations.
///
/// The escrow-fund test additionally broadcasts a self-signed reservation
/// with a real on-chain escrow deposit and verifies it via
/// [EscrowVerification.verify].
///
/// Prerequisites:
///   - Anvil running on https://arbitrum.hostr.development (chain-id 412346)
///   - Nostr relay at wss://relay.hostr.development
///   - Boltz at https://boltz.hostr.development/v2
///   - AlbyHub at https://alby.hostr.development
///   - MultiEscrow contract deployed
@Tags(['integration', 'docker'])
library;

import 'dart:convert';
import 'dart:math';

import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/datasources/contracts/boltz/TestERC20.g.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../support/evm_test_helpers.dart';
import '../../../support/integration_test_harness.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Escrow proof builders (for self-signed reservation)
// ═══════════════════════════════════════════════════════════════════════════

/// Builds a signed [EscrowMethod] event published by [host], containing:
/// - escrow type (`evm`)
/// - contract bytecode hash from [escrowService]
/// - trusted escrow pubkey from [escrowService]
/// - accepted payment forms for the host
EscrowMethod _buildSignedEscrowMethod({
  required KeyPair host,
  required EscrowService escrowService,
  required List<AcceptedPaymentForm> acceptedPaymentForms,
  String? contractBytecodeHashOverride,
  List<String>? trustedEscrowPubkeys,
}) {
  final bytecodeHash =
      contractBytecodeHashOverride ?? escrowService.contractBytecodeHash;
  final trustedPubkeys = trustedEscrowPubkeys ?? [escrowService.pubKey];
  final event = Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      pubKey: host.publicKey,
      kind: kNostrKindEscrowMethod,
      tags: [
        ['d', 'escrow-method'],
        ['t', 'evm'],
        ['c', bytecodeHash],
        for (final pubkey in trustedPubkeys) ['p', pubkey],
        for (final form in acceptedPaymentForms) form.toTag(),
      ],
      content: '',
      createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
    ),
    privateKey: host.privateKey!,
  );
  return EscrowMethod.fromNostrEvent(event);
}

/// Builds a signed profile event for a host.
Nip01Event _buildSignedProfile({required KeyPair key}) {
  final meta = <String, dynamic>{
    'name': 'test-user-${key.publicKey.substring(0, 6)}',
  };
  final unsigned = Nip01Event(
    pubKey: key.publicKey,
    kind: 0,
    tags: const [],
    content: jsonEncode(meta),
    createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
  );
  return Nip01Utils.signWithPrivateKey(
    event: unsigned,
    privateKey: key.privateKey!,
  );
}

/// Builds a self-signed commit reservation with a [PaymentProof].
Reservation _buildSelfSignedCommit({
  required Reservation negotiate,
  required Listing listing,
  required KeyPair buyer,
  required PaymentProof proof,
}) {
  return Reservation.create(
    pubKey: buyer.publicKey,
    dTag: negotiate.getDtag()!,
    listingAnchor: listing.anchor!,
    start: negotiate.start,
    end: negotiate.end,
    stage: ReservationStage.commit,
    quantity: negotiate.quantity,
    amount: negotiate.amount,
    proof: proof,
    createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
  ).signAs(buyer, Reservation.fromNostrEvent);
}

// ═══════════════════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  //  1) Swap In — Native (RBTC)
  // ─────────────────────────────────────────────────────────────────────────
  group('swap in native (RBTC) with fee sanity', () {
    late IntegrationTestHarness harness;

    setUpAll(() async {
      await IntegrationTestHarness.clearBoltzPendingEvmTransactions();
      harness = await IntegrationTestHarness.create(
        name: 'hostr_swap_in_rbtc_fees_it',
        logLevel: Level.warning,
      );
    });

    tearDownAll(() async {
      await harness.dispose();
      IntegrationTestHarness.resetLogLevel();
    });

    test('swap in RBTC estimates sane fees and completes', () async {
      final hostr = harness.hostr;
      final evm = hostr.evm;
      await harness.signInAndConnectNwc(
        user: harness.seeds.deriveKeyPair(Random().nextInt(1000000)),
        appNamePrefix: 'swap-in-rbtc-fee-it',
      );

      final configured = evm.getChainById('rootstock-regtest')!;
      final evmKey = await hostr.auth.hd.getActiveEvmKey();
      await harness.anvilRootstock.setBalance(
        address: evmKey.address.eip55With0x,
        amountWei: rbtcFromSats(BigInt.from(1000000)).getInWei,
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
          evmKey: evmKey,
          accountIndex: 0,
          amountSpec: AmountSpec.output(amount),
        ),
      );

      // ── Fee estimation ──
      final quote = await configured.swapInQuote(params: swapIn.params);
      expectSwapFees(quote.feeBreakdown);

      // ── Execute and verify completion ──
      final emittedStates = <SwapInState>[swapIn.state];
      final sub = swapIn.stream.listen(emittedStates.add);
      await swapIn.execute();
      await sub.cancel();

      expect(swapIn.state, isA<SwapInCompleted>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  2) Swap In — ERC-20 (tBTC)
  // ─────────────────────────────────────────────────────────────────────────
  group('swap in ERC-20 (tBTC) with fee sanity', () {
    late IntegrationTestHarness harness;

    setUpAll(() async {
      await IntegrationTestHarness.clearBoltzPendingEvmTransactions();
      harness = await IntegrationTestHarness.create(
        name: 'hostr_swap_in_tbtc_fees_it',
        logLevel: Level.warning,
      );
    });

    tearDownAll(() async {
      await harness.dispose();
      IntegrationTestHarness.resetLogLevel();
    });

    test('swap in tBTC estimates sane fees and completes', () async {
      final hostr = harness.hostr;
      final evm = hostr.evm;
      await harness.signInAndConnectNwc(
        user: harness.seeds.deriveKeyPair(Random().nextInt(1000000)),
        appNamePrefix: 'swap-in-tbtc-fee-it',
      );

      final configured = evm.configuredChains.first;
      final boltzTokens = configured.swaps!.chainInfo.tokens;

      // Use the first Boltz-discovered ERC-20 token (typically tBTC).
      final tokenEntry = boltzTokens.entries.first;
      final tokenAddress = tokenEntry.value;
      final tokenName = tokenEntry.key;
      print('Using Boltz ERC-20 token: $tokenName at $tokenAddress');

      final swapLimits = await configured.swaps!.getSwapInLimits(
        tokenAddress: tokenAddress,
      );

      // Build a Token with 18 decimals (tBTC uses 18).
      final tbtcToken = Token(
        chainId: configured.config.chainId,
        address: tokenAddress.eip55With0x,
        decimals: 18,
      );
      expect(tbtcToken.isERC20, isTrue);

      final amount =
          TokenAmount.fromDenominated(swapLimits.min, tbtcToken) +
          TokenAmount(
            value: BigInt.from(1000) * BigInt.from(10).pow(10),
            token: tbtcToken,
          );

      final swapIn = configured.swapIn(
        params: SwapInParams(
          evmKey: await hostr.auth.hd.getActiveEvmKey(),
          accountIndex: 0,
          amountSpec: AmountSpec.output(amount),
        ),
      );

      // ── Fee estimation ──
      final quote = await configured.swapInQuote(params: swapIn.params);
      expectSwapFees(quote.feeBreakdown);

      // ── Execute and verify completion ──
      final emittedStates = <SwapInState>[swapIn.state];
      final sub = swapIn.stream.listen(emittedStates.add);
      await swapIn.execute();
      await sub.cancel();

      expect(swapIn.state, isA<SwapInCompleted>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  3) Swap Out — Native (RBTC)
  // ─────────────────────────────────────────────────────────────────────────
  group('swap out native (RBTC) with fee sanity', () {
    late IntegrationTestHarness harness;

    setUpAll(() async {
      harness = await IntegrationTestHarness.create(
        name: 'hostr_swap_out_rbtc_fees_it',
        logLevel: Level.warning,
        cleanHydratedStorage: true,
      );
    });

    tearDownAll(() async {
      await harness.dispose();
      IntegrationTestHarness.resetLogLevel();
    });

    test('swap out RBTC estimates sane fees and completes', () async {
      final hostr = harness.hostr;
      await harness.signInAndConnectNwc(
        user: harness.fundedKeys[0],
        appNamePrefix: 'swap-out-rbtc-fee-it',
      );

      await harness.anvilRootstock.setBalance(
        address: (await hostr.auth.hd.getActiveEvmKey()).address.eip55With0x,
        amountWei: rbtcFromSats(BigInt.from(1000000)).getInWei,
      );

      await hostr.evm.init();
      final rskChain = hostr.evm.getChainById('rootstock-regtest')!;
      final userKey = await hostr.auth.hd.getActiveEvmKey();

      // Use a specific amount well below the balance to avoid the
      // full-balance edge case where the EOA gas buffer in _sendEoaCalls
      // (20% + 10 000) pushes lock + gas above the available balance.
      final nativeToken = Token.native(rskChain.config.chainId);
      final requestedAmount = TokenAmount(
        value: rbtcFromSats(BigInt.from(500000)).getInWei,
        token: nativeToken,
      );

      final swapOut = rskChain.swapOut(
        params: SwapOutParams(
          evmKey: userKey,
          accountIndex: 0,
          amountSpec: AmountSpec.input(requestedAmount),
        ),
      );

      // ── Fee estimation ──
      final quote = await rskChain.swapOutQuote(params: swapOut.params);
      expectSwapFees(quote.feeBreakdown);

      expect(quote.sendAmount.value, greaterThan(BigInt.zero));
      expect(quote.receiveAmount.value, greaterThan(BigInt.zero));
      print('  balance: ${quote.sendAmount}');
      print('  invoiceAmount: ${quote.receiveAmount}');

      // ── Execute and verify completion ──
      final emittedStates = <SwapOutState>[swapOut.state];
      final sub = swapOut.stream.listen(emittedStates.add);
      await swapOut.execute();
      await sub.cancel();

      expect(swapOut.state, isA<SwapOutCompleted>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  4) Swap Out — ERC-20 (tBTC)
  // ─────────────────────────────────────────────────────────────────────────
  group('swap out ERC-20 (tBTC) with fee sanity', () {
    late IntegrationTestHarness harness;
    late Web3Client web3;

    setUpAll(() async {
      harness = await IntegrationTestHarness.create(
        name: 'hostr_swap_out_tbtc_fees_it',
        seed: DateTime.now().microsecondsSinceEpoch,
        logLevel: Level.debug,
        cleanHydratedStorage: true,
      );
      web3 = Web3Client(IntegrationTestHarness.anvilRpc, http.Client());
    });

    tearDownAll(() async {
      web3.dispose();
      await harness.dispose();
      IntegrationTestHarness.resetLogLevel();
    });

    test('swap out tBTC estimates sane fees and completes', () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;

      await harness.signInAndConnectNwc(
        user: harness.fundedKeys[0],
        appNamePrefix: 'swap-out-tbtc-fee-it',
      );
      await hostr.evm.init();

      final configured = hostr.evm.configuredChains.first;
      final boltzTokens = configured.swaps!.chainInfo.tokens;
      // Fund HD #0 with native gas + ERC-20 tokens.
      final userKey = await hostr.auth.hd.getActiveEvmKey();
      // Resolve the smart-account address (differs from EOA when AA is
      // configured, which is the case on arbitrum-regtest).
      final smartAccountAddr = await configured.getAccountAddress(userKey);
      await anvil.setBalance(
        address: userKey.address.eip55With0x,
        amountWei: rbtcFromSats(BigInt.from(500000)).getInWei,
      );
      // The AA UserOp sender is the smart account — fund it with native
      // gas as well so the EntryPoint can pre-fund execution.
      await anvil.setBalance(
        address: smartAccountAddr.eip55With0x,
        amountWei: rbtcFromSats(BigInt.from(500000)).getInWei,
      );

      await anvil.setBalance(
        address: anvilDeployerKey.address.eip55With0x,
        amountWei: BigInt.from(10).pow(18),
      );

      final tokenEntry = boltzTokens.entries.first;
      final tokenContract = TestERC20(address: tokenEntry.value, client: web3);
      final mintAmount = BigInt.from(200000) * BigInt.from(10).pow(10);
      // Fund the EOA so _getSwapBalance (used by estimateFees) sees tokens.
      await waitForReceipt(
        web3,
        await tokenContract.transfer((
          to: userKey.address,
          value: mintAmount,
        ), credentials: anvilDeployerKey),
      );
      // Fund the smart account so the AA UserOp can transferFrom during
      // the ERC20Swap.lock step.
      await waitForReceipt(
        web3,
        await tokenContract.transfer((
          to: smartAccountAddr,
          value: mintAmount,
        ), credentials: anvilDeployerKey),
      );

      final tbtcToken = Token(
        chainId: configured.config.chainId,
        address: tokenEntry.value.eip55With0x,
        decimals: 18,
      );
      final requestedAmount = TokenAmount(
        value: BigInt.from(60000) * BigInt.from(10).pow(10),
        token: tbtcToken,
      );

      final erc20Op = configured.swapOut(
        params: SwapOutParams(
          evmKey: userKey,
          accountIndex: 0,
          amountSpec: AmountSpec.input(requestedAmount),
        ),
      );

      // ── Fee estimation ──
      final quote = await configured.swapOutQuote(params: erc20Op.params);
      expectSwapFees(quote.feeBreakdown);

      expect(quote.sendAmount.value, greaterThan(BigInt.zero));
      expect(quote.receiveAmount.value, greaterThan(BigInt.zero));
      print('  ERC-20 balance: ${quote.sendAmount}');
      print('  ERC-20 invoiceAmount: ${quote.receiveAmount}');

      // ── Execute and verify completion ──
      final emittedStates = <SwapOutState>[erc20Op.state];
      final sub = erc20Op.stream.listen(emittedStates.add);
      await erc20Op.execute();

      await sub.cancel();

      expect(erc20Op.state, isA<SwapOutCompleted>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  5) Escrow Fund — ERC-20 (tBTC) + Self-signed Reservation + Verification
  // ─────────────────────────────────────────────────────────────────────────
  group('escrow fund ERC-20 (tBTC) with fee sanity + verification', () {
    late IntegrationTestHarness harness;

    setUpAll(() async {
      harness = await IntegrationTestHarness.create(
        name: 'hostr_escrow_fund_tbtc_fees_it',
        seed: DateTime.now().microsecondsSinceEpoch,
        logLevel: Level.debug,
        cleanHydratedStorage: true,
      );
    });

    tearDownAll(() async {
      await harness.dispose();
      IntegrationTestHarness.resetLogLevel();
    });

    test(
      'escrow fund tBTC estimates sane fees, completes, and passes EscrowVerification',
      () async {
        final hostr = harness.hostr;
        final anvil = harness.anvil;

        // ── 1. Create trade fixtures + sign in with NWC ──
        // NWC is required because the escrow fund operation performs an
        // internal swap-in (reverse submarine swap via Boltz) which needs
        // the buyer's wallet to settle a Lightning invoice.
        final trade = await harness.seeds.freshTrade(hostHasEvm: true);
        await harness.signInAndConnectNwc(
          user: trade.guest.keyPair,
          appNamePrefix: 'escrow-fund-tbtc-fee-it',
        );

        // ── 2. Resolve escrow contract + service ──
        // Compute the real bytecode hash of the deployed MultiEscrow
        // contract so both the EscrowService and the host's EscrowMethod
        // carry the correct value for EscrowVerification.
        await hostr.evm.init();
        final configured = hostr.evm.configuredChains.first;
        final realBytecodeHash =
            await SupportedEscrowContractRegistry.bytecodeHashForAddress(
              configured,
              EthereumAddress.fromHex(
                env.evmConfig.chains.first.escrowContractAddress!,
              ),
            );
        print('  Real contract bytecode hash: $realBytecodeHash');

        final escrowService = (await harness.seeds.factory.buildEscrowServices(
          contractAddress: env.evmConfig.chains.first.escrowContractAddress!,
          multiEscrowBytecodeHash: realBytecodeHash,
        )).first;

        final negotiateReservation = trade.negotiateReservation;
        final sellerProfile = trade.sellerProfile;

        // ── 3. Estimate fees before executing ──
        // No manual ERC-20 funding is needed — the operation conducts a
        // swap-in via Boltz to bring the required tBTC amount on-chain.
        final preparer = hostr.escrow.fund(
          EscrowFundParams(
            escrowService: escrowService,
            negotiateReservation: negotiateReservation,
            sellerProfile: sellerProfile,
            sellerEvmAddress: trade.sellerEvmAddress,
            amount: negotiateReservation.amount!,
            dexInputBuffer: SwapInDexBuffer.zero,
          ),
        );

        final fees = await preparer.estimateFees();
        expectEscrowFees(fees);

        // ── 4. Prepare, fund the derived account with gas, and run swap-in ──
        final swapInParams = await preparer.prepare();
        final fundingKey = await hostr.auth.hd.getActiveEvmKey(
          accountIndex: preparer.accountIndex,
        );
        await anvil.setBalance(
          address: fundingKey.address.eip55With0x,
          amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
        );

        final swapIn = configured.swapIn(params: swapInParams);
        final emittedStates = <SwapInState>[swapIn.state];
        final sub = swapIn.stream.listen(emittedStates.add);

        await swapIn.execute();
        emittedStates.add(swapIn.state);
        await sub.cancel();

        // ── 5. Verify state flow ──
        expect(emittedStates.first, isA<SwapInInitialised>());
        expect(swapIn.state, isA<SwapInCompleted>());

        final completed = swapIn.state as SwapInCompleted;
        final txHash = completed.data.claimTxHash;
        expect(txHash, isNotNull);

        // ── 6. Build self-signed reservation with escrow proof ──
        final hostKeyPair = trade.host.keyPair;
        final listing = trade.listing;
        final hosterProfile = _buildSignedProfile(key: hostKeyPair);
        final bridgeToken = await configured.resolveBridgeToken();
        final acceptedPaymentForms = <AcceptedPaymentForm>[
          AcceptedPaymentForm(
            denomination: 'BTC',
            tokenTagId: Token.native(configured.config.chainId).tagId,
          ),
          AcceptedPaymentForm(
            denomination: 'BTC',
            tokenTagId: bridgeToken.tagId,
          ),
        ];
        final escrowMethod = _buildSignedEscrowMethod(
          host: hostKeyPair,
          escrowService: escrowService,
          acceptedPaymentForms: acceptedPaymentForms,
        );

        // Use the actual trade's negotiate reservation for the commit —
        // its dTag is the trade ID that was funded on-chain. Building a
        // new reservation with a different dTag would not match.
        final proof = PaymentProof(
          hoster: hosterProfile,
          listing: listing,
          zapProof: null,
          escrowProof: EscrowProof(
            txHash: txHash!,
            escrowService: escrowService,
            hostsEscrowMethods: escrowMethod,
          ),
        );

        final commit = _buildSelfSignedCommit(
          negotiate: negotiateReservation,
          listing: listing,
          buyer: trade.guest.keyPair,
          proof: proof,
        );

        // ── 7. Run EscrowVerification.verify ──
        final verification = EscrowVerification(
          evm: hostr.evm,
          logger: CustomLogger(),
        );
        final result = await verification.verify(reservation: commit);

        print('  EscrowVerification result: $result');
        expect(
          result.isValid,
          isTrue,
          reason:
              'Self-signed reservation with real on-chain escrow deposit '
              'should pass verification. Got: ${result.reason}',
        );
        expect(result.fundedEvent, isNotNull);
      },
    );
  });
}
