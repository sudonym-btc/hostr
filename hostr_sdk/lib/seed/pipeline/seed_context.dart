import 'dart:io' as dart_io;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../datasources/anvil/anvil.dart';
import '../../datasources/contracts/escrow/MultiEscrow.g.dart';

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
  AnvilClient? _anvilClient;
  final Map<String, MultiEscrow> _escrowContracts = {};
  int _clientGeneration = 0;

  SeedContext({
    required this.seed,
    required this.contractAddress,
    this.rpcUrl = 'https://anvil.hostr.development',
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
    if (_httpClient == null) {
      // Use a short idleTimeout so the client proactively drops keep-alive
      // connections before the nginx proxy's 65-second server-side timeout
      // closes them, which would otherwise cause stale-connection errors
      // ("Connection closed before full header was received") after long
      // idle periods between RPC call batches.
      _httpClient = IOClient(
        dart_io.HttpClient()..idleTimeout = const Duration(seconds: 10),
      );
    }
    _web3Client ??= Web3Client(rpcUrl, _httpClient!);
    return _web3Client!;
  }

  /// Disposes and recreates the chain client, but only if [ifGeneration]
  /// matches the current generation counter.
  ///
  /// This prevents the cascading-cancel problem that arises when many parallel
  /// [retryChainCall] coroutines share one [_httpClient]: when the first
  /// coroutine calls [_httpClient.close()] it cancels every other in-flight
  /// request, causing all of them to also land in the catch block.  Without
  /// generation-gating, each of those would call [resetChainClient] again,
  /// disposing the *fresh* client that the first coroutine just created.
  ///
  /// Because Dart is single-threaded, the synchronous reset runs atomically
  /// (no await), so the first caller wins and increments the generation before
  /// any other coroutine can execute its catch block.
  void _resetChainClientIfGeneration(int ifGeneration) {
    if (_clientGeneration != ifGeneration) return;
    _web3Client?.dispose();
    _web3Client = null;
    _httpClient?.close();
    _httpClient = null;
    _escrowContracts.clear();
    _clientGeneration++;
  }

  /// Runs [fn] against the chain client, retrying up to [retries] times on
  /// a [http.ClientException] (stale keep-alive connection) by recreating
  /// the underlying HTTP client before each retry.
  ///
  /// Each attempt captures the current [_clientGeneration] before the async
  /// gap so that only the first failing coroutine in a parallel [Future.wait]
  /// actually resets the shared client; all others are no-ops.
  Future<T> retryChainCall<T>(
    Future<T> Function(Web3Client) fn, {
    int retries = 1,
  }) async {
    for (int attempt = 1; attempt <= retries + 1; attempt++) {
      // Capture the generation BEFORE the await so that if this coroutine's
      // connection is cancelled by a sibling's reset, we can detect it.
      final gen = _clientGeneration;
      try {
        return await fn(chainClient());
      } on http.ClientException catch (e) {
        if (attempt > retries) rethrow;
        print(
          '[chain] Stale connection on attempt $attempt – resetting client: $e',
        );
        _resetChainClientIfGeneration(gen);
      }
    }
    throw StateError('unreachable');
  }

  AnvilClient anvilClient() {
    _anvilClient ??= AnvilClient(rpcUri: Uri.parse(rpcUrl));
    return _anvilClient!;
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
    _web3Client = null;
    _httpClient?.close();
    _httpClient = null;
    _escrowContracts.clear();
    _clientGeneration++;
  }
}
