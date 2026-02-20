import 'dart:convert';
import 'dart:io';

class AnvilClient {
  final Uri rpcUri;
  final HttpClient _httpClient;

  AnvilClient({required this.rpcUri, HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

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

  Future<bool> rpcCall({
    required String method,
    List<dynamic> params = const [],
  }) async {
    final request = await _httpClient.postUrl(rpcUri);
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': method,
        'params': params,
      }),
    );

    final response = await request.close();
    final body = await utf8.decodeStream(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return decoded['error'] == null;
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
    _httpClient.close(force: true);
  }
}
