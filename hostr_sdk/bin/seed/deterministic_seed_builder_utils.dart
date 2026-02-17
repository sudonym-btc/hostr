part of 'deterministic_seed_builder.dart';

extension _DeterministicSeedUtils on DeterministicSeedBuilder {
  int _sampleAverage(double avg) {
    if (avg <= 0) {
      return 0;
    }

    final base = avg.floor();
    final remainder = avg - base;
    return base + (_random.nextDouble() < remainder ? 1 : 0);
  }

  int _timestampDaysAfter(int days) {
    final candidate = _baseDate.add(Duration(days: days));
    final maxAllowed = DateTime.now().toUtc().subtract(
      const Duration(seconds: 5),
    );
    final safe = candidate.isAfter(maxAllowed) ? maxAllowed : candidate;
    return safe.millisecondsSinceEpoch ~/ 1000;
  }

  Web3Client _chainClient() {
    _httpClient ??= http.Client();
    _web3Client ??= Web3Client(rpcUrl, _httpClient!);
    return _web3Client!;
  }

  MultiEscrow _multiEscrowContract(String contractAddress) {
    return _escrowContracts.putIfAbsent(contractAddress, () {
      return MultiEscrow(
        address: EthereumAddress.fromHex(contractAddress),
        client: _chainClient(),
      );
    });
  }

  Future<void> _advanceChainTime({required int seconds}) async {
    final increased = await _rpcCall('evm_increaseTime', [seconds]);
    if (!increased) {
      await _rpcCall('anvil_setBlockTimestampInterval', [seconds]);
    }
    await _rpcCall('evm_mine', []);
  }

  Future<bool> _rpcCall(String method, List<dynamic> params) async {
    _httpClient ??= http.Client();
    final response = await _httpClient!.post(
      Uri.parse(rpcUrl),
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
  }

  void _disposeWeb3Client() {
    _web3Client?.dispose();
    _httpClient?.close();
    _web3Client = null;
    _httpClient = null;
    _escrowContracts.clear();
  }
}
