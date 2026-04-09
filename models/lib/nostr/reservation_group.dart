import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:models/nostr/main.dart';
import 'package:models/nostr_kinds.dart' show kListingRefTag;

/// Groups all reservation events for a single trade (same `d` tag).
///
/// Stores a flat [reservations] list. Role-based accessors
/// ([sellerReservation], [buyerReservation], [escrowReservation])
/// are computed getters that classify each entry by its publisher:
///
/// - **seller / host**: `pubKey == getPubKeyFromAnchor(listingAnchor)`
/// - **escrow**: `pubKey == escrowPubkey` (resolved from any reservation's
///   `escrowProof.escrowService.escrowPubkey`) and `pubKey != hostPubkey`
/// - **buyer / guest**: everyone else
///
/// Because the getters are derived, adding a reservation that reveals the
/// escrow pubkey automatically reclassifies earlier events.
class ReservationGroup {
  final List<Reservation> reservations;

  const ReservationGroup({this.reservations = const []});

  factory ReservationGroup.fromReservation(Reservation r) {
    return ReservationGroup(reservations: [r]);
  }

  /// Returns a new group with [r] added (replacing any existing reservation
  /// from the same pubkey).
  ///
  /// If the group already has reservations, silently drops [r] when its
  /// publisher is not in the established [participantSet]. This prevents a
  /// third party who knows the trade id from injecting events into a
  /// legitimate trade's group.
  ReservationGroup addReservation(Reservation r) {
    if (reservations.isNotEmpty && !participantSet.contains(r.pubKey)) {
      return this;
    }
    final updated = reservations.where((e) => e.pubKey != r.pubKey).toList()
      ..add(r);
    return ReservationGroup(reservations: updated);
  }

  // ── Security: participant set & group identity ──────────────────────

  /// The union of all pubkeys declared across every reservation in the group:
  /// each event's own [pubKey] plus any `p`-tagged counterparty pubkeys.
  Set<String> get participantSet {
    final result = <String>{};
    for (final r in reservations) {
      result.add(r.pubKey);
      result.addAll(r.parsedTags.getTags('p'));
    }
    return result;
  }

  /// Computes a stable group key from a **single** [Reservation] event.
  ///
  /// Because every participant declares the full set of counterparties in
  /// their `p` tags, the computed set `{r.pubKey} ∪ r.pTags` is identical
  /// for all legitimate events in the same trade. Events from outsiders
  /// who don't know (or don't match) the full set produce a different key
  /// and are automatically isolated into their own group.
  ///
  /// Formula: SHA-256 of `sorted(participantSet).join(':') + ':' + dTag`.
  static String groupIdFromEvent(Reservation r) {
    final dTag = r.getDtag() ?? r.id;
    final participants = {r.pubKey, ...r.parsedTags.getTags('p')};
    final sorted = participants.toList()..sort();
    final input = '${sorted.join(':')}:$dTag';
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// The group's stable composite identity: `groupIdFromEvent` applied to
  /// the accumulated [participantSet] and [tradeId].
  String get groupId {
    final sorted = participantSet.toList()..sort();
    final input = '${sorted.join(':')}:$tradeId';
    return sha256.convert(utf8.encode(input)).toString();
  }

  // ── Role-based getters ──────────────────────────────────────────────

  /// The reservation published by the listing owner (host / seller).
  Reservation? get sellerReservation {
    if (reservations.isEmpty) return null;
    final host = hostPubkey;
    return reservations.where((r) => r.pubKey == host).lastOrNull;
  }

  /// The reservation published by the guest (buyer).
  ///
  /// Defined as the reservation whose publisher is neither the host nor
  /// the resolved escrow pubkey.
  Reservation? get buyerReservation {
    if (reservations.isEmpty) return null;
    final host = hostPubkey;
    final ep = escrowPubkey;
    return reservations
        .where((r) => r.pubKey != host && (ep == null || r.pubKey != ep))
        .lastOrNull;
  }

  /// The reservation published by the escrow service, if any.
  ///
  /// Only resolvable when one of the reservations carries an
  /// [EscrowProof] whose `escrowService.escrowPubkey` is known and
  /// differs from the host pubkey.
  Reservation? get escrowReservation {
    final ep = escrowPubkey;
    if (ep == null) return null;
    final host = hostPubkey;
    if (ep == host) return null;
    return reservations.where((r) => r.pubKey == ep).lastOrNull;
  }

  // ── Derived properties ──────────────────────────────────────────────

  String get tradeId {
    return reservations.map((r) => r.getDtag()).whereType<String>().first;
  }

  String get listingAnchor {
    for (final r in reservations) {
      final anchors = r.parsedTags.getTags(kListingRefTag);
      if (anchors.isNotEmpty) return anchors.first;
    }
    throw StateError('No reservation in group carries a listing anchor');
  }

  String get hostPubkey => getPubKeyFromAnchor(listingAnchor);

  /// The buyer (guest) pubkey, resolved from the buyer's reservation.
  String? get buyerPubkey => buyerReservation?.pubKey;

  /// The escrow service pubkey, resolved from the first reservation that
  /// carries an [EscrowProof].
  String? get escrowPubkey {
    for (final r in reservations) {
      final pk = r.proof?.escrowProof?.escrowService.escrowPubkey;
      if (pk != null) return pk;
    }
    return null;
  }

  /// The start date from the committed reservation, falling back to the
  /// first available reservation.
  DateTime? get start {
    final committed = _committedReservation;
    if (committed != null) return committed.start;
    return (sellerReservation ?? buyerReservation)?.start;
  }

  /// The end date — same precedence as [start].
  DateTime? get end {
    final committed = _committedReservation;
    if (committed != null) return committed.end;
    return (sellerReservation ?? buyerReservation)?.end;
  }

  /// `true` when **any** reservation has cancelled.
  bool get cancelled => reservations.any(_isCancelled);

  /// `true` when **the seller** explicitly cancelled.
  bool get sellerCancelled => _isCancelled(sellerReservation);

  /// `true` when **the buyer** explicitly cancelled.
  bool get buyerCancelled => _isCancelled(buyerReservation);

  /// `true` when at least one committed reservation exists and no party
  /// has cancelled.
  bool get isActive =>
      !cancelled && reservations.isNotEmpty && _committedReservation != null;

  /// `true` when seller has published a commit and not cancelled.
  bool get isConfirmed => sellerReservation?.stage == ReservationStage.commit;

  /// `true` when the reservation's end date has passed and nobody cancelled.
  bool get isCompleted {
    final e = end;
    if (e == null) return false;
    return !cancelled && e.isBefore(DateTime.now().toUtc());
  }

  /// The current [ReservationStage] of the trade overall.
  ReservationStage get stage {
    if (cancelled) return ReservationStage.cancel;
    if (_committedReservation != null) return ReservationStage.commit;
    return ReservationStage.negotiate;
  }

  // ── Internals ───────────────────────────────────────────────────────

  Reservation? get _committedReservation {
    for (final r in reservations) {
      if (_isCommitted(r)) return r;
    }
    return null;
  }

  static bool _isCancelled(Reservation? r) {
    if (r == null) return false;
    return r.stage == ReservationStage.cancel;
  }

  static bool _isCommitted(Reservation? r) {
    if (r == null) return false;
    return r.stage == ReservationStage.commit && !_isCancelled(r);
  }
}
