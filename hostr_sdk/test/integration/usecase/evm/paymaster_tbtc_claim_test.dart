/// Temporary integration test — remove once proven.
///
/// End-to-end test: Lightning BTC → tBTC reverse swap via Boltz,
/// claimed through a 4337 smart wallet sponsored by the mock paymaster.
///
/// The claimer has **zero native balance**. Gas is paid entirely by the
/// paymaster via the Pimlico mock-verifying-paymaster stack.
///
/// Uses the `IntegrationTestHarness` for config, NWC wallet connection,
/// and the generated `ERC20Swap` contract for ABI encoding. The 4337
/// account / UserOp layer uses `permissionless` directly.
@Tags(['integration', 'docker'])
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:hostr_sdk/datasources/boltz/boltz.dart';
import 'package:hostr_sdk/datasources/contracts/boltz/ERC20Swap.g.dart';
import 'package:hostr_sdk/datasources/swagger_generated/boltz.swagger.dart'
    hide Call;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:permissionless/permissionless.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

import '../../../support/integration_test_harness.dart';

// Swap amount in sats.
const _swapAmountSats = 100000;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Generate 32 random bytes as hex (no 0x prefix).
String _randomHex32() {
  final rng = Random.secure();
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  return hex.encode(bytes);
}

/// SHA-256 of raw bytes given hex string (no 0x prefix).
String _sha256Hex(String inputHex) {
  final bytes = Uint8List.fromList(hex.decode(inputHex));
  return crypto.sha256.convert(bytes).toString();
}

