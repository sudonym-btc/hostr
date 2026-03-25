@Tags(['integration', 'docker'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/datasources/contracts/boltz/TestERC20.g.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;
  late Web3Client web3;

  setUpAll(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_escrow_fund_erc20_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.warning,
      cleanHydratedStorage: true,
    );
    web3 = Web3Client(IntegrationTestHarness.anvilRpc, http.Client());
  });

  tearDownAll(() {
    web3.dispose();
    IntegrationTestHarness.resetLogLevel();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test(
    'escrow fund with ERC20 (USDT) deposits token into MultiEscrow',
    () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;

      // ── 1. Create trade fixtures ──────────────────────────────────────
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);
      await hostr.auth.signin(trade.guest.privateKey);

      // ── 2. Resolve escrow contract + service ──────────────────────────
      final escrowAddress = EthereumAddress.fromHex(
        env.evmConfig.chains.first.escrowContractAddress!,
      );
      final escrowService = (await harness.seeds.factory.buildEscrowServices(
        contractAddress: env.evmConfig.chains.first.escrowContractAddress!,
      )).first;

      final chain = hostr.evm.getChainForEscrowService(escrowService);
      final contract = chain.escrow.getSupportedEscrowContract(escrowService);

      // ── 3. Deploy a TestERC20 (USDT) token on Anvil ────────────────────
      final deployerKey = EthPrivateKey.fromHex(
        // Anvil default account #0
        'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      );
      final usdtAddress = await _deployTestERC20(
        web3,
        deployerKey,
        name: 'Test USDT',
        symbol: 'USDT',
        decimals: 18,
        initialSupply: BigInt.from(10).pow(24), // 1 000 000 USDT
      );

      // ── 4. Query token decimals and build Token / TokenAmount ─────────
      final tokenContract = TestERC20(address: usdtAddress, client: web3);
      final decimals = (await tokenContract.tokenDecimals()).toInt();

      final usdtToken = Token(
        chainId: 412346,
        address: usdtAddress.with0x,
        decimals: decimals,
      );
      expect(usdtToken.isERC20, isTrue);

      // 5 USDT (in smallest unit)
      final tradeAmount = BigInt.from(5) * BigInt.from(10).pow(decimals);
      final usdtAmount = TokenAmount(value: tradeAmount, token: usdtToken);

      // escrow fee: mirrors EscrowServiceContent.escrowFee but in BigInt
      final feePercent = escrowService.feePercent;
      final escrowFee =
          (usdtAmount.value * BigInt.from((feePercent * 100).round())) ~/
          BigInt.from(10000);
      final totalTokenCost = tradeAmount + escrowFee;

      // ── 5. Get buyer's EVM key ────────────────────────────────────────
      final buyerKey = await hostr.auth.hd.getActiveEvmKey();
      final buyerAddress = buyerKey.address;

      // ── 6. Transfer USDT from deployer to buyer ─────────────────────
      // Fund deployer with RBTC for gas first.
      await anvil.setBalance(
        address: deployerKey.address.eip55With0x,
        amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
      );

      final transferTxHash = await tokenContract.transfer((
        to: buyerAddress,
        value: totalTokenCost * BigInt.two,
      ), credentials: deployerKey);
      await _waitForReceipt(web3, transferTxHash);

      // Verify balance was set
      final buyerBalance = await tokenContract.balanceOf((
        account: buyerAddress,
      ));
      expect(
        buyerBalance,
        greaterThanOrEqualTo(totalTokenCost),
        reason: 'Buyer should hold enough USDT',
      );

      // ── 8. Approve MultiEscrow to spend buyer's USDT ──────────────────
      // First fund buyer with RBTC for gas
      await anvil.setBalance(
        address: buyerAddress.eip55With0x,
        amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
      );

      final approveTxHash = await tokenContract.approve((
        spender: escrowAddress,
        value: totalTokenCost * BigInt.two,
      ), credentials: buyerKey);
      await _waitForReceipt(web3, approveTxHash);

      // ── 9. Build FundArgs and get ContractCallIntent ──────────────────
      final negotiation = trade.negotiateReservation;

      final fundArgs = FundArgs(
        tradeId: negotiation.getDtag()!,
        amount: usdtAmount,
        sellerEvmAddress: trade.sellerProfile.evmAddress!,
        arbiterEvmAddress: escrowService.evmAddress,
        unlockAt: negotiation.end.millisecondsSinceEpoch ~/ 1000,
        escrowFee: TokenAmount(value: escrowFee, token: usdtToken),
        ethKey: buyerKey,
        token: usdtToken,
      );

      final intent = contract.fund(fundArgs);

      // ERC-20 fund must be zero-value (tokens pulled via transferFrom)
      expect(
        intent.isZeroValue,
        isTrue,
        reason: 'ERC-20 createTrade should send 0 native value',
      );

      // ── 10. Broadcast directly from buyer EOA ─────────────────────────
      final chainId = chain.config.chainId;
      final txHash = await web3.sendTransaction(
        buyerKey,
        Transaction(to: intent.to, data: intent.data, value: intent.value),
        chainId: chainId,
      );

      expect(txHash, isNotEmpty);

      // ── 11. Wait for receipt ──────────────────────────────────────────
      TransactionReceipt? receipt;
      for (int i = 0; i < 15; i++) {
        receipt = await web3.getTransactionReceipt(txHash);
        if (receipt != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }

      expect(receipt, isNotNull, reason: 'Tx should be mined');
      expect(receipt!.status, isTrue, reason: 'createTrade should succeed');

      // ── 12. Verify on-chain trade ─────────────────────────────────────
      final tradeId = negotiation.getDtag()!;
      final onChainTrade = await contract.getTrade(tradeId);

      expect(onChainTrade, isNotNull, reason: 'Trade should exist in escrow');
      expect(onChainTrade!.isActive, isTrue);
      expect(
        onChainTrade.token,
        equals(usdtAddress),
        reason: 'Trade token must be USDT',
      );
      expect(
        onChainTrade.amount,
        equals(tradeAmount),
        reason: 'Trade amount must match',
      );

      // ── 13. Verify escrow received the USDT ───────────────────────────
      final escrowBalance = await tokenContract.balanceOf((
        account: escrowAddress,
      ));
      expect(
        escrowBalance,
        greaterThanOrEqualTo(tradeAmount),
        reason: 'Escrow contract should hold the funded USDT',
      );
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Deploy a TestERC20 token contract on Anvil.
///
/// Returns the deployed contract address. The [deployer] receives the
/// [initialSupply] of tokens.
Future<EthereumAddress> _deployTestERC20(
  Web3Client web3,
  EthPrivateKey deployer, {
  required String name,
  required String symbol,
  required int decimals,
  required BigInt initialSupply,
}) async {
  // Read bytecode from the bundled ABI JSON artifact.
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

  // ABI-encode constructor args: (string, string, uint8, uint256)
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

  // Wait for receipt
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

/// ABI-encode the TestERC20 constructor parameters:
///   `constructor(string name, string symbol, uint8 initialDecimals, uint256 initialSupply)`
Uint8List _abiEncodeConstructor(
  String name,
  String symbol,
  int decimals,
  BigInt initialSupply,
) {
  final nameBytes = utf8.encode(name);
  final symbolBytes = utf8.encode(symbol);

  // Padded length for string data (round up to 32-byte boundary).
  int pad32(int len) => ((len + 31) ~/ 32) * 32;

  final headSize = 4 * 32; // 4 params × 32 bytes each
  final nameDataOffset = headSize;
  final symbolDataOffset = nameDataOffset + 32 + pad32(nameBytes.length);
  final totalLen = symbolDataOffset + 32 + pad32(symbolBytes.length);

  final buf = Uint8List(totalLen);

  // Head section
  _putUint256(buf, 0, BigInt.from(nameDataOffset)); // offset → name
  _putUint256(buf, 32, BigInt.from(symbolDataOffset)); // offset → symbol
  _putUint256(buf, 64, BigInt.from(decimals)); // uint8 (padded)
  _putUint256(buf, 96, initialSupply); // uint256

  // Name data
  _putUint256(buf, nameDataOffset, BigInt.from(nameBytes.length));
  buf.setRange(
    nameDataOffset + 32,
    nameDataOffset + 32 + nameBytes.length,
    nameBytes,
  );

  // Symbol data
  _putUint256(buf, symbolDataOffset, BigInt.from(symbolBytes.length));
  buf.setRange(
    symbolDataOffset + 32,
    symbolDataOffset + 32 + symbolBytes.length,
    symbolBytes,
  );

  return buf;
}

/// Write a uint256 into [buf] at the given byte [offset].
void _putUint256(Uint8List buf, int offset, BigInt value) {
  final hex = value.toRadixString(16).padLeft(64, '0');
  for (int i = 0; i < 32; i++) {
    buf[offset + i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
}

/// Poll until a transaction receipt is available.
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
