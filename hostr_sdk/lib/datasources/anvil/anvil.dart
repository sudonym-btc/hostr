import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart' show bytesToHex, keccak256;

class AnvilClient {
  final Uri rpcUri;
  final http.Client _httpClient;

  AnvilClient({required this.rpcUri, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<bool> setBalance({
    required String address,
    required BigInt amountWei,
    List<String> methods = const ['anvil_setBalance', 'hardhat_setBalance'],
  }) async {
    for (final method in methods) {
      final ok = await _setBalanceWithMethod(
        method: method,
        address: address,
        amountWei: amountWei,
      );
      if (ok) {
        return true;
      }
    }

    return false;
  }

  Future<void> advanceChainTime({required int seconds}) async {
    final increased = await rpcCall(
      method: 'evm_increaseTime',
      params: [seconds],
    );
    if (!increased) {
      await rpcCall(
        method: 'anvil_setBlockTimestampInterval',
        params: [seconds],
      );
    }
    await rpcCall(method: 'evm_mine', params: const []);
  }

  /// Take a state snapshot and return its ID.
  ///
  /// The returned hex string can be passed to [revert] to restore the chain
  /// state at this point.  Uses the Anvil/Hardhat `evm_snapshot` JSON-RPC
  /// method.
  Future<String?> snapshot() async {
    final result = await rpcCallWithResult(method: 'evm_snapshot');
    return result?.toString();
  }

  /// Revert chain state to a previously taken [snapshotId].
  ///
  /// Returns `true` on success. After reverting, the snapshot is consumed —
  /// call [snapshot] again if you need another restore point.
  Future<bool> revert(String snapshotId) =>
      rpcCall(method: 'evm_revert', params: [snapshotId]);

  /// Enable or disable auto-mining (a block per transaction).
  Future<bool> setAutomine(bool enabled) =>
      rpcCall(method: 'evm_setAutomine', params: [enabled]);

  /// Mine a new block every [seconds] seconds.
  ///
  /// Setting [seconds] to `0` disables interval mining.
  Future<bool> setIntervalMining(int seconds) =>
      rpcCall(method: 'evm_setIntervalMining', params: [seconds]);

  /// Set a raw storage slot on a contract address.
  ///
  /// [address], [slot], and [value] must be hex-encoded (0x-prefixed).
  Future<bool> setStorageAt({
    required String address,
    required String slot,
    required String value,
    List<String> methods = const ['anvil_setStorageAt', 'hardhat_setStorageAt'],
  }) async {
    for (final method in methods) {
      final ok = await rpcCall(method: method, params: [address, slot, value]);
      if (ok) return true;
    }
    return false;
  }

  /// Give [account] an ERC-20 [amount] by writing the balance mapping directly.
  ///
  /// This is a local-chain test helper. It assumes the token uses the standard
  /// OpenZeppelin ERC-20 layout where `_balances` is mapping slot 0; writing the
  /// slot avoids spending from a shared deployer/funding account, which can make
  /// tests race on nonces when several setup flows run against the same Anvil.
  Future<void> setErc20Balance({
    required String token,
    required String account,
    required BigInt amount,
    int balanceMappingSlot = 0,
  }) async {
    final slot = erc20BalanceStorageSlot(
      account: account,
      balanceMappingSlot: balanceMappingSlot,
    );
    final value = '0x${amount.toRadixString(16).padLeft(64, '0')}';

    final ok = await setStorageAt(address: token, slot: slot, value: value);
    if (!ok) {
      throw Exception(
        'Failed to set ERC-20 balance for $account on $token via $rpcUri',
      );
    }
  }

  /// Compute `keccak256(abi.encode(account, balanceMappingSlot))`.
  String erc20BalanceStorageSlot({
    required String account,
    int balanceMappingSlot = 0,
  }) {
    final paddedAccount = account
        .replaceFirst('0x', '')
        .toLowerCase()
        .padLeft(64, '0');
    final paddedSlot = balanceMappingSlot.toRadixString(16).padLeft(64, '0');
    final preimage = '$paddedAccount$paddedSlot';
    final preimageBytes = Uint8List.fromList([
      for (var i = 0; i < preimage.length; i += 2)
        int.parse(preimage.substring(i, i + 2), radix: 16),
    ]);
    return '0x${bytesToHex(keccak256(preimageBytes))}';
  }

  /// Impersonate [address] so unsigned transactions from it are accepted.
  Future<bool> impersonateAccount(String address) =>
      rpcCall(method: 'anvil_impersonateAccount', params: [address]);

  /// Stop impersonating [address].
  Future<bool> stopImpersonatingAccount(String address) =>
      rpcCall(method: 'anvil_stopImpersonatingAccount', params: [address]);

  /// Execute a JSON-RPC call and return the raw `result` value.
  ///
  /// Returns `null` when the response contains an error.
  Future<dynamic> rpcCallWithResult({
    required String method,
    List<dynamic> params = const [],
  }) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _httpClient.post(
          rpcUri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': method,
            'params': params,
          }),
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['error'] != null) return null;
        return decoded['result'];
      } catch (_) {
        if (attempt > 0) rethrow;
      }
    }
    return null;
  }

  /// Send an unsigned transaction from a (possibly impersonated) account.
  ///
  /// Returns the transaction hash, or `null` on failure.
  Future<String?> sendUnsignedTransaction({
    required String from,
    required String to,
    required String data,
    String? value,
    String? gas,
  }) async {
    final result = await rpcCallWithResult(
      method: 'eth_sendTransaction',
      params: [
        {'from': from, 'to': to, 'data': data, 'value': ?value, 'gas': ?gas},
      ],
    );
    return result as String?;
  }

  Future<bool> rpcCall({
    required String method,
    List<dynamic> params = const [],
  }) async {
    // Retry once on connection errors (stale keep-alive after idle).
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _httpClient.post(
          rpcUri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': method,
            'params': params,
          }),
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return false;
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['error'] == null;
      } catch (_) {
        if (attempt > 0) rethrow;
      }
    }
    return false;
  }

  Future<bool> _setBalanceWithMethod({
    required String method,
    required String address,
    required BigInt amountWei,
  }) async {
    return rpcCall(
      method: method,
      params: [address, '0x${amountWei.toRadixString(16)}'],
    );
  }

  void close() {
    _httpClient.close();
  }
}
