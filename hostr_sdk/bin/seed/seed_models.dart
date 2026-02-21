class DeterministicSeedConfig {
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
  final int seed;
  final int userCount;
  final double hostRatio;
  final double hostHasEvmRatio;
  final double paidViaEscrowRatio;
  final double paidViaEscrowArbitrateRatio;
  final double paidViaEscrowClaimedRatio;
  final double listingsPerHostAvg;
  final int reservationRequestsPerGuest;
  final double completedRatio;
  final int messagesPerThreadAvg;
  final double reviewRatio;

  const DeterministicSeedConfig({
    this.relayUrl = 'ws://relay.hostr.development',
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
    this.paidViaEscrowRatio = 1,
    this.paidViaEscrowArbitrateRatio = 0.15,
    this.paidViaEscrowClaimedRatio = 0.7,
    this.listingsPerHostAvg = 1.6,
    this.reservationRequestsPerGuest = 10,
    this.completedRatio = 0.5,
    this.messagesPerThreadAvg = 3,
    this.reviewRatio = 0.5,
  });

  factory DeterministicSeedConfig.fromJson(Map<String, dynamic> json) {
    return DeterministicSeedConfig(
      relayUrl:
          _asStringOrNull(json['relayUrl']) ?? 'ws://relay.hostr.development',
      rpcUrl: _asStringOrNull(json['rpcUrl']) ?? 'http://localhost:8545',
      fundProfiles: _asBool(json['fundProfiles'], fallback: true),
      setupLnbits: _asBool(json['setupLnbits'], fallback: false),
      fundAmountWei: _asBigIntOrNull(json['fundAmountWei']),
      lnbits1BaseUrl:
          _asStringOrNull(json['lnbits1BaseUrl']) ?? 'http://localhost:5055',
      lnbits2BaseUrl:
          _asStringOrNull(json['lnbits2BaseUrl']) ?? 'http://localhost:5056',
      lnbitsAdminEmail:
          _asStringOrNull(json['lnbitsAdminEmail']) ?? 'admin@example.com',
      lnbitsAdminPassword:
          _asStringOrNull(json['lnbitsAdminPassword']) ?? 'adminpassword',
      lnbitsExtensionName:
          _asStringOrNull(json['lnbitsExtensionName']) ?? 'lnurlp',
      lnbitsNostrPrivateKey: _asStringOrNull(json['lnbitsNostrPrivateKey']),
      seed: _asInt(json['seed'], fallback: 1),
      userCount: _asInt(json['userCount'], fallback: 40),
      hostRatio: _asDouble(json['hostRatio'], fallback: 0.35),
      hostHasEvmRatio: _asDouble(json['hostHasEvmRatio'], fallback: 0.8),
      paidViaEscrowRatio: _asDouble(json['paidViaEscrowRatio'], fallback: 0.55),
      paidViaEscrowArbitrateRatio: _asDouble(
        json['paidViaEscrowArbitrateRatio'],
        fallback: 0.15,
      ),
      paidViaEscrowClaimedRatio: _asDouble(
        json['paidViaEscrowClaimedRatio'],
        fallback: 0.7,
      ),
      listingsPerHostAvg: _asDouble(json['listingsPerHostAvg'], fallback: 1.6),
      reservationRequestsPerGuest: _asInt(
        json['reservationRequestsPerGuest'],
        fallback: 2,
      ),
      completedRatio: _asDouble(json['completedRatio'], fallback: 0.55),
      messagesPerThreadAvg: _asInt(json['messagesPerThreadAvg'], fallback: 3),
      reviewRatio: _asDouble(json['reviewRatio'], fallback: 0.55),
    ).validated();
  }

  DeterministicSeedConfig validated() {
    return DeterministicSeedConfig(
      relayUrl: relayUrl,
      rpcUrl: rpcUrl,
      fundProfiles: fundProfiles,
      setupLnbits: setupLnbits,
      fundAmountWei: fundAmountWei,
      lnbits1BaseUrl: lnbits1BaseUrl,
      lnbits2BaseUrl: lnbits2BaseUrl,
      lnbitsAdminEmail: lnbitsAdminEmail,
      lnbitsAdminPassword: lnbitsAdminPassword,
      lnbitsExtensionName: lnbitsExtensionName,
      lnbitsNostrPrivateKey: lnbitsNostrPrivateKey,
      seed: seed,
      userCount: userCount < 2 ? 2 : userCount,
      hostRatio: _clamp01(hostRatio),
      hostHasEvmRatio: _clamp01(hostHasEvmRatio),
      paidViaEscrowRatio: _clamp01(paidViaEscrowRatio),
      paidViaEscrowArbitrateRatio: _clamp01(paidViaEscrowArbitrateRatio),
      paidViaEscrowClaimedRatio: _clamp01(paidViaEscrowClaimedRatio),
      listingsPerHostAvg: listingsPerHostAvg < 0 ? 0 : listingsPerHostAvg,
      reservationRequestsPerGuest: reservationRequestsPerGuest < 0
          ? 0
          : reservationRequestsPerGuest,
      completedRatio: _clamp01(completedRatio),
      messagesPerThreadAvg: messagesPerThreadAvg < 0 ? 0 : messagesPerThreadAvg,
      reviewRatio: _clamp01(reviewRatio),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'paidViaEscrowRatio': paidViaEscrowRatio,
      'paidViaEscrowArbitrateRatio': paidViaEscrowArbitrateRatio,
      'paidViaEscrowClaimedRatio': paidViaEscrowClaimedRatio,
      'listingsPerHostAvg': listingsPerHostAvg,
      'reservationRequestsPerGuest': reservationRequestsPerGuest,
      'completedRatio': completedRatio,
      'messagesPerThreadAvg': messagesPerThreadAvg,
      'reviewRatio': reviewRatio,
    };
  }
}

class SeedSummary {
  final int users;
  final int hosts;
  final int guests;
  final int profiles;
  final int listings;
  final int reservationRequests;
  final int messages;
  final int reservations;
  final int zapReceipts;
  final int reviews;
  final int escrowServices;
  final int escrowTrusts;
  final int escrowMethods;

  const SeedSummary({
    required this.users,
    required this.hosts,
    required this.guests,
    required this.profiles,
    required this.listings,
    required this.reservationRequests,
    required this.messages,
    required this.reservations,
    required this.zapReceipts,
    required this.reviews,
    required this.escrowServices,
    required this.escrowTrusts,
    required this.escrowMethods,
  });
}

int _asInt(dynamic value, {required int fallback}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _asDouble(dynamic value, {required double fallback}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String? _asStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return value;
  return null;
}

bool _asBool(dynamic value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return fallback;
}

BigInt? _asBigIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is BigInt) return value;
  if (value is int) return BigInt.from(value);
  if (value is String) return BigInt.tryParse(value);
  return null;
}

double _clamp01(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}
