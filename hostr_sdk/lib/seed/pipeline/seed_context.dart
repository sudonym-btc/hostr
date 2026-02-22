import 'dart:math';

import 'package:hostr_sdk/datasources/contracts/escrow/MultiEscrow.g.dart';
import 'package:http/http.dart' as http;
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

/// Shared mutable context threaded through every pipeline stage.
///
/// Owns the seeded [Random], the base date for timestamp generation,
/// and lazy web3 / HTTP clients that are disposed at the end of a run.
class SeedContext {
  final int seed;
  final Random random;
  final DateTime baseDate;
  final String rpcUrl;
  final String contractAddress;

  http.Client? _httpClient;
  Web3Client? _web3Client;
  final Map<String, MultiEscrow> _escrowContracts = {};

  SeedContext({
    required this.seed,
    required this.contractAddress,
    this.rpcUrl = 'http://localhost:8545',
    int? userCount,
    int? reservationRequestsPerGuest,
  }) : random = Random(seed),
       baseDate = _computePastBaseDate(
         userCount ?? 50,
         reservationRequestsPerGuest ?? 10,
       );

  // ── Deterministic timestamp helpers ──

  static DateTime _computePastBaseDate(
    int userCount,
    int reservationRequestsPerGuest,
  ) {
    final now = DateTime.now().toUtc();
    final maxThreads = userCount * reservationRequestsPerGuest;
    const safetyDays = 30;
    final totalBackDays = 90 + maxThreads + safetyDays;
    const maxBackfillDays = 120;
    final boundedBackDays = totalBackDays > maxBackfillDays
        ? maxBackfillDays
        : totalBackDays;
    return now.subtract(Duration(days: boundedBackDays));
  }

  int timestampDaysAfter(int days) {
    final candidate = baseDate.add(Duration(days: days));
    final maxAllowed = DateTime.now().toUtc().subtract(
      const Duration(seconds: 5),
    );
    final safe = candidate.isAfter(maxAllowed) ? maxAllowed : candidate;
    return safe.millisecondsSinceEpoch ~/ 1000;
  }

  // ── Random helpers ──

  bool pickByRatio(double ratio) => random.nextDouble() < ratio;

  int sampleAverage(double avg) {
    if (avg <= 0) return 0;
    final base = avg.floor();
    final remainder = avg - base;
    return base + (random.nextDouble() < remainder ? 1 : 0);
  }

  int countByRatio(int total, double ratio) {
    final exact = total * ratio;
    final base = exact.floor();
    final remainder = exact - base;
    return base + (random.nextDouble() < remainder ? 1 : 0);
  }

  T pickFrom<T>(List<T> values) => values[random.nextInt(values.length)];

  // ── Web3 client management ──

  Web3Client chainClient() {
    _httpClient ??= http.Client();
    _web3Client ??= Web3Client(rpcUrl, _httpClient!);
    return _web3Client!;
  }

  MultiEscrow multiEscrowContract(String address) {
    return _escrowContracts.putIfAbsent(address, () {
      return MultiEscrow(
        address: EthereumAddress.fromHex(address),
        client: chainClient(),
      );
    });
  }

  Future<void> waitForChainTimePast({
    required int targetEpochSeconds,
    Duration pollInterval = const Duration(milliseconds: 300),
    Duration maxWait = const Duration(seconds: 15),
  }) async {
    final deadline = DateTime.now().add(maxWait);
    while (true) {
      final nowSeconds =
          (await chainClient().getBlockInformation()).timestamp
              .toUtc()
              .millisecondsSinceEpoch ~/
          1000;
      if (nowSeconds > targetEpochSeconds) return;
      if (DateTime.now().isAfter(deadline)) {
        throw Exception(
          'Timed out waiting for chain timestamp to pass $targetEpochSeconds; latest=$nowSeconds',
        );
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  /// Key derivation from seed + index. Deterministic.
  KeyPair deriveKeyPair(int index) {
    var nonce = 0;
    while (true) {
      final r = Random(seed * 100000 + index * 1000 + nonce);
      final bytes = List<int>.generate(32, (_) => r.nextInt(256));
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      try {
        return Bip340.fromPrivateKey(hex);
      } catch (_) {
        nonce++;
      }
    }
  }

  void dispose() {
    _web3Client?.dispose();
    _httpClient?.close();
    _web3Client = null;
    _httpClient = null;
    _escrowContracts.clear();
  }
}
