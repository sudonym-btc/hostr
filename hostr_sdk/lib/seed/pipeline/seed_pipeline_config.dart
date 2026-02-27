/// Configuration for the seed pipeline.
///
/// [SeedPipelineConfig] provides global defaults, while [SeedUserSpec]
/// allows per-user overrides for integration tests or surgical scenarios.
///
/// Thread stage articulation is controlled via [ThreadStageSpec] which lets
/// callers specify exactly how many messages, reservation requests,
/// self-signed reservations, host-approved reservations, etc. to generate
/// per thread.
library;

// ─── Thread stage articulation ──────────────────────────────────────────────

/// Controls what stage each thread reaches in the conversation flow.
///
/// The pipeline generates threads in order:
///   1. reservationRequest  — always created
///   2. textMessages        — filler DMs in the thread
///   3. escrowSelected      — guest picks an escrow service (if escrow path)
///   4. selfSignedReservation — guest publishes reservation with self-signed proof
///   5. hostApprovedReservation — host co-signs / approves the reservation
///   6. outcome             — on-chain escrow settlement or zap receipt
///   7. review              — guest leaves a review
///
/// By setting counts/ratios you control how far each thread progresses.
class ThreadStageSpec {
  /// Average number of text messages per thread (both directions).
  final int textMessageCount;

  /// Whether a reservation request is generated. Always true in practice
  /// (a thread without a request is just DMs), but included for completeness.
  final bool withReservationRequest;

  /// Fraction of threads where the guest publishes a self-signed reservation
  /// (i.e. reservation with payment proof but no host approval).
  /// Only meaningful when [withOutcome] is true.
  final double selfSignedReservationRatio;

  /// Fraction of threads that reach a completed outcome (escrow settlement
  /// or zap payment). Set to 0.0 for integration tests that need to drive
  /// the outcome themselves.
  final double completedRatio;

  /// Of completed threads, fraction that use escrow (vs zap).
  final double paidViaEscrowRatio;

  /// Of escrow-completed threads, fraction where arbiter intervenes.
  final double paidViaEscrowArbitrateRatio;

  /// Of escrow-completed threads, fraction where host claims after unlock.
  final double paidViaEscrowClaimedRatio;

  /// Fraction of completed threads that get a review.
  final double reviewRatio;

  const ThreadStageSpec({
    this.textMessageCount = 3,
    this.withReservationRequest = true,
    this.selfSignedReservationRatio = 0.0,
    this.completedRatio = 0.5,
    this.paidViaEscrowRatio = 1.0,
    this.paidViaEscrowArbitrateRatio = 0.15,
    this.paidViaEscrowClaimedRatio = 0.7,
    this.reviewRatio = 0.5,
  });

  /// All threads complete with outcomes resolved.
  const ThreadStageSpec.allCompleted({
    this.textMessageCount = 3,
    this.withReservationRequest = true,
    this.selfSignedReservationRatio = 0.0,
    this.completedRatio = 1.0,
    this.paidViaEscrowRatio = 1.0,
    this.paidViaEscrowArbitrateRatio = 0.15,
    this.paidViaEscrowClaimedRatio = 0.7,
    this.reviewRatio = 0.5,
  });

  /// Threads stop at reservation request — no outcomes. For integration tests
  /// that need to drive the payment/escrow flow themselves.
  const ThreadStageSpec.pendingOnly({
    this.textMessageCount = 1,
    this.withReservationRequest = true,
    this.selfSignedReservationRatio = 0.0,
    this.completedRatio = 0.0,
    this.paidViaEscrowRatio = 0.0,
    this.paidViaEscrowArbitrateRatio = 0.0,
    this.paidViaEscrowClaimedRatio = 0.0,
    this.reviewRatio = 0.0,
  });
}

// ─── Per-user specification ─────────────────────────────────────────────────

enum UserRole { host, guest }

