import 'package:models/nostr/main.dart';
import 'package:models/util/validation_result.dart';

/// Summarises the status of a reservation trade by examining the seller's
/// and buyer's latest reservation snapshots.
///
/// Usage:
/// ```dart
/// final status = ReservationPairStatus(
///   sellerReservation: sellerRes,
///   buyerReservation: buyerRes,
/// );
/// if (status.cancelled) { /* one side cancelled */ }
/// ```
class ReservationPair {
  final Reservation? sellerReservation;
  final Reservation? buyerReservation;
  final Validation<ReservationPair>? sellerReservationValidation;
  final Validation<ReservationPair>? buyerReservationValidation;

  ReservationPair({
    this.sellerReservation,
    this.buyerReservation,
    this.sellerReservationValidation,
    this.buyerReservationValidation,
  });

  factory ReservationPair.fromReservation(Reservation r) {
    if (r.isSeller) {
      return ReservationPair(sellerReservation: r);
    } else {
      return ReservationPair(buyerReservation: r);
    }
  }

  ReservationPair addReservation(Reservation r) {
    if (r.isSeller) {
      return ReservationPair(
        sellerReservation: r,
        buyerReservation: buyerReservation,
      );
    }
    return ReservationPair(
      sellerReservation: sellerReservation,
      buyerReservation: r,
    );
  }

  // ── Derived properties ──────────────────────────────────────────────

  String get tradeId {
    return (buyerReservation?.getDtag() ?? sellerReservation?.getDtag())!;
  }

  String get listingAnchor {
    return (buyerReservation?.parsedTags.listingAnchor ??
        sellerReservation?.parsedTags.listingAnchor)!;
  }

  String get hostPubkey => getPubKeyFromAnchor(listingAnchor);

  /// The start date from whichever reservation is available.
  /// Prefers the committed reservation; falls back to the seller's, then
  /// the buyer's negotiate snapshot.
  DateTime? get start {
    final committed = _committedReservation;
    if (committed != null) return committed.start;
    return (sellerReservation ?? buyerReservation)?.start;
  }

  /// The end date from whichever reservation is available.
  /// Same precedence as [start].
  DateTime? get end {
    final committed = _committedReservation;
    if (committed != null) return committed.end;
    return (sellerReservation ?? buyerReservation)?.end;
  }

  /// `true` when **either** party has cancelled.
  bool get cancelled {
    return _isCancelled(sellerReservation) || _isCancelled(buyerReservation);
  }

  /// `true` when **the seller** explicitly cancelled.
  bool get sellerCancelled => _isCancelled(sellerReservation);

  /// `true` when **the buyer** explicitly cancelled.
  bool get buyerCancelled => _isCancelled(buyerReservation);

  /// `true` when at least one committed reservation exists and neither
  /// party has cancelled.
  bool get isActive =>
      !cancelled &&
      (sellerReservation != null || buyerReservation != null) &&
      _committedReservation != null;

  /// `true` when seller has published the counterpart reservation and not cancelled.
  bool get isConfirmed => (sellerReservation?.stage == ReservationStage.commit);

  /// `true` when the reservation's end date has passed and neither party
  /// cancelled. Returns `false` if no end date can be determined.
  bool get isCompleted {
    final e = end;
    if (e == null) return false;
    return !cancelled && e.isBefore(DateTime.now().toUtc());
  }

  /// The current [ReservationStage] of the trade overall.
  ///
  /// If either side cancelled → [ReservationStage.cancel].
  /// If a committed reservation exists → [ReservationStage.commit].
  /// Otherwise → [ReservationStage.negotiate].
  ReservationStage get stage {
    if (cancelled) return ReservationStage.cancel;
    if (_committedReservation != null) return ReservationStage.commit;
    return ReservationStage.negotiate;
  }

  // ── Internals ───────────────────────────────────────────────────────

  /// Returns the first committed (non-cancelled) reservation, preferring
  /// the seller's over the buyer's.
  Reservation? get _committedReservation {
    if (_isCommitted(sellerReservation)) return sellerReservation;
    if (_isCommitted(buyerReservation)) return buyerReservation;
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
