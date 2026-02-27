import 'reservation.dart';
import 'reservation_transition.dart';

/// Result of validating a sequence of [ReservationTransition] events.
class TransitionValidationResult {
  /// Whether the entire sequence is valid.
  final bool isValid;

  /// Human-readable description of the first violation, or `null` if valid.
  final String? reason;

  /// Zero-based index of the first invalid transition, or `null` if valid.
  final int? failedIndex;

  const TransitionValidationResult.valid()
      : isValid = true,
        reason = null,
        failedIndex = null;

  const TransitionValidationResult.invalid({
    required this.reason,
    required this.failedIndex,
  }) : isValid = false;

  @override
  String toString() => isValid
      ? 'TransitionValidationResult(valid)'
      : 'TransitionValidationResult(invalid @ $failedIndex: $reason)';
}

/// Legal state transitions encoded as a set of `(from, to)` pairs.
///
/// The reservation lifecycle state machine is:
///
/// ```
///   negotiate ──→ negotiate   (counter-offer)
///   negotiate ──→ commit      (seller-ack / buyer-commit)
///   negotiate ──→ cancel
///   commit    ──→ cancel
/// ```
///
/// Everything else is forbidden (e.g. cancel → *, commit → negotiate,
/// commit → commit).
const _allowedTransitions = <(ReservationStage, ReservationStage)>{
  (ReservationStage.negotiate, ReservationStage.negotiate),
  (ReservationStage.negotiate, ReservationStage.commit),
  (ReservationStage.negotiate, ReservationStage.cancel),
  (ReservationStage.commit, ReservationStage.cancel),
};

/// Maps [ReservationTransitionType] to its expected `(from, to)` stage pair(s).
const _typeToStages =
    <ReservationTransitionType, Set<(ReservationStage, ReservationStage)>>{
  ReservationTransitionType.counterOffer: {
    (ReservationStage.negotiate, ReservationStage.negotiate),
  },
  ReservationTransitionType.sellerAck: {
    (ReservationStage.negotiate, ReservationStage.commit),
  },
  ReservationTransitionType.commit: {
    (ReservationStage.negotiate, ReservationStage.commit),
  },
  ReservationTransitionType.cancel: {
    (ReservationStage.negotiate, ReservationStage.cancel),
    (ReservationStage.commit, ReservationStage.cancel),
  },
};

/// Validate a chronologically-ordered list of [ReservationTransition] events
/// for a **single participant** (buyer or seller) and return a
/// [TransitionValidationResult].
///
/// The function checks:
/// 1. Each transition's `(fromStage, toStage)` is a legal state-machine edge.
/// 2. Each transition's `transitionType` matches its declared stages.
/// 3. Consecutive transitions chain correctly: the previous transition's
///    `toStage` equals the next transition's `fromStage`.
///
/// The caller is responsible for filtering transitions by pubkey before
/// calling this function. [transitions] must be sorted in chronological order
/// (oldest first).
TransitionValidationResult validateStateTransitions(
  List<ReservationTransition> transitions,
) {
  if (transitions.isEmpty) {
    return const TransitionValidationResult.valid();
  }

  ReservationStage? currentStage;

  for (var i = 0; i < transitions.length; i++) {
    final t = transitions[i];
    final content = t.parsedContent;
    final from = content.fromStage;
    final to = content.toStage;

    // 1. Legal state-machine edge?
    if (!_allowedTransitions.contains((from, to))) {
      return TransitionValidationResult.invalid(
        reason: 'Illegal transition ${from.name} → ${to.name} '
            '(index $i)',
        failedIndex: i,
      );
    }

    // 2. Transition type matches declared stages?
    final allowed = _typeToStages[content.transitionType];
    if (allowed != null && !allowed.contains((from, to))) {
      return TransitionValidationResult.invalid(
        reason: 'Transition type ${content.transitionType.name} '
            'does not match stages ${from.name} → ${to.name} '
            '(index $i)',
        failedIndex: i,
      );
    }

    // 3. Chain continuity: previous `toStage` == this `fromStage`.
    if (currentStage != null && from != currentStage) {
      return TransitionValidationResult.invalid(
        reason: 'Chain break: expected fromStage=${currentStage.name} '
            'but got ${from.name} (index $i)',
        failedIndex: i,
      );
    }

    currentStage = to;
  }

  return const TransitionValidationResult.valid();
}
