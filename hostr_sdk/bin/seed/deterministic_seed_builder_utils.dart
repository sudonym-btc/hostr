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
    await _anvil().advanceChainTime(seconds: seconds);
  }

  AnvilClient _anvil() {
    _anvilClient ??= AnvilClient(rpcUri: Uri.parse(rpcUrl));
    return _anvilClient!;
  }

  void _disposeWeb3Client() {
    _web3Client?.dispose();
    _httpClient?.close();
    _anvilClient?.close();
    _web3Client = null;
    _httpClient = null;
    _anvilClient = null;
    _escrowContracts.clear();
  }
}
