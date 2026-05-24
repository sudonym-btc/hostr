import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import 'payment_method.dart';
import 'type_json_content.dart';

class EscrowService
    extends JsonContentNostrEvent<EscrowServiceContent, EventTags> {
  static const List<int> kinds = [kNostrKindEscrowService];
  static final EventTagsParser<EventTags> _tagParser = EventTags.new;
  static final EventContentParser<EscrowServiceContent> _contentParser =
      EscrowServiceContent.fromJson;

  static const List<List<String>> requiredTags = [
    ['d'],
  ];

  // ── Convenience getters ─────────────────────────────────────────────
  String get escrowPubkey => parsedContent.pubkey;
  String get arbiterAddress => parsedContent.params.arbiterAddress;
  String get evmAddress => arbiterAddress;
  String get contractAddress => parsedContent.params.contractAddress;
  String get contractBytecodeHash => parsedContent.params.contractBytecodeHash;
  int get chainId => parsedContent.params.chainId;
  Duration get maxDuration => parsedContent.maxDuration;
  EscrowType get escrowType => parsedContent.type;
  EscrowFee get fee => parsedContent.fee;
  BigInt escrowFee(BigInt amount, {String tokenAddress = 'native'}) =>
      parsedContent.escrowFee(amount, tokenAddress: tokenAddress);

  EscrowService(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
            kind: kNostrKindEscrowService,
            tagParser: _tagParser,
            contentParser: _contentParser);

  EscrowService.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
          requiredTags: requiredTags,
        );
}

/// Fee policy published by the escrow operator.
///
/// Amount values are in the selected asset's smallest unit. Asset overrides are
/// keyed by token contract address, or `native` for the chain's native asset.
class EscrowFee {
  static final BigInt _ppmDenominator = BigInt.from(1000000);

  /// Proportional fee in parts per million.
  final int ppm;

  /// Flat fee added after the proportional fee.
  final BigInt base;

  /// Minimum fee floor. Zero means no floor.
  final BigInt min;

  /// Maximum fee cap. Zero means no cap.
  final BigInt max;

  /// Per-asset complete fee overrides.
  final Map<String, EscrowFee> assetOverrides;

  EscrowFee({
    this.ppm = 0,
    BigInt? base,
    BigInt? min,
    BigInt? max,
    this.assetOverrides = const {},
  })  : base = base ?? BigInt.zero,
        min = min ?? BigInt.zero,
        max = max ?? BigInt.zero;

  EscrowFee forAsset(String asset) => assetOverrides[asset] ?? this;

  BigInt calculate(BigInt amount) {
    var value = (amount * BigInt.from(ppm)) ~/ _ppmDenominator + base;
    if (min > BigInt.zero && value < min) {
      value = min;
    }
    if (max > BigInt.zero && value > max) {
      value = max;
    }
    return value;
  }

  Map<String, dynamic> toJson({bool includeAssetOverrides = true}) => {
        'ppm': ppm,
        'base': base.toString(),
        'min': min.toString(),
        'max': max.toString(),
        if (includeAssetOverrides && assetOverrides.isNotEmpty)
          'assetOverrides': assetOverrides.map(
            (key, value) =>
                MapEntry(key, value.toJson(includeAssetOverrides: false)),
          ),
      };

