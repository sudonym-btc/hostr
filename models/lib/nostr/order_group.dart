import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:models/nostr/main.dart';
import 'package:models/nostr_kinds.dart' show kListingRefTag;

/// Groups all order events for a single trade (same `d` tag).
///
/// Stores a flat [orders] list. Role-based accessors
/// ([sellerOrder], [buyerOrder], [escrowOrder])
/// are computed getters that classify each entry by its publisher:
///
/// - **seller / host**: `pubKey == getPubKeyFromAnchor(listingAnchor)`
/// - **escrow**: `pubKey == escrowPubkey` (resolved from any order's
///   `escrowProof.escrowService.escrowPubkey`) and `pubKey != hostPubkey`
/// - **buyer / guest**: everyone else
///
/// Because the getters are derived, adding a order that reveals the
/// escrow pubkey automatically reclassifies earlier events.
class OrderGroup {
  final List<Order> orders;
  final bool confirmedCommitted;

  const OrderGroup({
    this.orders = const [],
    this.confirmedCommitted = false,
  });

  factory OrderGroup.fromOrder(Order r) {
    return OrderGroup(orders: [r]);
  }

  OrderGroup copyWith({
    List<Order>? orders,
    bool? confirmedCommitted,
  }) {
    return OrderGroup(
      orders: orders ?? this.orders,
      confirmedCommitted: confirmedCommitted ?? this.confirmedCommitted,
    );
  }

  /// Returns a new group with [r] added (replacing any existing order
  /// from the same pubkey).
  ///
  /// If the group already has orders, silently drops [r] when its
  /// publisher is not in the established [participantSet]. This prevents a
  /// third party who knows the trade id from injecting events into a
  /// legitimate trade's group.
  OrderGroup addOrder(Order r) {
    if (orders.isNotEmpty && !participantSet.contains(r.pubKey)) {
      return this;
    }
    final updated = orders.where((e) => e.pubKey != r.pubKey).toList()..add(r);
    return OrderGroup(
      orders: updated,
      confirmedCommitted: confirmedCommitted,
    );
  }

  // ── Security: participant set & group identity ──────────────────────

  /// The union of all pubkeys declared across every order in the group:
  /// each event's own [pubKey] plus any `p`-tagged counterparty pubkeys.
  Set<String> get participantSet {
    final result = <String>{};
    for (final r in orders) {
      result.add(r.pubKey);
      result.addAll(r.parsedTags.getTags('p'));
    }
    return result;
  }

  static List<String> normalizeParticipants(Iterable<String> participants) =>
      (participants.where((p) => p.isNotEmpty).toSet().toList()..sort());

  static String groupIdForParticipants({
    required String tradeId,
    required Iterable<String> participants,
  }) {
    final preimage = jsonEncode([
      normalizeParticipants(participants),
      tradeId.trim(),
    ]);
    return sha256.convert(utf8.encode(preimage)).toString();
  }

  /// Computes a stable group key from a **single** [Order] event.
  ///
  /// Because every participant declares the full set of counterparties in
  /// their `p` tags, the computed set `{r.pubKey} ∪ r.pTags` is identical
  /// for all legitimate events in the same trade. Events from outsiders
  /// who don't know (or don't match) the full set produce a different key
  /// and are automatically isolated into their own group.
  ///
  /// Formula: SHA-256 of the JSON tuple
  /// `[sorted(unique(participantSet)), dTag]`, matching thread identifiers.
  static String groupIdFromEvent(Order r) {
    final dTag = r.getDtag() ?? r.id;
    final participants = {r.pubKey, ...r.parsedTags.getTags('p')};
    return groupIdForParticipants(tradeId: dTag, participants: participants);
  }

  /// The group's stable composite identity: `groupIdFromEvent` applied to
  /// the accumulated [participantSet] and [tradeId].
  String get groupId =>
      groupIdForParticipants(tradeId: tradeId, participants: participantSet);

  // ── Role-based getters ──────────────────────────────────────────────

  /// The order published by the listing owner (host / seller).
  Order? get sellerOrder {
    if (orders.isEmpty) return null;
    final host = sellerPubkey;
    return orders.where((r) => r.pubKey == host).lastOrNull;
  }

