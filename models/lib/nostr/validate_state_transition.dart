import 'order.dart';
import 'order_transition.dart';

/// Result of validating a sequence of [OrderTransition] events.
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

/// A transition chain ordered by `prev` pointers plus its validation result.
class TransitionChainResolution {
  final List<OrderTransition> transitions;
  final TransitionValidationResult validation;

  const TransitionChainResolution({
    required this.transitions,
    required this.validation,
  });
}

/// Legal state transitions encoded as a set of `(from, to)` pairs.
///
/// The order lifecycle state machine is:
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
const _allowedTransitions = <(OrderStage, OrderStage)>{
  (OrderStage.negotiate, OrderStage.negotiate),
  (OrderStage.negotiate, OrderStage.commit),
  (OrderStage.negotiate, OrderStage.cancel),
  (OrderStage.commit, OrderStage.cancel),
  // Escrow confirm: re-stamps a committed order after payment validation.
  (OrderStage.commit, OrderStage.commit),
};

/// Maps [OrderTransitionType] to its expected `(from, to)` stage pair(s).
const _typeToStages = <OrderTransitionType, Set<(OrderStage, OrderStage)>>{
  OrderTransitionType.counterOffer: {
    (OrderStage.negotiate, OrderStage.negotiate),
  },
  OrderTransitionType.commit: {
    (OrderStage.negotiate, OrderStage.commit),
  },
  OrderTransitionType.cancel: {
    (OrderStage.negotiate, OrderStage.cancel),
    (OrderStage.commit, OrderStage.cancel),
  },
  OrderTransitionType.confirm: {
    (OrderStage.commit, OrderStage.commit),
  },
};

/// Order [transitions] by their `prev` tags, then validate the resulting chain
/// for a **single participant** (buyer or seller) and return a
/// [TransitionChainResolution].
///
/// The chain rules are:
/// 1. Exactly one genesis transition may omit `prev`.
/// 2. Every later transition must point to a known previous transition.
/// 3. A transition may have at most one child; competing children are a fork.
///
/// Once ordered, the function checks:
/// 1. Each transition's `(fromStage, toStage)` is a legal state-machine edge.
/// 2. Each transition's `transitionType` matches its declared stages.
/// 3. Consecutive transitions chain correctly: the previous transition's
///    `toStage` equals the next transition's `fromStage`.
///
/// The caller is responsible for filtering transitions by pubkey before calling
/// this function. Event `created_at` is deliberately not used for ordering.
TransitionChainResolution resolveStateTransitionChain(
  List<OrderTransition> transitions,
) {
  if (transitions.isEmpty) {
    return const TransitionChainResolution(
      transitions: [],
      validation: TransitionValidationResult.valid(),
    );
  }

  final originalIndex = <OrderTransition, int>{};
  final byId = <String, OrderTransition>{};
  final genesis = <OrderTransition>[];
  final childrenByPrev = <String, List<OrderTransition>>{};

  for (var i = 0; i < transitions.length; i++) {
    final t = transitions[i];
    originalIndex[t] = i;

    final id = t.id;
    if (id.isEmpty) {
      return TransitionChainResolution(
        transitions: transitions,
        validation: TransitionValidationResult.invalid(
          reason: 'Transition missing event id (index $i)',
          failedIndex: i,
        ),
      );
    }

    if (byId.containsKey(id)) {
      return TransitionChainResolution(
        transitions: transitions,
        validation: TransitionValidationResult.invalid(
          reason: 'Duplicate transition id $id (index $i)',
          failedIndex: i,
        ),
      );
    }

    byId[id] = t;
  }

  for (var i = 0; i < transitions.length; i++) {
    final t = transitions[i];
    final prev = t.parsedTags.prevTransitionId;
    if (prev == null || prev.isEmpty) {
      genesis.add(t);
      continue;
    }

    final parent = byId[prev];
    if (parent == null) {
      return TransitionChainResolution(
        transitions: transitions,
        validation: TransitionValidationResult.invalid(
          reason: 'Missing previous transition $prev (index $i)',
          failedIndex: i,
        ),
      );
    }

    childrenByPrev.putIfAbsent(prev, () => []).add(t);
  }

  if (genesis.isEmpty) {
    return TransitionChainResolution(
      transitions: transitions,
      validation: const TransitionValidationResult.invalid(
        reason: 'No genesis transition: first transition must omit prev',
        failedIndex: 0,
      ),
    );
  }

  if (genesis.length > 1) {
    final secondGenesisIndex = originalIndex[genesis[1]] ?? 1;
    return TransitionChainResolution(
      transitions: transitions,
      validation: TransitionValidationResult.invalid(
        reason:
            'Multiple genesis transitions; later transitions must include prev',
        failedIndex: secondGenesisIndex,
      ),
    );
  }

  for (final entry in childrenByPrev.entries) {
    if (entry.value.length > 1) {
      final forkIndex = originalIndex[entry.value[1]] ?? 0;
      return TransitionChainResolution(
        transitions: transitions,
        validation: TransitionValidationResult.invalid(
          reason: 'Transition fork: multiple children reference ${entry.key}',
          failedIndex: forkIndex,
        ),
      );
    }
  }

  final ordered = <OrderTransition>[];
  final visited = <String>{};
  var current = genesis.first;

  while (true) {
    final id = current.id;
    if (!visited.add(id)) {
      final cycleIndex = originalIndex[current] ?? 0;
      return TransitionChainResolution(
        transitions: ordered,
        validation: TransitionValidationResult.invalid(
          reason: 'Transition cycle at $id',
          failedIndex: cycleIndex,
        ),
      );
    }

    ordered.add(current);
    final children = childrenByPrev[id] ?? const <OrderTransition>[];
    if (children.isEmpty) break;
    current = children.single;
  }

  if (ordered.length != transitions.length) {
    final disconnected = transitions.firstWhere((t) => !visited.contains(t.id));
    final disconnectedIndex = originalIndex[disconnected] ?? 0;
    return TransitionChainResolution(
      transitions: ordered,
      validation: TransitionValidationResult.invalid(
        reason: 'Disconnected transition chain (index $disconnectedIndex)',
        failedIndex: disconnectedIndex,
      ),
    );
  }

  final validation = _validateOrderedTransitions(ordered);
  return TransitionChainResolution(
    transitions: ordered,
    validation: validation,
  );
}

