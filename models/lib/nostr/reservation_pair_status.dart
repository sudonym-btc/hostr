import 'reservation.dart';

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
class ReservationPairStatus {
  final Reservation? sellerReservation;
  final Reservation? buyerReservation;

  ReservationPairStatus({
    this.sellerReservation,
    this.buyerReservation,
  });

  // ── Derived properties ──────────────────────────────────────────────

  /// The start date from whichever reservation is available.
  /// Prefers the committed reservation; falls back to the seller's, then
  /// the buyer's negotiate snapshot.
  DateTime? get start {
    final committed = _committedReservation;
    if (committed != null) return committed.parsedContent.start;
    return (sellerReservation ?? buyerReservation)?.parsedContent.start;
  }

  /// The end date from whichever reservation is available.
  /// Same precedence as [start].
  DateTime? get end {
    final committed = _committedReservation;
    if (committed != null) return committed.parsedContent.end;
    return (sellerReservation ?? buyerReservation)?.parsedContent.end;
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

  /// `true` when the reservation's end date has passed and neither party
  /// cancelled. Returns `false` if no end date can be determined.
  bool get isCompleted {
    final e = end;
    if (e == null) return false;
    return !cancelled && e.isBefore(DateTime.now());
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
    return r.parsedContent.stage == ReservationStage.cancel ||
        r.parsedContent.cancelled;
  }

  static bool _isCommitted(Reservation? r) {
    if (r == null) return false;
    return r.parsedContent.stage == ReservationStage.commit && !_isCancelled(r);
  }
}