  /// The order published by the guest (buyer).
  ///
  /// Defined as the order whose publisher is neither the host nor
  /// the resolved escrow pubkey.
  Order? get buyerOrder {
    if (orders.isEmpty) return null;
    final host = sellerPubkey;
    final ep = escrowPubkey;
    return orders
        .where((r) => r.pubKey != host && (ep == null || r.pubKey != ep))
        .lastOrNull;
  }

  /// The order published by the escrow service, if any.
  ///
  /// Only resolvable when one of the orders carries an
  /// [EscrowProof] whose `escrowService.escrowPubkey` is known and
  /// differs from the host pubkey.
  Order? get escrowOrder {
    final ep = escrowPubkey;
    if (ep == null) return null;
    final host = sellerPubkey;
    if (ep == host) return null;
    return orders.where((r) => r.pubKey == ep).lastOrNull;
  }

  // ── Derived properties ──────────────────────────────────────────────

  String get tradeId {
    return orders.map((r) => r.getDtag()).whereType<String>().first;
  }

  String get listingAnchor {
    for (final r in orders) {
      final anchors = r.parsedTags.getTags(kListingRefTag);
      if (anchors.isNotEmpty) return anchors.first;
    }
    throw StateError('No order in group carries a listing anchor');
  }

  String get sellerPubkey => getPubKeyFromAnchor(listingAnchor);

  /// The buyer (guest) pubkey, resolved from the buyer's order.
  String? get buyerPubkey => buyerOrder?.pubKey;

  /// The escrow service pubkey, resolved from the first order that
  /// carries an [EscrowProof], falling back to the first `p` tag with
  /// an `"escrow"` role marker (`["p", pk, "", "escrow"]`).
  String? get escrowPubkey {
    // 1. Resolve from EscrowProof (most authoritative).
    for (final r in orders) {
      final pk = r.proof?.escrowProof?.escrowService.escrowPubkey;
      if (pk != null) return pk;
    }
    // 2. Fallback: scan p tags for the role marker.
    for (final r in orders) {
      final pk = r.parsedTags.getTagValueByMarker('p', 'escrow');
      if (pk != null) return pk;
    }
    return null;
  }

  /// The start date from the committed order when present, falling back
  /// to the first order in the group that carries a start date.
  DateTime? get start {
    final committedStart = _committedOrder?.start;
    if (committedStart != null) return committedStart;

    for (final r in orders) {
      final start = r.start;
      if (start != null) return start;
    }
    return null;
  }

  /// The end date — same precedence as [start].
  DateTime? get end {
    final committedEnd = _committedOrder?.end;
    if (committedEnd != null) return committedEnd;

    for (final r in orders) {
      final end = r.end;
      if (end != null) return end;
    }
    return null;
  }

  /// `true` when **any** order has cancelled.
  bool get cancelled => orders.any(_isCancelled);

  /// `true` when **the seller** explicitly cancelled.
  bool get sellerCancelled => _isCancelled(sellerOrder);

  /// `true` when **the buyer** explicitly cancelled.
  bool get buyerCancelled => _isCancelled(buyerOrder);

  /// `true` when at least one committed order exists and no party
  /// has cancelled.
  bool get isActive =>
      !cancelled && orders.isNotEmpty && _committedOrder != null;

  /// `true` when seller has published a commit and not cancelled.
  bool get isConfirmed => sellerOrder?.stage == OrderStage.commit;

  /// `true` when either seller or escrow has published a commit snapshot for
  /// the current group state, or the group was marked committed by validation.
  bool get hasCommitConfirmation =>
      sellerOrder?.stage == OrderStage.commit ||
      escrowOrder?.stage == OrderStage.commit;

  /// `true` when the order's end date has passed and nobody cancelled.
  bool get isCompleted {
    final e = end;
    if (e == null) return false;
    return !cancelled && e.isBefore(DateTime.now().toUtc());
  }

  /// The current [OrderStage] of the trade overall.
  OrderStage get stage {
    if (cancelled) return OrderStage.cancel;
    if (_committedOrder != null) return OrderStage.commit;
    return OrderStage.negotiate;
  }

  // ── Internals ───────────────────────────────────────────────────────

  Order? get _committedOrder {
    for (final r in orders) {
      if (_isCommitted(r)) return r;
    }
    return null;
  }

  static bool _isCancelled(Order? r) {
    if (r == null) return false;
    return r.stage == OrderStage.cancel;
  }

  static bool _isCommitted(Order? r) {
    if (r == null) return false;
    return r.stage == OrderStage.commit && !_isCancelled(r);
  }
}
