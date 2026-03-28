@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/datasources/contracts/boltz/TestERC20.g.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

import '../../../support/evm_test_helpers.dart';
import '../../../support/integration_test_harness.dart';

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late IntegrationTestHarness harness;
  late Web3Client web3;

  setUp(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_swap_out_erc20_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.warning,
      cleanHydratedStorage: true,
    );
  });

  setUpAll(() async {
    web3 = Web3Client(IntegrationTestHarness.anvilRpc, http.Client());
  });

  tearDownAll(() {
    web3.dispose();
    IntegrationTestHarness.resetLogLevel();
  });

  tearDown(() async {
    await harness.dispose();
  });

  group('EvmChain ERC-20 balance scanning', () {
    test('getERC20Balance returns non-zero for funded address', () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;

      await hostr.auth.signin(harness.fundedKeys[0].privateKey!);

      // Deploy a TestERC20.
      await anvil.setBalance(
        address: anvilDeployerKey.address.eip55With0x,
        amountWei: BigInt.from(10).pow(18),
      );
      final tokenAddress = await deployTestERC20(
        web3,
        anvilDeployerKey,
        name: 'Test TBTC',
        symbol: 'TBTC',
        decimals: 18,
        initialSupply: BigInt.from(10).pow(24),
      );
      final tokenContract = TestERC20(address: tokenAddress, client: web3);

      // Transfer tokens to the user's HD address #0.
      final userKey = await hostr.auth.hd.getActiveEvmKey();
      final transferAmount = BigInt.from(5) * BigInt.from(10).pow(18);
      final txHash = await tokenContract.transfer((
        to: userKey.address,
        value: transferAmount,
      ), credentials: anvilDeployerKey);
      await waitForReceipt(web3, txHash);

      // Now test getERC20Balance.
      final chain = hostr.evm.configuredChains.first;
      final balance = await chain.getERC20Balance(
        userKey.address,
        tokenAddress,
      );

      expect(balance.value, equals(transferAmount));
      expect(balance.token.isERC20, isTrue);
      expect(
        balance.token.address.toLowerCase(),
        equals(tokenAddress.eip55With0x.toLowerCase()),
      );
    });

    test('getERC20Balance returns zero for unfunded address', () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;

      await hostr.auth.signin(harness.fundedKeys[0].privateKey!);

      await anvil.setBalance(
        address: anvilDeployerKey.address.eip55With0x,
        amountWei: BigInt.from(10).pow(18),
      );
      final tokenAddress = await deployTestERC20(
        web3,
        anvilDeployerKey,
        name: 'Test USDT',
        symbol: 'USDT',
        decimals: 6,
        initialSupply: BigInt.from(10).pow(12),
      );

      // Do NOT transfer any tokens — balance should be zero.
      final userKey = await hostr.auth.hd.getActiveEvmKey();
      final chain = hostr.evm.configuredChains.first;
      final balance = await chain.getERC20Balance(
        userKey.address,
        tokenAddress,
      );

      expect(balance.value, equals(BigInt.zero));
    });

    test('getAddressesWithTokenBalances finds funded HD addresses', () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;

      await hostr.auth.signin(harness.fundedKeys[0].privateKey!);

      await anvil.setBalance(
        address: anvilDeployerKey.address.eip55With0x,
        amountWei: BigInt.from(10).pow(18),
      );
      final tokenAddress = await deployTestERC20(
        web3,
        anvilDeployerKey,
        name: 'Test TBTC',
        symbol: 'TBTC',
        decimals: 18,
        initialSupply: BigInt.from(10).pow(24),
      );
      final tokenContract = TestERC20(address: tokenAddress, client: web3);

      // Fund HD addresses #0 and #2 with TBTC (skip #1).
      final addr0 = await hostr.auth.hd.getEvmAddress(accountIndex: 0);
      final addr2 = await hostr.auth.hd.getEvmAddress(accountIndex: 2);
      final amount0 = BigInt.from(3) * BigInt.from(10).pow(18);
      final amount2 = BigInt.from(7) * BigInt.from(10).pow(18);

      await waitForReceipt(
        web3,
        await tokenContract.transfer((
          to: addr0,
          value: amount0,
        ), credentials: anvilDeployerKey),
      );
      await waitForReceipt(
        web3,
        await tokenContract.transfer((
          to: addr2,
          value: amount2,
        ), credentials: anvilDeployerKey),
      );

      // Scan using the token map.
      final chain = hostr.evm.configuredChains.first;
      final results = await chain.getAddressesWithTokenBalances({
        'TBTC': tokenAddress,
      });

      expect(results.length, equals(2));

      final entry0 = results.firstWhere((e) => e.accountIndex == 0);
      expect(entry0.balance.value, equals(amount0));
      expect(entry0.tokenName, equals('TBTC'));
      expect(
        entry0.tokenAddress.eip55With0x.toLowerCase(),
        equals(tokenAddress.eip55With0x.toLowerCase()),
      );

      final entry2 = results.firstWhere((e) => e.accountIndex == 2);
      expect(entry2.balance.value, equals(amount2));
      expect(entry2.tokenName, equals('TBTC'));
    });

    test('getAddressesWithTokenBalances returns empty for no tokens', () async {
      final hostr = harness.hostr;
      await hostr.auth.signin(harness.fundedKeys[0].privateKey!);

      final chain = hostr.evm.configuredChains.first;
      final results = await chain.getAddressesWithTokenBalances({});

      expect(results, isEmpty);
    });
  });

  group('swapOutAll with ERC-20 tokens', () {
    test(
      'swapOutAll includes ERC-20-funded addresses when Boltz tokens present',
      () async {
        final hostr = harness.hostr;
        final anvil = harness.anvil;

        await hostr.auth.signin(harness.fundedKeys[0].privateKey!);
        await hostr.evm.init();

        // The test Docker stack deploys a mock ERC-20 that Boltz discovers
        // as "TBTC". Its address comes from ARBITRUM_TBTC_ADDRESS env var.
        // If not set, skip this test.
        final configured = hostr.evm.configuredChains.first;
        if (configured.swaps == null) {
          markTestSkipped('Boltz not configured — skipping ERC-20 swapOutAll');
          return;
        }
        final boltzTokens = configured.swaps!.chainInfo.tokens;
        if (boltzTokens.isEmpty) {
          markTestSkipped('No Boltz ERC-20 tokens discovered — skipping');
          return;
        }

        // Fund HD #0 with both native + ERC-20.
        final userKey = await hostr.auth.hd.getActiveEvmKey();
        await anvil.setBalance(
          address: userKey.address.eip55With0x,
          amountWei: rbtcFromSats(BigInt.from(100000)).getInWei,
        );

        // Mint ERC-20 to user via deployer.
        await anvil.setBalance(
          address: anvilDeployerKey.address.eip55With0x,
          amountWei: BigInt.from(10).pow(18),
        );

        final tokenEntry = boltzTokens.entries.first;
        final tokenContract = TestERC20(
          address: tokenEntry.value,
          client: web3,
        );
        final mintAmount = BigInt.from(10) * BigInt.from(10).pow(18);
        await waitForReceipt(
          web3,
          await tokenContract.transfer((
            to: userKey.address,
            value: mintAmount,
          ), credentials: anvilDeployerKey),
        );

        // Call swapOutAll — should return ops for both native and ERC-20.
        final ops = await hostr.evm.swapOutAll();

        // At minimum we expect 2 ops: 1 native + 1 ERC-20.
        expect(ops.length, greaterThanOrEqualTo(2));

        // Verify one of the ops carries an ERC-20 token amount.
        final erc20Ops = ops.where(
          (op) => op.params.amount != null && op.params.amount!.token.isERC20,
        );
        expect(
          erc20Ops,
          isNotEmpty,
          reason: 'Expected at least one swap-out op for an ERC-20 token',
        );

        final erc20Op = erc20Ops.first;
        expect(erc20Op.params.amount!.value, equals(mintAmount));
        expect(
          erc20Op.params.amount!.token.address.toLowerCase(),
          equals(tokenEntry.value.eip55With0x.toLowerCase()),
        );
      },
    );

    test('swapOutAll skips ERC-20 below minimumBalance', () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;

      await hostr.auth.signin(harness.fundedKeys[0].privateKey!);
      await hostr.evm.init();

      final configured = hostr.evm.configuredChains.first;
      if (configured.swaps == null ||
          configured.swaps!.chainInfo.tokens.isEmpty) {
        markTestSkipped('Boltz ERC-20 tokens not available — skipping');
        return;
      }

      final userKey = await hostr.auth.hd.getActiveEvmKey();

      // Fund deployer + mint a tiny ERC-20 amount.
      await anvil.setBalance(
        address: anvilDeployerKey.address.eip55With0x,
        amountWei: BigInt.from(10).pow(18),
      );
      final tokenEntry = configured.swaps!.chainInfo.tokens.entries.first;
      final tokenContract = TestERC20(address: tokenEntry.value, client: web3);
      final tinyAmount = BigInt.from(100); // 100 wei — negligible
      await waitForReceipt(
        web3,
        await tokenContract.transfer((
          to: userKey.address,
          value: tinyAmount,
        ), credentials: anvilDeployerKey),
      );

      // Set a minimum balance higher than the tiny amount.
      // Use a native-token amount for comparison (the filter is cross-token).
      final highMinimum = rbtcFromSats(BigInt.from(999999));
      final ops = await hostr.evm.swapOutAll(minimumBalance: highMinimum);

      // ERC-20 op should be filtered out.
      final erc20Ops = ops.where(
        (op) => op.params.amount != null && op.params.amount!.token.isERC20,
      );
      expect(
        erc20Ops,
        isEmpty,
        reason: 'ERC-20 op with tiny balance should be filtered by minimum',
      );
    });
  });
}
