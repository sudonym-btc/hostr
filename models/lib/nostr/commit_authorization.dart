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
  static const String reservationCommitHashAlg = 'sha256';
  static const List<String> reservationCommittedFields = [
    'amount',
    'end',
    'quantity',
    'recipient',
    'start',
  ];
  static final EventTagsParser<CommitAuthorizationTags> _tagParser =
      CommitAuthorizationTags.new;
  static final EventContentParser<CommitAuthorizationContent> _contentParser =
      CommitAuthorizationContent.fromJson;

  String get commitHash => parsedContent.commitHash;
  String get role => parsedContent.role;
  String get hashAlg => parsedContent.hashAlg;
  List<String> get committedFields => parsedContent.committedFields;
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
        hashAlg: reservationCommitHashAlg,
        committedFields: reservationCommittedFields,
      ),
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  bool authorizesReservation({
    required String authorPubkey,
    required String listingAnchor,
    required String tradeId,
    required String commitHash,
    Iterable<String> committedFields = reservationCommittedFields,
    String hashAlg = reservationCommitHashAlg,
    String role = 'seller',
  }) {
    if (pubKey != authorPubkey) return false;
    if (!valid()) return false;
    if (this.listingAnchor != listingAnchor) return false;
    if (this.tradeId != tradeId) return false;
    if (this.commitHash != commitHash) return false;
    if (this.hashAlg != hashAlg) return false;
    if (!_sameCommittedFields(this.committedFields, committedFields)) {
      return false;
    }
    if (this.role != role) return false;
    return true;
  }

  static bool _sameCommittedFields(
    Iterable<String> left,
    Iterable<String> right,
  ) {
    final a = left.toSet().toList()..sort();
    final b = right.toSet().toList()..sort();
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class CommitAuthorizationContent extends EventContent {
  final int version;
  final String commitHash;
  final String role;
  final String hashAlg;
  final List<String> committedFields;

  CommitAuthorizationContent({
    this.version = 1,
    required this.commitHash,
    required this.role,
    this.hashAlg = CommitAuthorization.reservationCommitHashAlg,
    Iterable<String> committedFields =
        CommitAuthorization.reservationCommittedFields,
  }) : committedFields = (committedFields.toSet().toList()..sort());

  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'commitHash': commitHash,
      'hashAlg': hashAlg,
      'committedFields': committedFields,
      'role': role,
    };
  }

  static CommitAuthorizationContent fromJson(Map<String, dynamic> json) {
    return CommitAuthorizationContent(
      version: json['version'] as int? ?? 1,
      commitHash: json['commitHash'] as String,
      role: json['role'] as String? ?? 'seller',
      hashAlg: json['hashAlg'] as String? ??
          CommitAuthorization.reservationCommitHashAlg,
      committedFields: (json['committedFields'] as List<dynamic>?)
              ?.map((e) => e.toString()) ??
          CommitAuthorization.reservationCommittedFields,
    );
  }
}
