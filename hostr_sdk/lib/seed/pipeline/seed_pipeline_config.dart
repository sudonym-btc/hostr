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
  final String? tradeSponsorPrivateKey;
  final String lnbitsBaseUrl;
  final String lnbitsAdminEmail;
  final String lnbitsAdminPassword;
  final String lnbitsExtensionName;
  final String? lnbitsNostrPrivateKey;
  final String multiEscrowBytecodeHash;
  final String? signetBunkerUrl;

  // ── EVM chain / token addresses ──
  final int chainId;
  final String? tbtcAddress;
  final int tbtcDecimals;
  final String? usdtAddress;
  final int usdtDecimals;

  // ── Escrow identity ──
  final String escrowProfileName;
  final String? escrowProfilePicture;

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
    this.rpcUrl = 'https://arbitrum.hostr.development',
    this.fundProfiles = false,
    this.setupLnbits = true,
    this.fundAmountWei,
    this.tradeSponsorPrivateKey,
    this.lnbitsBaseUrl = 'https://lnbits.hostr.development',
    this.lnbitsAdminEmail = 'admin@example.com',
    this.lnbitsAdminPassword = 'adminpassword',
    this.lnbitsExtensionName = 'lnurlp',
    this.lnbitsNostrPrivateKey,
    this.seed = 1,
    this.multiEscrowBytecodeHash = '0xMockMultiEscrowBytecodeHash',
    this.signetBunkerUrl,
    this.chainId = 412346,
    this.tbtcAddress,
    this.tbtcDecimals = 18,
    this.usdtAddress,
    this.usdtDecimals = 6,
    this.escrowProfileName = 'Hostr Escrow',
    this.escrowProfilePicture,
    this.userCount = 50,
    this.hostRatio = 0.5,
    this.hostHasEvmRatio = 1,
    this.listingsPerHostAvg = 1.6,
    this.reservationRequestsPerGuest = 10,
    this.threadStages = const ThreadStageSpec(),
    this.invalidReservationRate = 0,
    this.userOverrides = const [],
  });

  /// Construct from a JSON map (e.g. --config-json or --config-file).
  factory SeedPipelineConfig.fromJson(Map<String, dynamic> json) {
    return SeedPipelineConfig(
      relayUrl: _str(json['relayUrl']) ?? 'wss://relay.hostr.development',
      rpcUrl: _str(json['rpcUrl']) ?? 'https://arbitrum.hostr.development',
      fundProfiles: _bool(json['fundProfiles'], false),
      setupLnbits: _bool(json['setupLnbits'], false),
      fundAmountWei: _bigInt(json['fundAmountWei']),
      tradeSponsorPrivateKey: _str(json['tradeSponsorPrivateKey']),
      lnbitsBaseUrl:
          _str(json['lnbitsBaseUrl']) ?? 'https://lnbits.hostr.development',
      lnbitsAdminEmail: _str(json['lnbitsAdminEmail']) ?? 'admin@example.com',
      lnbitsAdminPassword: _str(json['lnbitsAdminPassword']) ?? 'adminpassword',
      lnbitsExtensionName: _str(json['lnbitsExtensionName']) ?? 'lnurlp',
      lnbitsNostrPrivateKey: _str(json['lnbitsNostrPrivateKey']),
      multiEscrowBytecodeHash:
          _str(json['multiEscrowBytecodeHash']) ??
          '0xMockMultiEscrowBytecodeHash',
      signetBunkerUrl: _str(json['signetBunkerUrl']),
      chainId: _int(json['chainId'], 412346),
      tbtcAddress: _str(json['tbtcAddress']),
      tbtcDecimals: _int(json['tbtcDecimals'], 18),
      usdtAddress: _str(json['usdtAddress']),
      usdtDecimals: _int(json['usdtDecimals'], 6),
      escrowProfileName: _str(json['escrowProfileName']) ?? 'Hostr Escrow',
      escrowProfilePicture: _str(json['escrowProfilePicture']),
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
    'tradeSponsorPrivateKey': tradeSponsorPrivateKey == null
        ? null
        : '<configured>',
    'lnbitsBaseUrl': lnbitsBaseUrl,
    'lnbitsAdminEmail': lnbitsAdminEmail,
    'lnbitsAdminPassword': lnbitsAdminPassword,
    'lnbitsExtensionName': lnbitsExtensionName,
    'lnbitsNostrPrivateKey': lnbitsNostrPrivateKey,
    'multiEscrowBytecodeHash': multiEscrowBytecodeHash,
    'signetBunkerUrl': signetBunkerUrl,
    'chainId': chainId,
    'tbtcAddress': tbtcAddress,
    'tbtcDecimals': tbtcDecimals,
    'usdtAddress': usdtAddress,
    'usdtDecimals': usdtDecimals,
    'escrowProfileName': escrowProfileName,
    'escrowProfilePicture': escrowProfilePicture,
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

  /// Shallow copy with selective overrides.
  SeedPipelineConfig copyWith({
    String? relayUrl,
    String? rpcUrl,
    bool? fundProfiles,
    bool? setupLnbits,
    BigInt? fundAmountWei,
    String? tradeSponsorPrivateKey,
    String? lnbitsBaseUrl,
    String? lnbitsAdminEmail,
    String? lnbitsAdminPassword,
    String? lnbitsExtensionName,
    String? lnbitsNostrPrivateKey,
    String? multiEscrowBytecodeHash,
    String? signetBunkerUrl,
    int? chainId,
    String? tbtcAddress,
    int? tbtcDecimals,
    String? usdtAddress,
    int? usdtDecimals,
    String? escrowProfileName,
    String? escrowProfilePicture,
    int? seed,
    int? userCount,
    double? hostRatio,
    double? hostHasEvmRatio,
    double? listingsPerHostAvg,
    int? reservationRequestsPerGuest,
    ThreadStageSpec? threadStages,
    double? invalidReservationRate,
    List<SeedUserSpec>? userOverrides,
  }) => SeedPipelineConfig(
    relayUrl: relayUrl ?? this.relayUrl,
    rpcUrl: rpcUrl ?? this.rpcUrl,
    fundProfiles: fundProfiles ?? this.fundProfiles,
    setupLnbits: setupLnbits ?? this.setupLnbits,
    fundAmountWei: fundAmountWei ?? this.fundAmountWei,
    tradeSponsorPrivateKey:
        tradeSponsorPrivateKey ?? this.tradeSponsorPrivateKey,
    lnbitsBaseUrl: lnbitsBaseUrl ?? this.lnbitsBaseUrl,
    lnbitsAdminEmail: lnbitsAdminEmail ?? this.lnbitsAdminEmail,
    lnbitsAdminPassword: lnbitsAdminPassword ?? this.lnbitsAdminPassword,
    lnbitsExtensionName: lnbitsExtensionName ?? this.lnbitsExtensionName,
    lnbitsNostrPrivateKey: lnbitsNostrPrivateKey ?? this.lnbitsNostrPrivateKey,
    multiEscrowBytecodeHash:
        multiEscrowBytecodeHash ?? this.multiEscrowBytecodeHash,
    signetBunkerUrl: signetBunkerUrl ?? this.signetBunkerUrl,
    chainId: chainId ?? this.chainId,
    tbtcAddress: tbtcAddress ?? this.tbtcAddress,
    tbtcDecimals: tbtcDecimals ?? this.tbtcDecimals,
    usdtAddress: usdtAddress ?? this.usdtAddress,
    usdtDecimals: usdtDecimals ?? this.usdtDecimals,
    escrowProfileName: escrowProfileName ?? this.escrowProfileName,
    escrowProfilePicture: escrowProfilePicture ?? this.escrowProfilePicture,
    seed: seed ?? this.seed,
    userCount: userCount ?? this.userCount,
    hostRatio: hostRatio ?? this.hostRatio,
    hostHasEvmRatio: hostHasEvmRatio ?? this.hostHasEvmRatio,
    listingsPerHostAvg: listingsPerHostAvg ?? this.listingsPerHostAvg,
    reservationRequestsPerGuest:
        reservationRequestsPerGuest ?? this.reservationRequestsPerGuest,
    threadStages: threadStages ?? this.threadStages,
    invalidReservationRate:
        invalidReservationRate ?? this.invalidReservationRate,
    userOverrides: userOverrides ?? this.userOverrides,
  );

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
