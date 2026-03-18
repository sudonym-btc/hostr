import 'dart:math';

import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

/// Shared mutable context threaded through every pipeline stage.
///
/// Owns the seeded [Random], the base date for timestamp generation,
/// and deterministic key derivation.
///
/// **No I/O, no network, no chain.**  Infrastructure concerns (Web3Client,
/// AnvilClient, MultiEscrow) live in [InfrastructureSink].
class SeedContext {
  final int seed;
  final Random random;
  final DateTime baseDate;
  final String contractAddress;

  SeedContext({
    required this.seed,
    this.contractAddress = '0x0000000000000000000000000000000000000000',
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

  // ── Key derivation ──

  /// Deterministic key pair from seed + index.
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

  /// No-op — kept for API compatibility with callers that call dispose().
  void dispose() {}
}
