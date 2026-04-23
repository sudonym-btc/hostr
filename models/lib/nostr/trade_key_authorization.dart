import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class TradeKeyAuthorizationTags extends EventTags
    with ReferencesListing<TradeKeyAuthorizationTags> {
  TradeKeyAuthorizationTags(super.tags);

  String? get tradeId {
    final tTags = getTags('t');
    return tTags.isNotEmpty ? tTags.first : null;
  }
}

class TradeKeyAuthorization extends JsonContentNostrEvent<
    TradeKeyAuthorizationContent, TradeKeyAuthorizationTags> {
  static const List<int> kinds = [kNostrKindTradeKeyAuthorization];
  static final EventTagsParser<TradeKeyAuthorizationTags> _tagParser =
      TradeKeyAuthorizationTags.new;
  static final EventContentParser<TradeKeyAuthorizationContent> _contentParser =
      TradeKeyAuthorizationContent.fromJson;

  String get role => parsedContent.role;
  String get participantPubkey => parsedContent.participantPubkey;
  String get tradeId => parsedTags.tradeId ?? '';
  String get listingAnchor => parsedTags.listingAnchor;

  TradeKeyAuthorization({
    required super.pubKey,
    required super.tags,
    required super.content,
    super.createdAt,
    super.id,
    super.sig,
  }) : super(
          kind: kNostrKindTradeKeyAuthorization,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );

  TradeKeyAuthorization.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );

  factory TradeKeyAuthorization.create({
    required String identityPubkey,
    required String listingAnchor,
    required String tradeId,
    required String participantPubkey,
    required String role,
    int? createdAt,
  }) {
    return TradeKeyAuthorization(
      pubKey: identityPubkey,
      tags: TradeKeyAuthorizationTags([
        [kListingRefTag, listingAnchor],
        ['t', tradeId],
      ]),
      content: TradeKeyAuthorizationContent(
        role: role,
        participantPubkey: participantPubkey,
      ),
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  bool authorizesParticipant({
    required String identityPubkey,
    required String listingAnchor,
    required String tradeId,
    required String participantPubkey,
    required String role,
  }) {
    if (pubKey != identityPubkey) return false;
    if (!valid()) return false;
    if (this.listingAnchor != listingAnchor) return false;
    if (this.tradeId != tradeId) return false;
    if (this.participantPubkey != participantPubkey) return false;
    if (this.role != role) return false;
    return true;
  }
}

class TradeKeyAuthorizationContent extends EventContent {
  final int version;
  final String role;
  final String participantPubkey;

  TradeKeyAuthorizationContent({
    this.version = 1,
    required this.role,
    required this.participantPubkey,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'role': role,
      'participantPubkey': participantPubkey,
    };
  }

  static TradeKeyAuthorizationContent fromJson(Map<String, dynamic> json) {
    return TradeKeyAuthorizationContent(
      version: json['version'] as int? ?? 1,
      role: json['role'] as String,
      participantPubkey: json['participantPubkey'] as String,
    );
  }
}