/// Validate a single participant's [OrderTransition] events after
/// ordering them by `prev` tags.
TransitionValidationResult validateStateTransitions(
  List<OrderTransition> transitions,
) {
  return resolveStateTransitionChain(transitions).validation;
}

/// Validate a single escrow participant's transition chain.
///
/// Escrow may reject before committing (`negotiate -> cancel`), and may confirm
/// funds while staying in commit (`commit -> commit`). But once escrow has
/// published a committed state, it must not later republish the trade as
/// cancelled on the relay. Financial resolution must move to payment events
/// (release / claim / arbitration), not back to mutable order state.
TransitionValidationResult validateEscrowStateTransitions(
  List<OrderTransition> transitions,
) {
  final resolution = resolveStateTransitionChain(transitions);
  if (!resolution.validation.isValid) {
    return resolution.validation;
  }

  for (var i = 0; i < resolution.transitions.length; i++) {
    final t = resolution.transitions[i];
    if (t.fromStage == OrderStage.commit && t.toStage == OrderStage.cancel) {
      return TransitionValidationResult.invalid(
        reason: 'Escrow cannot cancel after commit (index $i)',
        failedIndex: i,
      );
    }
  }

  return const TransitionValidationResult.valid();
}

TransitionValidationResult _validateOrderedTransitions(
  List<OrderTransition> transitions,
) {
  if (transitions.isEmpty) {
    return const TransitionValidationResult.valid();
  }

  OrderStage? currentStage;

  for (var i = 0; i < transitions.length; i++) {
    final t = transitions[i];
    final from = t.fromStage;
    final to = t.toStage;

    // 1. Legal state-machine edge?
    if (!_allowedTransitions.contains((from, to))) {
      return TransitionValidationResult.invalid(
        reason: 'Illegal transition ${from.name} → ${to.name} '
            '(index $i)',
        failedIndex: i,
      );
    }

    // 2. Transition type matches declared stages?
    final allowed = _typeToStages[t.transitionType];
    if (allowed != null && !allowed.contains((from, to))) {
      return TransitionValidationResult.invalid(
        reason: 'Transition type ${t.transitionType.name} '
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
