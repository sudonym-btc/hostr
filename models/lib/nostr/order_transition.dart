import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class OrderTransitionTags extends EventTags
    with ReferencesListing<OrderTransitionTags> {
  OrderTransitionTags(super.tags);

  /// The canonical d tag (trade identifier) linking this transition to its
  /// order.
  ///
  /// Older events may have used a `t` tag for this lookup, so retain that as a
  /// read-only fallback when parsing historical data.
  String? get tradeId {
    final dTags = getTags('d');
    if (dTags.isNotEmpty) return dTags.first;
    final tTags = getTags('t');
    return tTags.isNotEmpty ? tTags.first : null;
  }

  /// The event id of the order this transition applies to (`e` tag).
  String? get orderEventId {
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

/// Records a stage transition on a order.
///
/// Every time a buyer or seller changes the order's stage (negotiate →
/// commit, negotiate → cancel, commit → cancel, or a counter-offer within
/// negotiate), they MUST broadcast a [OrderTransition] event so that
/// relays and other clients can audit the history.
///
/// Each transition references its parent order via an `e` tag and
/// optionally chains to the previous transition via a `prev` tag, forming
/// a monotonic log.
class OrderTransition
    extends JsonContentNostrEvent<OrderTransitionContent, OrderTransitionTags> {
  static const List<int> kinds = [kNostrKindOrderTransition];
  static final EventTagsParser<OrderTransitionTags> _tagParser =
      OrderTransitionTags.new;
  static final EventContentParser<OrderTransitionContent> _contentParser =
      OrderTransitionContent.fromJson;

  // ── Convenience getters ─────────────────────────────────────────────
  OrderTransitionType get transitionType => parsedContent.transitionType;
  OrderStage get fromStage => parsedContent.fromStage;
  OrderStage get toStage => parsedContent.toStage;
  String? get commitTermsHash => parsedContent.commitTermsHash;
  String? get reason => parsedContent.reason;
  Map<String, dynamic>? get updatedFields => parsedContent.updatedFields;

  OrderTransition({
    required super.pubKey,
    required super.tags,
    required super.content,
    super.createdAt,
    super.id,
    super.sig,
  }) : super(
          kind: kNostrKindOrderTransition,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );

  OrderTransition.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );
}

/// The type of stage transition.
enum OrderTransitionType {
  /// A negotiate-stage update (counter-offer with new terms).
  counterOffer,

  /// Any party commits the order (negotiate → commit).
  commit,

  /// Any party cancels (negotiate → cancel, or commit → cancel).
  cancel,

  /// Escrow confirms payment proof is valid (commit → commit).
  ///
  /// Published by the escrow service after verifying that the buyer's
  /// payment proof matches the on-chain / lightning settlement. This
  /// re-stamps the order in the commit stage, signalling all parties
  /// that funds are secured.
  confirm,
}

class OrderTransitionContent extends EventContent {
  /// What kind of stage transition this event records.
  final OrderTransitionType transitionType;

  /// The stage the order was in *before* this transition.
  final OrderStage fromStage;

  /// The stage the order is in *after* this transition.
  final OrderStage toStage;

  /// The commit-terms hash that both parties agree on at the time of
  /// transition. For [commit] this MUST match the order's
  /// `commitTermsHash`.
  final String? commitTermsHash;

  /// Human-readable reason or note (optional). Useful for cancellations.
  final String? reason;

  /// Snapshot of updated fields when the transition carries new terms
  /// (e.g. a counter-offer changes `start`, `end`, `quantity`, or `amount`).
  final Map<String, dynamic>? updatedFields;

  OrderTransitionContent({
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

  static OrderTransitionContent fromJson(Map<String, dynamic> json) {
    return OrderTransitionContent(
      transitionType: OrderTransitionType.values
          .firstWhere((e) => e.name == json['transitionType']),
      fromStage:
          OrderStage.values.firstWhere((e) => e.name == json['fromStage']),
      toStage: OrderStage.values.firstWhere((e) => e.name == json['toStage']),
      commitTermsHash: json['commitTermsHash'] as String?,
      reason: json['reason'] as String?,
      updatedFields: json['updatedFields'] as Map<String, dynamic>?,
    );
  }
}