  factory EscrowFee.fromJson(Map<String, dynamic> json) {
    final rawOverrides = json['assetOverrides'];
    final overrides = <String, EscrowFee>{};
    if (rawOverrides is Map) {
      for (final entry in rawOverrides.entries) {
        final value = entry.value;
        if (value is Map) {
          overrides[entry.key.toString()] = EscrowFee.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
    }

    final ppm = (json['ppm'] as num?)?.toInt() ?? 0;
    if (ppm < 0) {
      throw FormatException('Invalid escrow fee "ppm": $ppm');
    }

    return EscrowFee(
      ppm: ppm,
      base: _amountFromJson(json['base'], 'base'),
      min: _amountFromJson(json['min'], 'min'),
      max: _amountFromJson(json['max'], 'max'),
      assetOverrides: overrides,
    );
  }

  static BigInt _amountFromJson(dynamic value, String field) {
    if (value == null) return BigInt.zero;
    if (value is BigInt) return value;
    if (value is int) return BigInt.from(value);
    if (value is num) return BigInt.from(value.toInt());
    final parsed = BigInt.tryParse(value.toString());
    if (parsed == null || parsed < BigInt.zero) {
      throw FormatException('Invalid escrow fee "$field": $value');
    }
    return parsed;
  }

  static final zero = EscrowFee();
}

class EscrowServiceParams {
  final String arbiterAddress;
  final String contractAddress;
  final String contractBytecodeHash;
  final int chainId;

  const EscrowServiceParams({
    required this.arbiterAddress,
    required this.contractAddress,
    required this.contractBytecodeHash,
    required this.chainId,
  });

  Map<String, dynamic> toJson() => {
        'arbiterAddress': arbiterAddress,
        'contractAddress': contractAddress,
        'contractBytecodeHash': contractBytecodeHash,
        'chainId': chainId,
      };

  factory EscrowServiceParams.fromJson(Map<String, dynamic> json) =>
      EscrowServiceParams(
        arbiterAddress: json['arbiterAddress'],
        contractAddress: json['contractAddress'],
        contractBytecodeHash: json['contractBytecodeHash'],
        chainId: json['chainId'],
      );
}

class EscrowServiceContent extends EventContent {
  final String pubkey;
  final EscrowType type;
  final Duration maxDuration;

  /// Fee policy for the escrow service.
  final EscrowFee fee;

  /// Service-type specific parameters.
  final EscrowServiceParams params;

  String get arbiterAddress => params.arbiterAddress;
  String get evmAddress => arbiterAddress;
  String get contractAddress => params.contractAddress;
  String get contractBytecodeHash => params.contractBytecodeHash;
  int get chainId => params.chainId;

  /// Compute the escrow fee for a given [amount] in token smallest units.
  ///
  /// `fee = clamp(floor(amount * ppm / 1,000,000) + base, min, max)`
  ///
  /// [tokenAddress] should be the ERC-20 contract address or `'native'`.
  BigInt escrowFee(BigInt amount, {String tokenAddress = 'native'}) =>
      fee.forAsset(tokenAddress).calculate(amount);

  EscrowServiceContent(
      {required this.pubkey,
      required this.type,
      required this.maxDuration,
      EscrowFee? fee,
      required this.params})
      : fee = fee ?? EscrowFee.zero;

  @override
  Map<String, dynamic> toJson() {
    return {
      "pubkey": pubkey,
      "type": type.toString().split('.').last,
      "maxDuration": maxDuration.inSeconds,
      "fee": fee.toJson(),
      "params": params.toJson(),
    };
  }

  static EscrowServiceContent fromJson(Map<String, dynamic> json) {
    final rawFee = json["fee"];
    final rawParams = json["params"] as Map;

    return EscrowServiceContent(
      pubkey: json["pubkey"],
      type: EscrowType.values
          .firstWhere((e) => e.toString() == 'EscrowType.${json["type"]}'),
      maxDuration: Duration(seconds: json["maxDuration"]),
      fee: rawFee is Map
          ? EscrowFee.fromJson(Map<String, dynamic>.from(rawFee))
          : EscrowFee.zero,
      params: EscrowServiceParams.fromJson(
        Map<String, dynamic>.from(rawParams),
      ),
    );
  }
}

enum EscrowType {
  EVM(PaymentMethod.evm);

  final PaymentMethod paymentMethod;
  const EscrowType(this.paymentMethod);
}

enum ChainIds {
  Rootstock(30),
  RootstockRegtest(33),
  Arbitrum(42161),
  ArbitrumRegtest(412346);

  final int value;
  const ChainIds(this.value);
}
