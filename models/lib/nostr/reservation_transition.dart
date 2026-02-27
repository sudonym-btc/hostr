import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class ReservationTransitionTags extends EventTags
    with ReferencesListing<ReservationTransitionTags> {
  ReservationTransitionTags(super.tags);

  /// The t tag (trade identifier) linking this transition to its reservation.
  String? get tradeId {
    final tTags = getTags('t');
    return tTags.isNotEmpty ? tTags.first : null;
  }

  /// The event id of the reservation this transition applies to (`e` tag).
  String? get reservationEventId {
    final eTags = getTags('e');
    return eTags.isNotEmpty ? eTags.first : null;
  }

  /// Optional: the event id of the previous transition in the chain,
  /// forming a monotonic log of stage transitions.
  String? get prevTransitionId {
    final tags = getTags('prev');
    return tags.isNotEmpty ? tags.first : null;
  }
}

/// Records a stage transition on a reservation.
///
/// Every time a buyer or seller changes the reservation's stage (negotiate →
/// commit, negotiate → cancel, commit → cancel, or a counter-offer within
/// negotiate), they MUST broadcast a [ReservationTransition] event so that
/// relays and other clients can audit the history.
///
/// Each transition references its parent reservation via an `e` tag and
/// optionally chains to the previous transition via a `prev` tag, forming
/// a monotonic log.
class ReservationTransition extends JsonContentNostrEvent<
    ReservationTransitionContent, ReservationTransitionTags> {
  static const List<int> kinds = [kNostrKindReservationTransition];
  static final EventTagsParser<ReservationTransitionTags> _tagParser =
      ReservationTransitionTags.new;
  static final EventContentParser<ReservationTransitionContent> _contentParser =
      ReservationTransitionContent.fromJson;

  ReservationTransition({
    required super.pubKey,
    required super.tags,
    required super.content,
    super.createdAt,
    super.id,
    super.sig,
  }) : super(
          kind: kNostrKindReservationTransition,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );

  ReservationTransition.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );
}

/// The type of stage transition.
enum ReservationTransitionType {
  /// A negotiate-stage update (counter-offer with new terms).
  counterOffer,

  /// Seller acknowledges / approves the negotiate terms.
  sellerAck,

  /// Buyer or seller commits the reservation (negotiate → commit).
  commit,

  /// Buyer or seller cancels (negotiate → cancel, or commit → cancel).
  cancel,
}

class ReservationTransitionContent extends EventContent {
  /// What kind of stage transition this event records.
  final ReservationTransitionType transitionType;

  /// The stage the reservation was in *before* this transition.
  final ReservationStage fromStage;

  /// The stage the reservation is in *after* this transition.
  final ReservationStage toStage;

  /// The commit-terms hash that both parties agree on at the time of
  /// transition. For [commit] and [sellerAck] this MUST match the
  /// reservation's `commitTermsHash`.
  final String? commitTermsHash;

  /// Human-readable reason or note (optional). Useful for cancellations.
  final String? reason;

  /// Snapshot of updated fields when the transition carries new terms
  /// (e.g. a counter-offer changes `start`, `end`, `quantity`, or `amount`).
  final Map<String, dynamic>? updatedFields;

  ReservationTransitionContent({
    required this.transitionType,
    required this.fromStage,
    required this.toStage,
    this.commitTermsHash,
    this.reason,
    this.updatedFields,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'transitionType': transitionType.name,
      'fromStage': fromStage.name,
      'toStage': toStage.name,
      if (commitTermsHash != null) 'commitTermsHash': commitTermsHash,
      if (reason != null) 'reason': reason,
      if (updatedFields != null) 'updatedFields': updatedFields,
    };
  }

  static ReservationTransitionContent fromJson(Map<String, dynamic> json) {
    return ReservationTransitionContent(
      transitionType: ReservationTransitionType.values
          .firstWhere((e) => e.name == json['transitionType']),
      fromStage: ReservationStage.values
          .firstWhere((e) => e.name == json['fromStage']),
      toStage:
          ReservationStage.values.firstWhere((e) => e.name == json['toStage']),
      commitTermsHash: json['commitTermsHash'] as String?,
      reason: json['reason'] as String?,
      updatedFields: json['updatedFields'] as Map<String, dynamic>?,
    );
  }
}
