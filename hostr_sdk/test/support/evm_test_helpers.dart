/// Shared EVM test helpers for integration tests.
///
/// Consolidates helper functions that were previously duplicated across
/// multiple integration test files (escrow_fund_test, escrow_fund_with_swap_test,
/// fee_and_verification_test, escrow_fund_erc20_test, swap_out_erc20_test).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Transaction inspection helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Extract the transaction hash from a [TransactionInformation].
///
/// Uses dynamic dispatch because the web3dart type does not expose a stable
/// `hash` getter across all versions.
String? extractTxHash(TransactionInformation tx) {
  final dynamic d = tx;
  final hash = d.hash?.toString() ?? d.id?.toString();
  if (hash == null || hash.isEmpty) return null;
  return hash;
}

/// Extract the transaction hash from a [TransactionReceipt].
String? extractReceiptTxHash(TransactionReceipt receipt) {
  final dynamic hash = (receipt as dynamic).transactionHash;
  if (hash == null) return null;
  if (hash is String) return hash;
  if (hash is List<int>) return bytesToHex(hash, include0x: true);
  final normalized = hash.toString();
  if (normalized.isEmpty) return null;
  return normalized;
}

/// Returns `true` if the receipt indicates a successful transaction.
bool isReceiptSuccessful(TransactionReceipt receipt) {
  final dynamic status = (receipt as dynamic).status;
  if (status == null) return true;
  if (status is bool) return status;
  if (status is int) return status == 1;
  if (status is BigInt) return status == BigInt.one;
  final normalized = status.toString().toLowerCase();
  return normalized == '1' || normalized == '0x1' || normalized == 'true';
}

// ═══════════════════════════════════════════════════════════════════════════
//  Receipt polling
// ═══════════════════════════════════════════════════════════════════════════

/// Polls for a transaction receipt until it appears or [maxAttempts] is reached.
Future<TransactionReceipt> waitForReceipt(
  Web3Client web3,
  String txHash, {
  int maxAttempts = 15,
  Duration delay = const Duration(seconds: 1),
}) async {
  for (int i = 0; i < maxAttempts; i++) {
    final receipt = await web3.getTransactionReceipt(txHash);
    if (receipt != null) return receipt;
    await Future.delayed(delay);
  }
  throw StateError('Transaction $txHash was not mined within timeout');
}

// ═══════════════════════════════════════════════════════════════════════════
//  TestERC20 deployment
// ═══════════════════════════════════════════════════════════════════════════

/// Deploys a TestERC20 token contract on Anvil and returns its address.
Future<EthereumAddress> deployTestERC20(
  Web3Client web3,
  EthPrivateKey deployer, {
  required String name,
  required String symbol,
  required int decimals,
  required BigInt initialSupply,
  int chainId = 412346,
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
  final constructorArgs = abiEncodeConstructor(
    name,
    symbol,
    decimals,
    initialSupply,
  );
  final deployData = Uint8List.fromList([...bytecode, ...constructorArgs]);

  final txHash = await web3.sendTransaction(
    deployer,
    Transaction(data: deployData),
    chainId: chainId,
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

// ═══════════════════════════════════════════════════════════════════════════
//  ABI encoding helpers
// ═══════════════════════════════════════════════════════════════════════════

/// ABI-encodes the constructor arguments for a TestERC20(string, string, uint8, uint256).
Uint8List abiEncodeConstructor(
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
  putUint256(buf, 0, BigInt.from(nameDataOffset));
  putUint256(buf, 32, BigInt.from(symbolDataOffset));
  putUint256(buf, 64, BigInt.from(decimals));
  putUint256(buf, 96, initialSupply);

  putUint256(buf, nameDataOffset, BigInt.from(nameBytes.length));
  buf.setRange(
    nameDataOffset + 32,
    nameDataOffset + 32 + nameBytes.length,
    nameBytes,
  );

  putUint256(buf, symbolDataOffset, BigInt.from(symbolBytes.length));
  buf.setRange(
    symbolDataOffset + 32,
    symbolDataOffset + 32 + symbolBytes.length,
    symbolBytes,
  );

  return buf;
}

/// Writes a big-endian uint256 into [buf] at [offset].
void putUint256(Uint8List buf, int offset, BigInt value) {
  final hex = value.toRadixString(16).padLeft(64, '0');
  for (int i = 0; i < 32; i++) {
    buf[offset + i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Fee assertion helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Asserts that a fee breakdown has sane values for a swap operation.
void expectSwapFees(dynamic fees, {bool expectSwapFee = true}) {
  expect(
    fees.gasFee.value >= BigInt.zero,
    isTrue,
    reason: 'Gas fee should be non-negative, got ${fees.gasFee.value}',
  );
  if (!fees.gasSponsored) {
    expect(
      fees.gasFee.value > BigInt.zero,
      isTrue,
      reason: 'Unsponsored gas fee should be > 0, got ${fees.gasFee.value}',
    );
  }
  if (expectSwapFee) {
    expect(
      fees.swapFee.value > BigInt.zero,
      isTrue,
      reason: 'Swap fee should be > 0, got ${fees.swapFee.value}',
    );
  }
  expect(
    fees.escrowFee.value,
    equals(BigInt.zero),
    reason: 'Pure swap should have zero escrow fee',
  );
  expect(
    fees.networkFees.value > BigInt.zero,
    isTrue,
    reason:
        'networkFees (gas + swap) should be > 0, got ${fees.networkFees.value}',
  );
}

/// Asserts that a fee breakdown has sane values for an escrow-fund operation.
void expectEscrowFees(dynamic fees) {
  expect(
    fees.gasFee.value >= BigInt.zero,
    isTrue,
    reason: 'Gas fee should be non-negative, got ${fees.gasFee.value}',
  );
  if (!fees.gasSponsored) {
    expect(
      fees.gasFee.value > BigInt.zero,
      isTrue,
      reason: 'Unsponsored gas fee should be > 0, got ${fees.gasFee.value}',
    );
  }
  expect(
    fees.swapFee.value > BigInt.zero,
    isTrue,
    reason: 'Escrow fund swap fee should be > 0, got ${fees.swapFee.value}',
  );
  expect(
    fees.escrowFee.value > BigInt.zero,
    isTrue,
    reason: 'Escrow fee should be > 0, got ${fees.escrowFee.value}',
  );
}

/// Anvil default account #0 — has unlimited ETH, used to deploy + fund.
final anvilDeployerKey = EthPrivateKey.fromHex(
  'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
);
