import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
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
  String get evmAddress => parsedContent.evmAddress;
  String get contractAddress => parsedContent.contractAddress;
  String get contractBytecodeHash => parsedContent.contractBytecodeHash;
  int get chainId => parsedContent.chainId;
  Duration get maxDuration => parsedContent.maxDuration;
  EscrowType get escrowType => parsedContent.type;
  double get feePercent => parsedContent.feePercent;
  Map<String, TokenFeeHints> get tokenFeeHints => parsedContent.tokenFeeHints;
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

/// Per-token fee hints published by the escrow operator.
///
/// All values are in the token's smallest unit. When absent, defaults to zero.
class TokenFeeHints {
  /// Flat base fee in the token's smallest unit (e.g. 500 sats for BTC,
  /// 50000 micro-USDT for USDT). Added on top of [EscrowServiceContent.feePercent].
  final int baseFee;

  /// Maximum fee cap in the token's smallest unit. Zero means no cap.
  final int maxFee;

  /// Minimum fee floor in the token's smallest unit. Zero means no floor.
  final int minFee;

  const TokenFeeHints({
    this.baseFee = 0,
    this.maxFee = 0,
    this.minFee = 0,
  });

  Map<String, dynamic> toJson() => {
        'baseFee': baseFee,
        'maxFee': maxFee,
        'minFee': minFee,
      };

  factory TokenFeeHints.fromJson(Map<String, dynamic> json) => TokenFeeHints(
        baseFee: (json['baseFee'] as num?)?.toInt() ?? 0,
        maxFee: (json['maxFee'] as num?)?.toInt() ?? 0,
        minFee: (json['minFee'] as num?)?.toInt() ?? 0,
      );

  static const zero = TokenFeeHints();
}

class EscrowServiceContent extends EventContent {
  final String pubkey;
  final String evmAddress;
  final String contractAddress;
  final String contractBytecodeHash;
  final int chainId;
  final Duration maxDuration;
  final EscrowType type;

  /// Proportional fee as a percentage of the escrow amount (e.g. 1.5 = 1.5%).
  final double feePercent;

  /// Optional per-token fee hints keyed by token address (or `'native'` for
  /// the chain's native asset). When absent for a token, all hints default
  /// to zero.
  final Map<String, TokenFeeHints> tokenFeeHints;

  /// Compute the escrow fee for a given [amount] in token smallest units.
  ///
  /// Uses [feePercent] plus the per-token [baseFee] from [tokenFeeHints].
  /// The result is clamped to [minFee, maxFee] when those hints are set.
  ///
  /// `fee = floor(amount × feePercent / 100) + baseFee`
  ///
  /// [tokenAddress] should be the ERC-20 contract address or `'native'`.
  BigInt escrowFee(BigInt amount, {String tokenAddress = 'native'}) {
    final hints = tokenFeeHints[tokenAddress] ?? TokenFeeHints.zero;
    var fee = (amount * BigInt.from((feePercent * 100).round())) ~/
            BigInt.from(10000) +
        BigInt.from(hints.baseFee);
    if (hints.minFee > 0 && fee < BigInt.from(hints.minFee)) {
      fee = BigInt.from(hints.minFee);
    }
    if (hints.maxFee > 0 && fee > BigInt.from(hints.maxFee)) {
      fee = BigInt.from(hints.maxFee);
    }
    return fee;
  }

  EscrowServiceContent(
      {required this.pubkey,
      required this.evmAddress,
      required this.contractAddress,
      required this.contractBytecodeHash,
      required this.chainId,
      required this.maxDuration,
      required this.type,
      this.feePercent = 0,
      this.tokenFeeHints = const {}});

  @override
  Map<String, dynamic> toJson() {
    return {
      "pubkey": pubkey,
      "evmAddress": evmAddress,
      "contractAddress": contractAddress,
      "contractBytecodeHash": contractBytecodeHash,
      "chainId": chainId,
      "maxDuration": maxDuration.inSeconds,
      "type": type.toString().split('.').last,
      "feePercent": feePercent,
      if (tokenFeeHints.isNotEmpty)
        "tokenFeeHints": tokenFeeHints.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
    };
  }

  static EscrowServiceContent fromJson(Map<String, dynamic> json) {
    final rawHints = json["tokenFeeHints"] as Map<String, dynamic>?;
    final hints = <String, TokenFeeHints>{};
    if (rawHints != null) {
      for (final entry in rawHints.entries) {
        hints[entry.key] = TokenFeeHints.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    return EscrowServiceContent(
      pubkey: json["pubkey"],
      evmAddress: json["evmAddress"],
      contractAddress: json["contractAddress"],
      contractBytecodeHash: json["contractBytecodeHash"],
      chainId: json["chainId"],
      maxDuration: Duration(seconds: json["maxDuration"]),
      type: EscrowType.values
          .firstWhere((e) => e.toString() == 'EscrowType.${json["type"]}'),
      feePercent: (json["feePercent"] as num?)?.toDouble() ?? 0,
      tokenFeeHints: hints,
    );
  }
}

enum EscrowType { EVM }

enum ChainIds {
  Rootstock(30),
  RootstockRegtest(33),
  Arbitrum(42161),
  ArbitrumRegtest(412346);

  final int value;
  const ChainIds(this.value);
}
