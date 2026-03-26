@Tags(['integration', 'docker'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hostr_sdk/datasources/contracts/boltz/TestERC20.g.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../support/integration_test_harness.dart';

// ── Shared helpers ────────────────────────────────────────────────────────

/// Anvil default account #0 — has unlimited ETH, used to deploy + fund.
final _deployerKey = EthPrivateKey.fromHex(
  'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
);

/// Deploy a fresh [TestERC20] on Anvil and return its address.
Future<EthereumAddress> _deployTestERC20(
  Web3Client web3,
  EthPrivateKey deployer, {
  required String name,
  required String symbol,
  required int decimals,
  required BigInt initialSupply,
}) async {
  final abiJsonFile = File(
    'lib/datasources/contracts/boltz/TestERC20.abi.json',
  );
  final artifact =
      jsonDecode(await abiJsonFile.readAsString()) as Map<String, dynamic>;
  final bytecodeHex = (artifact['bytecode']['object'] as String).replaceFirst(
    '0x',
    '',
  );
  final bytecode = hexToBytes(bytecodeHex);
  final constructorArgs = _abiEncodeConstructor(
    name,
    symbol,
    decimals,
    initialSupply,
  );
  final deployData = Uint8List.fromList([...bytecode, ...constructorArgs]);

  final txHash = await web3.sendTransaction(
    deployer,
    Transaction(data: deployData),
    chainId: 412346,
  );

  TransactionReceipt? receipt;
  for (int i = 0; i < 15; i++) {
    receipt = await web3.getTransactionReceipt(txHash);
    if (receipt != null) break;
    await Future.delayed(const Duration(seconds: 1));
  }
  if (receipt == null || receipt.contractAddress == null) {
    throw StateError('TestERC20 deployment failed — no contract address');
  }
  return receipt.contractAddress!;
}

/// ABI-encode TestERC20 constructor:
///   `constructor(string name, string symbol, uint8 initialDecimals, uint256 initialSupply)`
Uint8List _abiEncodeConstructor(
  String name,
  String symbol,
  int decimals,
  BigInt initialSupply,
) {
  final nameBytes = utf8.encode(name);
  final symbolBytes = utf8.encode(symbol);
  int pad32(int len) => ((len + 31) ~/ 32) * 32;

  final headSize = 4 * 32;
  final nameDataOffset = headSize;
  final symbolDataOffset = nameDataOffset + 32 + pad32(nameBytes.length);
  final totalLen = symbolDataOffset + 32 + pad32(symbolBytes.length);

  final buf = Uint8List(totalLen);
  _putUint256(buf, 0, BigInt.from(nameDataOffset));
  _putUint256(buf, 32, BigInt.from(symbolDataOffset));
  _putUint256(buf, 64, BigInt.from(decimals));
  _putUint256(buf, 96, initialSupply);

  _putUint256(buf, nameDataOffset, BigInt.from(nameBytes.length));
  buf.setRange(
    nameDataOffset + 32,
    nameDataOffset + 32 + nameBytes.length,
    nameBytes,
  );

  _putUint256(buf, symbolDataOffset, BigInt.from(symbolBytes.length));
  buf.setRange(
    symbolDataOffset + 32,
    symbolDataOffset + 32 + symbolBytes.length,
    symbolBytes,
  );

  return buf;
}

void _putUint256(Uint8List buf, int offset, BigInt value) {
  final hex = value.toRadixString(16).padLeft(64, '0');
  for (int i = 0; i < 32; i++) {
    buf[offset + i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
}

Future<TransactionReceipt> _waitForReceipt(
  Web3Client web3,
  String txHash,
) async {
  for (int i = 0; i < 15; i++) {
    final receipt = await web3.getTransactionReceipt(txHash);
    if (receipt != null) return receipt;
    await Future.delayed(const Duration(seconds: 1));
  }
  throw StateError('Transaction $txHash was not mined within timeout');
}

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
    test(
      'getERC20Balance returns non-zero for funded address',
      () async {
        final hostr = harness.hostr;
        final anvil = harness.anvil;

        await hostr.auth.signin(harness.fundedKeys[0].privateKey!);

        // Deploy a TestERC20.
        await anvil.setBalance(
          address: _deployerKey.address.eip55With0x,
          amountWei: BigInt.from(10).pow(18),
        );
        final tokenAddress = await _deployTestERC20(
          web3,
          _deployerKey,
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
        ), credentials: _deployerKey);
        await _waitForReceipt(web3, txHash);

        // Now test getERC20Balance.
        final chain = hostr.evm.configuredChains.first.chain;
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
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'getERC20Balance returns zero for unfunded address',
      () async {
        final hostr = harness.hostr;
        final anvil = harness.anvil;

        await hostr.auth.signin(harness.fundedKeys[0].privateKey!);

        await anvil.setBalance(
          address: _deployerKey.address.eip55With0x,
          amountWei: BigInt.from(10).pow(18),
        );
        final tokenAddress = await _deployTestERC20(
          web3,
          _deployerKey,
          name: 'Test USDT',
          symbol: 'USDT',
          decimals: 6,
          initialSupply: BigInt.from(10).pow(12),
        );

        // Do NOT transfer any tokens — balance should be zero.
        final userKey = await hostr.auth.hd.getActiveEvmKey();
        final chain = hostr.evm.configuredChains.first.chain;
        final balance = await chain.getERC20Balance(
          userKey.address,
          tokenAddress,
        );

        expect(balance.value, equals(BigInt.zero));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'getAddressesWithTokenBalances finds funded HD addresses',
      () async {
        final hostr = harness.hostr;
        final anvil = harness.anvil;

        await hostr.auth.signin(harness.fundedKeys[0].privateKey!);

        await anvil.setBalance(
          address: _deployerKey.address.eip55With0x,
          amountWei: BigInt.from(10).pow(18),
        );
        final tokenAddress = await _deployTestERC20(
          web3,
          _deployerKey,
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

        await _waitForReceipt(
          web3,
          await tokenContract.transfer((
            to: addr0,
            value: amount0,
          ), credentials: _deployerKey),
        );
        await _waitForReceipt(
          web3,
          await tokenContract.transfer((
            to: addr2,
            value: amount2,
          ), credentials: _deployerKey),
        );

        // Scan using the token map.
        final chain = hostr.evm.configuredChains.first.chain;
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
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getAddressesWithTokenBalances returns empty for no tokens',
      () async {
        final hostr = harness.hostr;
        await hostr.auth.signin(harness.fundedKeys[0].privateKey!);

        final chain = hostr.evm.configuredChains.first.chain;
        final results = await chain.getAddressesWithTokenBalances({});

        expect(results, isEmpty);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
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
          amountWei: rbtcFromSatsInt(100000).getInWei,
        );

        // Mint ERC-20 to user via deployer.
        await anvil.setBalance(
          address: _deployerKey.address.eip55With0x,
          amountWei: BigInt.from(10).pow(18),
        );

        final tokenEntry = boltzTokens.entries.first;
        final tokenContract = TestERC20(
          address: tokenEntry.value,
          client: web3,
        );
        final mintAmount = BigInt.from(10) * BigInt.from(10).pow(18);
        await _waitForReceipt(
          web3,
          await tokenContract.transfer((
            to: userKey.address,
            value: mintAmount,
          ), credentials: _deployerKey),
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
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'swapOutAll skips ERC-20 below minimumBalance',
      () async {
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
          address: _deployerKey.address.eip55With0x,
          amountWei: BigInt.from(10).pow(18),
        );
        final tokenEntry = configured.swaps!.chainInfo.tokens.entries.first;
        final tokenContract = TestERC20(
          address: tokenEntry.value,
          client: web3,
        );
        final tinyAmount = BigInt.from(100); // 100 wei — negligible
        await _waitForReceipt(
          web3,
          await tokenContract.transfer((
            to: userKey.address,
            value: tinyAmount,
          ), credentials: _deployerKey),
        );

        // Set a minimum balance higher than the tiny amount.
        // Use a native-token amount for comparison (the filter is cross-token).
        final highMinimum = rbtcFromSatsInt(999999);
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
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