/// Per-user override. When added to [SeedPipelineConfig.userOverrides],
/// the pipeline creates this user with the exact settings specified instead
/// of drawing from global ratios.
class SeedUserSpec {
  final UserRole role;
  final bool hasEvm;
  final bool setupLnbits;

  /// Number of listings this host publishes. Ignored for guests.
  final int? listingCount;

  /// Number of threads this user participates in (as guest → sends requests,
  /// as host → receives requests).
  final int? threadCount;

  /// Per-user thread stage override. Falls back to global if null.
  final ThreadStageSpec? threadStages;

  const SeedUserSpec({
    required this.role,
    this.hasEvm = false,
    this.setupLnbits = false,
    this.listingCount,
    this.threadCount,
    this.threadStages,
  });

  /// Quick host spec for integration tests.
  const SeedUserSpec.host({
    this.hasEvm = true,
    this.setupLnbits = false,
    this.listingCount = 1,
    this.threadCount,
    this.threadStages,
  }) : role = UserRole.host;

  /// Quick guest spec for integration tests.
  const SeedUserSpec.guest({
    this.hasEvm = false,
    this.setupLnbits = false,
    this.threadCount,
    this.threadStages,
  }) : role = UserRole.guest,
       listingCount = null;
}

// ─── Pipeline config ────────────────────────────────────────────────────────

class SeedPipelineConfig {
  // ── Infrastructure ──
  final String? relayUrl;
  final String rpcUrl;
  final bool fundProfiles;
  final bool setupLnbits;
  final BigInt? fundAmountWei;
  final String lnbits1BaseUrl;
  final String lnbits2BaseUrl;
  final String lnbitsAdminEmail;
  final String lnbitsAdminPassword;
  final String lnbitsExtensionName;
  final String? lnbitsNostrPrivateKey;

  // ── Determinism ──
  final int seed;

  // ── Population (global defaults for random users) ──
  final int userCount;
  final double hostRatio;
  final double hostHasEvmRatio;
  final double listingsPerHostAvg;
  final int reservationRequestsPerGuest;

  // ── Thread stage defaults ──
  final ThreadStageSpec threadStages;

  /// Probability that a generated reservation is intentionally corrupted.
  /// When triggered, the reservation either omits a payment proof entirely
  /// or references a bogus transaction hash/chain combination.
  final double invalidReservationRate;

  // ── Per-user overrides (sparse) ──
  final List<SeedUserSpec> userOverrides;

  const SeedPipelineConfig({
    this.relayUrl = 'wss://relay.hostr.development',
    this.rpcUrl = 'http://localhost:8545',
    this.fundProfiles = true,
    this.setupLnbits = true,
    this.fundAmountWei,
    this.lnbits1BaseUrl = 'http://localhost:5055',
    this.lnbits2BaseUrl = 'http://localhost:5056',
    this.lnbitsAdminEmail = 'admin@example.com',
    this.lnbitsAdminPassword = 'adminpassword',
    this.lnbitsExtensionName = 'lnurlp',
    this.lnbitsNostrPrivateKey,
    this.seed = 1,
    this.userCount = 50,
    this.hostRatio = 0.25,
    this.hostHasEvmRatio = 0.8,
    this.listingsPerHostAvg = 1.6,
    this.reservationRequestsPerGuest = 10,
    this.threadStages = const ThreadStageSpec(),
    this.invalidReservationRate = 0.2,
    this.userOverrides = const [],
  });

