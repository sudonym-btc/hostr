import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class CommitAuthorizationTags extends EventTags
    with ReferencesListing<CommitAuthorizationTags> {
  CommitAuthorizationTags(super.tags);

  String? get tradeId {
    final dTags = getTags('d');
    return dTags.isNotEmpty ? dTags.first : null;
  }
}

class CommitAuthorization extends JsonContentNostrEvent<
    CommitAuthorizationContent, CommitAuthorizationTags> {
  static const List<int> kinds = [kNostrKindCommitAuthorization];
  static final EventTagsParser<CommitAuthorizationTags> _tagParser =
      CommitAuthorizationTags.new;
  static final EventContentParser<CommitAuthorizationContent> _contentParser =
      CommitAuthorizationContent.fromJson;

  String get commitHash => parsedContent.commitHash;
  String get role => parsedContent.role;
  String? get tradeId => parsedTags.tradeId;
  String get listingAnchor => parsedTags.listingAnchor;

  CommitAuthorization({
    required super.pubKey,
    required super.tags,
    required super.content,
    super.createdAt,
    super.id,
    super.sig,
  }) : super(
          kind: kNostrKindCommitAuthorization,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );

  CommitAuthorization.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );

  factory CommitAuthorization.create({
    required String pubKey,
    required String listingAnchor,
    required String tradeId,
    required String commitHash,
    String role = 'seller',
    int? createdAt,
  }) {
    return CommitAuthorization(
      pubKey: pubKey,
      tags: CommitAuthorizationTags([
        [kListingRefTag, listingAnchor],
        ['d', tradeId],
      ]),
      content: CommitAuthorizationContent(
        commitHash: commitHash,
        role: role,
      ),
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  bool authorizesReservation({
    required String authorPubkey,
    required String listingAnchor,
    required String tradeId,
    required String commitHash,
    String role = 'seller',
  }) {
    if (pubKey != authorPubkey) return false;
    if (!valid()) return false;
    if (this.listingAnchor != listingAnchor) return false;
    if (this.tradeId != tradeId) return false;
    if (this.commitHash != commitHash) return false;
    if (this.role != role) return false;
    return true;
  }
}

class CommitAuthorizationContent extends EventContent {
  final int version;
  final String commitHash;
  final String role;

  CommitAuthorizationContent({
    this.version = 1,
    required this.commitHash,
    required this.role,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'commitHash': commitHash,
      'role': role,
    };
  }

  static CommitAuthorizationContent fromJson(Map<String, dynamic> json) {
    return CommitAuthorizationContent(
      version: json['version'] as int? ?? 1,
      commitHash: json['commitHash'] as String,
      role: json['role'] as String? ?? 'seller',
    );
  }
}