/// Call `balanceOf(address)` on a token contract via permissionless
/// PublicClient.
Future<BigInt> _tokenBalance(
  PublicClient pub,
  EthereumAddress token,
  EthereumAddress account,
) async {
  final selector = AbiEncoder.functionSelector('balanceOf(address)');
  final calldata = AbiEncoder.encodeFunctionCall(selector, [
    AbiEncoder.encodeAddress(account),
  ]);
  final result = await pub.call(Call(to: token, data: calldata));
  return BigInt.parse(Hex.strip0x(result), radix: 16);
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------
void main() {
  late IntegrationTestHarness harness;
  late Web3Client web3;

  // Config values resolved from env / harness config.
  late String rpcUrl;
  late String bundlerUrl;
  late String boltzApiUrl;
  late int chainId;
  late EthereumAddress entryPointAddress;
  late EthereumAddress accountFactoryAddress;

  // permissionless clients
  late PublicClient publicClient;
  late BundlerClient bundlerClient;
  late PaymasterClient paymasterClient;

  setUpAll(() async {
    IntegrationTestHarness.acceptSelfSignedCerts();
    await IntegrationTestHarness.clearBoltzPendingEvmTransactions();
    harness = await IntegrationTestHarness.create(
      name: 'hostr_paymaster_tbtc_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.warning,
    );

    final evmCfg = harness.hostr.config.evmConfig;
    final chainCfg = evmCfg.chains.first;
    final aa = chainCfg.accountAbstraction!;

    rpcUrl = chainCfg.rpcUrl;
    bundlerUrl = aa.bundlerUrl;
    boltzApiUrl = evmCfg.boltz!.apiUrl;
    chainId = chainCfg.chainId;
    entryPointAddress = EthereumAddress.fromHex(aa.entryPointAddress);
    accountFactoryAddress = EthereumAddress.fromHex(aa.accountFactoryAddress);

    web3 = Web3Client(rpcUrl, http.Client());
    publicClient = createPublicClient(url: rpcUrl);
    bundlerClient = createBundlerClient(
      url: bundlerUrl,
      entryPoint: entryPointAddress,
    );
    paymasterClient = createPaymasterClient(url: bundlerUrl);
  });

  tearDownAll(() async {
    publicClient.close();
    bundlerClient.close();
    paymasterClient.close();
    web3.dispose();
    await harness.dispose();
    IntegrationTestHarness.resetLogLevel();
  });

  test(
    'claim tBTC reverse swap through 4337 smart wallet with paymaster',
    () async {
      final hostr = harness.hostr;

      // ── 0. Sign in & connect NWC so we can pay the LN invoice ────────
      final user = harness.seeds.deriveKeyPair(Random().nextInt(1000000));
      await harness.signInAndConnectNwc(
        user: user,
        appNamePrefix: 'paymaster-tbtc-it',
      );
      final nwcConnection = hostr.nwc.getActiveConnection()!;

      // ── 1. Wait for Boltz tBTC pair to be ready ──────────────────────
      print('⏳ Waiting for Boltz tBTC pair fees …');
      final boltzSwagger = Boltz.create(baseUrl: Uri.parse(boltzApiUrl));
      Map<String, dynamic>? tbtcPair;
      for (var i = 0; i < 30; i++) {
        final res = await boltzSwagger.swapReverseGet();
        if (res.isSuccessful && res.body != null) {
          final decoded = res.body as Map<String, dynamic>;
          tbtcPair = decoded['BTC']?['tBTC'] as Map<String, dynamic>?;
          if (tbtcPair != null &&
              tbtcPair['fees'] != null &&
              (tbtcPair['fees'] as Map)['minerFees'] != null) {
            break;
          }
          tbtcPair = null;
        }
        await Future.delayed(const Duration(seconds: 5));
      }
      expect(tbtcPair, isNotNull, reason: 'tBTC pair never became available');
      print('✓ tBTC pair ready: minerFees=${tbtcPair!['fees']['minerFees']}');

      // ── 2. Resolve tBTC contract addresses from Boltz ────────────────
      final contractsRes = await boltzSwagger.chainCurrencyContractsGet(
        currency: 'tBTC',
      );
      expect(
        contractsRes.isSuccessful,
        isTrue,
        reason: 'Failed to fetch tBTC contracts',
      );
      final erc20SwapAddress = EthereumAddress.fromHex(
        contractsRes.body!.swapContracts.eRC20Swap!,
      );
      final tbtcTokenAddress = EthereumAddress.fromHex(
        contractsRes.body!.tokens.values.first,
      );
      print('  ERC20Swap:    ${erc20SwapAddress.checksummed}');
      print('  tBTC token:   ${tbtcTokenAddress.checksummed}');

      // Instantiate the generated ERC20Swap contract for encoding / reads.
      final erc20Swap = ERC20Swap(
        address: erc20SwapAddress,
        client: web3,
        chainId: chainId,
      );

      // ── 3. Generate a fresh owner key (ZERO native balance) ──────────
      final ownerPrivateKey = '0x${_randomHex32()}';
      final owner = PrivateKeyOwner(ownerPrivateKey);
      print('  Owner EOA:  ${owner.address.checksummed}');

      // ── 4. Create SimpleSmartAccount (counterfactual) ────────────────
      final account = createSimpleSmartAccount(
        owner: owner,
        chainId: BigInt.from(chainId),
        entryPointVersion: EntryPointVersion.v07,
        salt: BigInt.zero,
        customFactoryAddress: accountFactoryAddress,
        publicClient: publicClient,
      );

      final smartWallet = await account.getAddress();
      print('  Smart wallet: ${smartWallet.checksummed}');

      // Verify zero ETH balance
      final ethBalance = await publicClient.getBalance(smartWallet);
      expect(
        ethBalance,
        equals(BigInt.zero),
        reason: 'Smart wallet should start with zero ETH',
      );
      print('  ETH balance:  $ethBalance (zero as expected)');

      // ── 5. Generate preimage & hash ──────────────────────────────────
      final preimage = _randomHex32();
      final preimageHash = _sha256Hex(preimage);
      print('  Preimage:     ${preimage.substring(0, 16)}…');
      print('  Hash:         ${preimageHash.substring(0, 16)}…');

      // ── 6. Create reverse swap (BTC → tBTC) via Boltz ────────────────
      //    claimAddress = the smart wallet (msg.sender in the claim tx)
      final swapRes = await boltzSwagger.swapReversePost(
        body: ReverseRequest(
          from: 'BTC',
          to: 'tBTC',
          invoiceAmount: _swapAmountSats.toDouble(),
          preimageHash: preimageHash,
          claimAddress: smartWallet.checksummed,
        ),
      );
      expect(
        swapRes.isSuccessful,
        isTrue,
        reason: 'Swap creation failed: ${swapRes.error}',
      );

      final swap = swapRes.body!;
      final onchainAmount = swap.onchainAmount!.toInt();
      final refundAddr = EthereumAddress.fromHex(swap.refundPublicKey!);
      final timelock = swap.timeoutBlockHeight!.toInt();
      final onchainWei = BigInt.from(onchainAmount) * BigInt.from(10).pow(10);

      print('  Swap ID:      ${swap.id}');
      print('  Onchain amt:  $onchainAmount sats → $onchainWei wei');
      print('  Timeout:      $timelock');

      // ── 7. Pay the Lightning invoice via NWC (in background) ─────────
      print('⏳ Paying Lightning invoice via NWC …');
      // ignore: unawaited_futures
      final payFuture = hostr.nwc.payInvoice(nwcConnection, swap.invoice);

      // ── 8. Wait for Boltz to lock tBTC on-chain ──────────────────────
      print('⏳ Waiting for lockup transaction …');
      final boltzClient = BoltzClient(
        hostr.config.evmConfig.boltz!,
        CustomLogger(),
      );
      String? lockupStatus;
      for (var i = 0; i < 60; i++) {
        final status = await boltzClient.getSwap(id: swap.id);
        final s = status.status;
        if (s == 'transaction.mempool' || s == 'transaction.confirmed') {
          lockupStatus = s;
          print('  ✓ Lockup detected: $s');
          break;
        }
        if (s.contains('error') ||
            s.contains('failed') ||
            s.contains('expired')) {
          fail('Swap failed with status: $s');
        }
        await Future.delayed(const Duration(seconds: 2));
      }
      expect(lockupStatus, isNotNull, reason: 'Timed out waiting for lockup');

      // Give anvil a moment
      await Future.delayed(const Duration(seconds: 2));

      // ── 9. Verify swap is registered in ERC20Swap (generated class) ──
      final swapHash = await erc20Swap.hashValues((
        preimageHash: Uint8List.fromList(hex.decode(preimageHash)),
        amount: onchainWei,
        tokenAddress: tbtcTokenAddress,
        claimAddress: smartWallet,
        refundAddress: refundAddr,
        timelock: BigInt.from(timelock),
      ));
      print('  Swap hash:    0x${hex.encode(swapHash).substring(0, 16)}…');

      final registered = await erc20Swap.swaps(($param94: swapHash));
      expect(registered, isTrue, reason: 'Swap not registered in ERC20Swap');
      print('  ✓ Swap registered in contract');

      // ── 10. Check tBTC balance BEFORE ────────────────────────────────
      final balanceBefore = await _tokenBalance(
        publicClient,
        tbtcTokenAddress,
        smartWallet,
      );
      print('  Balance before: $balanceBefore wei');

      // ── 11. Claim via 4337 UserOp (paymaster-sponsored) ─────────────
      //
      // Use the generated ERC20Swap ABI to encode the 5-arg claim.
      // claim$4(preimage, amount, tokenAddress, refundAddress, timelock)
      // msg.sender = smart wallet = claimAddress.
      print('⏳ Claiming tBTC via smart wallet + paymaster …');

      final claimFn = erc20Swap.self.abi.functions.firstWhere(
        (f) => f.name == 'claim' && f.parameters.length == 5,
      );
      final claimCalldata = claimFn.encodeCall([
        Uint8List.fromList(hex.decode(preimage)),
        onchainWei,
        tbtcTokenAddress,
        refundAddr,
        BigInt.from(timelock),
      ]);

      final smartAccountClient = SmartAccountClient(
        account: account,
        bundler: bundlerClient,
        publicClient: publicClient,
        paymaster: paymasterClient,
      );

      try {
        final feeData = await publicClient.getFeeData();
        final maxPriorityFeePerGas =
            feeData.maxPriorityFeePerGas ?? feeData.gasPrice;
        final maxFeePerGas = feeData.gasPrice > maxPriorityFeePerGas
            ? feeData.gasPrice
            : maxPriorityFeePerGas;

        final receipt = await smartAccountClient.sendUserOperationAndWait(
          calls: [
            Call(
              to: erc20SwapAddress,
              value: BigInt.zero,
              data: '0x${hex.encode(claimCalldata)}',
            ),
          ],
          maxFeePerGas: maxFeePerGas,
          maxPriorityFeePerGas: maxPriorityFeePerGas,
        );

        expect(receipt, isNotNull, reason: 'No UserOp receipt returned');
        expect(
          receipt!.success,
          isTrue,
          reason: 'UserOp failed: ${receipt.reason}',
        );
        print('  ✓ Claim UserOp successful');
        print('    UserOp hash: ${receipt.userOpHash}');
        print('    Tx hash:     ${receipt.receipt?.transactionHash}');
        print('    Gas used:    ${receipt.actualGasUsed}');
        print('    Gas cost:    ${receipt.actualGasCost} wei');
      } finally {
        smartAccountClient.close();
      }

      // Wait for LN payment to settle
      try {
        await payFuture.timeout(const Duration(seconds: 10));
      } catch (_) {
        // Payment may have already settled or timed out — that's fine
      }

      // ── 12. Check tBTC balance AFTER ─────────────────────────────────
      final balanceAfter = await _tokenBalance(
        publicClient,
        tbtcTokenAddress,
        smartWallet,
      );
      final diff = balanceAfter - balanceBefore;
      print('  Balance after:  $balanceAfter wei');
      print('  Difference:     +$diff wei');
      print('  Expected:       +$onchainWei wei');

      expect(
        diff,
        equals(onchainWei),
        reason: 'Balance difference does not match onchainAmount',
      );

      // Verify smart wallet still has zero ETH (paymaster paid gas!)
      final ethBalanceAfter = await publicClient.getBalance(smartWallet);
      print(
        '  ETH after:      $ethBalanceAfter (still zero — paymaster paid!)',
      );
      expect(
        ethBalanceAfter,
        equals(BigInt.zero),
        reason: 'Smart wallet should still have zero ETH',
      );

      // ── Final summary ────────────────────────────────────────────────
      final diffSats = diff ~/ BigInt.from(10).pow(10);
      print('');
      print('═══════════════════════════════════════════════════════════');
      print(' ✅ PAYMASTER tBTC CLAIM SUCCESSFUL');
      print('    Received:    +$diffSats sats');
      print('    Gas paid by: Paymaster (smart wallet has 0 ETH)');
      print('    Swap ID:     ${swap.id}');
      print('═══════════════════════════════════════════════════════════');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