  /// Construct from a JSON map (e.g. --config-json or --config-file).
  factory SeedPipelineConfig.fromJson(Map<String, dynamic> json) {
    return SeedPipelineConfig(
      relayUrl: _str(json['relayUrl']) ?? 'wss://relay.hostr.development',
      rpcUrl: _str(json['rpcUrl']) ?? 'http://localhost:8545',
      fundProfiles: _bool(json['fundProfiles'], true),
      setupLnbits: _bool(json['setupLnbits'], false),
      fundAmountWei: _bigInt(json['fundAmountWei']),
      lnbits1BaseUrl: _str(json['lnbits1BaseUrl']) ?? 'http://localhost:5055',
      lnbits2BaseUrl: _str(json['lnbits2BaseUrl']) ?? 'http://localhost:5056',
      lnbitsAdminEmail: _str(json['lnbitsAdminEmail']) ?? 'admin@example.com',
      lnbitsAdminPassword: _str(json['lnbitsAdminPassword']) ?? 'adminpassword',
      lnbitsExtensionName: _str(json['lnbitsExtensionName']) ?? 'lnurlp',
      lnbitsNostrPrivateKey: _str(json['lnbitsNostrPrivateKey']),
      seed: _int(json['seed'], 1),
      userCount: _int(json['userCount'], 50),
      hostRatio: _dbl(json['hostRatio'], 0.25),
      hostHasEvmRatio: _dbl(json['hostHasEvmRatio'], 0.8),
      listingsPerHostAvg: _dbl(json['listingsPerHostAvg'], 1.6),
      reservationRequestsPerGuest: _int(
        json['reservationRequestsPerGuest'],
        10,
      ),
      invalidReservationRate: _dbl(json['invalidReservationRate'], 0.0),
      threadStages: ThreadStageSpec(
        textMessageCount: _int(json['messagesPerThreadAvg'], 3),
        completedRatio: _dbl(json['completedRatio'], 0.5),
        paidViaEscrowRatio: _dbl(json['paidViaEscrowRatio'], 1.0),
        paidViaEscrowArbitrateRatio: _dbl(
          json['paidViaEscrowArbitrateRatio'],
          0.15,
        ),
        paidViaEscrowClaimedRatio: _dbl(json['paidViaEscrowClaimedRatio'], 0.7),
        reviewRatio: _dbl(json['reviewRatio'], 0.5),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'relayUrl': relayUrl,
    'rpcUrl': rpcUrl,
    'fundProfiles': fundProfiles,
    'setupLnbits': setupLnbits,
    'fundAmountWei': fundAmountWei?.toString(),
    'lnbits1BaseUrl': lnbits1BaseUrl,
    'lnbits2BaseUrl': lnbits2BaseUrl,
    'lnbitsAdminEmail': lnbitsAdminEmail,
    'lnbitsAdminPassword': lnbitsAdminPassword,
    'lnbitsExtensionName': lnbitsExtensionName,
    'lnbitsNostrPrivateKey': lnbitsNostrPrivateKey,
    'seed': seed,
    'userCount': userCount,
    'hostRatio': hostRatio,
    'hostHasEvmRatio': hostHasEvmRatio,
    'listingsPerHostAvg': listingsPerHostAvg,
    'reservationRequestsPerGuest': reservationRequestsPerGuest,
    'invalidReservationRate': invalidReservationRate,
    'threadStages': {
      'textMessageCount': threadStages.textMessageCount,
      'completedRatio': threadStages.completedRatio,
      'paidViaEscrowRatio': threadStages.paidViaEscrowRatio,
      'paidViaEscrowArbitrateRatio': threadStages.paidViaEscrowArbitrateRatio,
      'paidViaEscrowClaimedRatio': threadStages.paidViaEscrowClaimedRatio,
      'reviewRatio': threadStages.reviewRatio,
    },
    'userOverrides': userOverrides.length,
  };

  // ── JSON helpers ──
  static int _int(dynamic v, int fb) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v) ?? fb;
    return fb;
  }

  static double _dbl(dynamic v, double fb) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fb;
    return fb;
  }

  static String? _str(dynamic v) => (v is String && v.isNotEmpty) ? v : null;

  static bool _bool(dynamic v, bool fb) {
    if (v is bool) return v;
    if (v is String) {
      if (v.toLowerCase() == 'true') return true;
      if (v.toLowerCase() == 'false') return false;
    }
    return fb;
  }

  static BigInt? _bigInt(dynamic v) {
    if (v is BigInt) return v;
    if (v is int) return BigInt.from(v);
    if (v is String) return BigInt.tryParse(v);
    return null;
  }
}
