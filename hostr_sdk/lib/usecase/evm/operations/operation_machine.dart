// ignore_for_file: unused_element
/// ═══════════════════════════════════════════════════════════════════════
/// OperationMachine — hardened state-machine base class
/// ═══════════════════════════════════════════════════════════════════════
///
/// Shared base for SwapInOperation, SwapOutOperation, OnchainOperation.
///
/// Goals:
///   1. Declarative step graph with explicit allowed-from sets.
///   2. Compare-and-set (CAS) on the persisted state before every
///      side-effect, so two processes never perform the same step.
///   3. `run()` re-reads persisted state on every iteration.
///   4. Stale busy-state recovery with configurable timeouts.
///   5. Background-vs-foreground step gating.
///
/// Cross-isolate safety:
///   The [OperationStateStore] uses SQLite with `BEGIN IMMEDIATE`
///   transactions.  The write lock is held for the entire duration
///   of each CAS operation (SELECT + check + UPDATE), so there is
///   no race window between isolates.
///
/// ═══════════════════════════════════════════════════════════════════════
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../util/custom_logger.dart';
import 'operation_state_store.dart';

// ─────────────────────────────────────────────────────────────────────────
// § 1. State contract
// ─────────────────────────────────────────────────────────────────────────

/// Interface that every operation-state sealed class must implement.
///
/// Existing classes already have [operationId], [isTerminal], [toJson].
/// The only addition is [stateName] — a short, stable string key
/// (e.g. `'funded'`, `'claimed'`) that must match the `'state'` value
/// in [toJson]. Each `final class` variant provides its own constant.
///
/// Migration path for SwapInState:
/// ```dart
/// sealed class SwapInState implements MachineState { … }
///
/// final class SwapInFunded extends SwapInState {
///   @override String get stateName => 'funded';
///   // everything else unchanged
/// }
/// ```
abstract interface class MachineState {
  /// Unique operation ID (e.g. boltzId, tradeId). Null before creation.
  String? get operationId;

  /// True for completed / terminally-failed states.
  bool get isTerminal;

  /// Short string key identifying this state variant.
  /// Must be stable across versions (it's persisted as JSON `'state'`).
  String get stateName;

  /// For failed states: the step that was executing when the failure
  /// occurred. Used by the [OperationMachine] run loop to re-enter the
  /// correct step on recovery without subclass-specific hooks.
  ///
  /// Non-failed states should return `null`. Sealed base classes
  /// (e.g. `SwapInState`) provide the default `null` implementation;
  /// only the `*Failed` variant overrides it.
  String? get failedAtStep;

  /// Serialise for [OperationStateStore].
  Map<String, dynamic> toJson();
}

// ─────────────────────────────────────────────────────────────────────────
// § 2. Step guard — declarative transition metadata
// ─────────────────────────────────────────────────────────────────────────

/// Declarative description of one step in the state machine.
///
/// The [allowedFrom] set is the core CAS precondition:
///   "Only attempt this step if the *persisted* state name is in this set."
///
/// Include the step's own busy-state name in [allowedFrom] to allow a
/// second process (or the same process after a crash) to reclaim it once
/// [staleTimeout] has elapsed.
///
/// Example (swap-in claim relay):
/// ```dart
/// const StepGuard(
///   step: SwapInStep.claimRelay,
///   allowedFrom: {'funded', 'claimRelaying'},   // ← includes busy state
///   staleTimeout: Duration(minutes: 30),
///   backgroundAllowed: true,
/// )
/// ```
class StepGuard<E extends Enum> {
  /// Type-safe step identifier, used for the `executeStep` switch and logging.
  final E step;

  /// Persisted state names from which this step may be claimed.
  final Set<String> allowedFrom;

  /// A stale busy-state from a crashed prior attempt becomes reclaimable
  /// after this duration (checked via `updatedAt` in the persisted JSON).
  /// Set to [Duration.zero] to never reclaim (step owns the state forever).
  final Duration staleTimeout;

  /// If `false`, the background worker will skip this step.
  /// Use for steps that must only run in the foreground (e.g. paying an
  /// invoice that requires user interaction).
  final bool backgroundAllowed;

  const StepGuard({
    required this.step,
    required this.allowedFrom,
    this.staleTimeout = const Duration(minutes: 30),
    this.backgroundAllowed = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────
// § 2b. CAS result
// ─────────────────────────────────────────────────────────────────────────

/// Outcome of a [OperationMachine.claimTransition] attempt.
enum ClaimResult {
  /// CAS succeeded — proceed to execute the step.
  claimed,

  /// The persisted state is NOT in the guard's [allowedFrom] set.
  /// Another process (or an earlier iteration) already moved the state
  /// forward. The [run] loop should **re-read** and try the next step.
  raceForward,

  /// The persisted state IS the busy-state for this step, but it is
  /// NOT yet stale — another process is actively executing.
  /// The [run] loop should **stop** (not spin-wait).
  /// The owning process will complete the step, or the next recovery
  /// attempt will find the state stale and reclaim it.
  busyBackoff,
}

// ─────────────────────────────────────────────────────────────────────────
// § 3. OperationMachine — the base class
// ─────────────────────────────────────────────────────────────────────────

/// Hardened, persistence-aware state-machine loop.
///
/// Subclasses (SwapInOperation, OnchainOperation, …) provide:
///   - [namespace]    — persistence key
///   - [steps]        — the declarative step graph
///   - [stateFromJson] / [busyStateFor] / [executeStep] / [emitError]
///
/// The base class provides:
///   - [emit] override that persists every state
///   - [run] loop that re-reads persisted state on each iteration
///   - [claimTransition] CAS primitive
///   - [recover] entry-point with stale-state reclamation
abstract class OperationMachine<S extends MachineState, E extends Enum>
    extends Cubit<S> {
  @protected
  final OperationStateStore store;
  @protected
  final CustomLogger logger;

  /// Whether this machine is running in a background isolate.
  /// Set via [recover] or the constructor; checked against
  /// [StepGuard.backgroundAllowed].
  bool get isBackground => _isBackground;
  bool _isBackground = false;

  OperationMachine({
    required this.store,
    required CustomLogger logger,
    required S initialState,
  }) : logger = logger,
       super(initialState);

  // ── Telemetry hook ────────────────────────────────────────────────
  //
  // Subclasses override [telemetryAttributes] to add domain-specific
  // attributes (swap ID, chain ID, etc.).  The base class calls
  // [applyTelemetry] at the start of each major span so that every
  // span in the trace carries the standard operation context.
  //
  // Explicit `addEvent` calls are NOT needed — every `logger.i/w/e`
  // already emits an OTel span event via CustomLogger._emitSpanEvent.

  /// Structured attributes for the currently-active span.
  ///
  /// Override in subclasses to add domain-specific attributes.
  /// The base implementation provides core operation metadata.
  @protected
  Map<String, Object?> get telemetryAttributes => {
    'hostr.operation.type': runtimeType.toString(),
    'hostr.operation.namespace': namespace,
    'hostr.operation.background': _isBackground,
    'hostr.operation.state': state.stateName,
    if (state.operationId != null) 'hostr.operation.id': state.operationId,
  };

  /// Annotates the current span with [telemetryAttributes] merged with
  /// any [extra] key-value pairs.
  @protected
  void applyTelemetry([Map<String, Object?> extra = const {}]) {
    CustomLogger.telemetry.setSpanAttributes({
      ...telemetryAttributes,
      ...extra,
    });
  }

  // ── Abstract: subclass must implement ──────────────────────────────

  /// Persistence namespace (e.g. `'swap_in'`, `'escrow_fund'`).
  String get namespace;

  /// The ordered list of steps this machine supports.
  ///
  /// The [run] loop walks this list on each iteration to find the first
  /// step whose [StepGuard.allowedFrom] contains the current persisted
  /// state name.
  ///
  /// **Order matters**: if two guards both match, the first wins.
  /// In practice each state maps to exactly one step, so order rarely
  /// matters — but document the intended precedence here.
  ///
  /// Example (swap-in):
  /// ```dart
  /// @override
  /// List<StepGuard<SwapInStep>> get steps => const [
  ///   StepGuard(
  ///     step: SwapInStep.createSwap,
  ///     allowedFrom: {'initialised'},
  ///     backgroundAllowed: false,
  ///   ),
  ///   StepGuard(
  ///     step: SwapInStep.dispatchPayment,
  ///     allowedFrom: {'requestCreated'},
  ///     staleTimeout: Duration(minutes: 45),
  ///     backgroundAllowed: false,         // only foreground pays
  ///   ),
  ///   StepGuard(
  ///     step: SwapInStep.ensureFunded,
  ///     allowedFrom: {
  ///       'awaitingOnChain', 'paymentProgress',
  ///       'paymentDispatching',            // recovery from crashed fg
  ///     },
  ///     backgroundAllowed: true,           // no lock — anyone can wait
  ///   ),
  ///   StepGuard(
  ///     step: SwapInStep.claimRelay,
  ///     allowedFrom: {'funded', 'claimRelaying'},
  ///     staleTimeout: Duration(minutes: 30),
  ///     backgroundAllowed: true,
  ///   ),
  ///   StepGuard(
  ///     step: SwapInStep.checkMempool,
  ///     allowedFrom: {'claimed'},
  ///     backgroundAllowed: true,
  ///   ),
  ///   StepGuard(
  ///     step: SwapInStep.confirmClaim,
  ///     allowedFrom: {'claimTxInMempool'},
  ///     backgroundAllowed: true,
  ///   ),
  /// ];
  /// ```
  List<StepGuard<E>> get steps;

  /// Reconstruct a state object from persisted JSON.
  S stateFromJson(Map<String, dynamic> json);

  /// Build the "busy" state to persist BEFORE the side-effect begins.
  ///
  /// Return `null` if the step doesn't need a busy guard (e.g. it is
  /// purely idempotent or read-only). In that case the CAS is skipped
  /// and the step executes unconditionally.
  ///
  /// The busy state should carry the same data as [currentState] but
  /// with a different [MachineState.stateName] (e.g. `'claimRelaying'`).
  ///
  /// ```dart
  /// @override
  /// SwapInState? busyStateFor(SwapInStep step, SwapInState current) {
  ///   return switch (step) {
  ///     SwapInStep.claimRelay => SwapInClaimRelaying(current.data!),
  ///     _ => null,  // no busy guard for other steps
  ///   };
  /// }
  /// ```
  S? busyStateFor(E step, S currentState);

  /// Execute the actual work for [step] and return the resulting state.
  ///
  /// Called **only** after the CAS succeeds (or is skipped because
  /// [busyStateFor] returned null).
  ///
  /// Steps must **never** call [emit] directly. Instead:
  ///   - **Return** the final state — the [run] loop persists it.
  ///   - Use [emitProgress] for intermediate UI-only updates
  ///     (e.g. payment progress) that don't need persistence.
  ///
  /// This ensures the base class is the sole writer of durable state,
  /// preventing a slow step from overwriting a newer state written by a
  /// faster concurrent process.
  ///
  /// ```dart
  /// @override
  /// Future<SwapInState> executeStep(SwapInStep step) async {
  ///   return switch (step) {
  ///     SwapInStep.createSwap       => await _stepCreateSwap(),
  ///     SwapInStep.dispatchPayment  => await _stepDispatchPayment(),
  ///     SwapInStep.ensureFunded     => await _stepEnsureFunded(),
  ///     SwapInStep.claimRelay       => await _stepClaim(),
  ///     SwapInStep.checkMempool     => await _stepCheckClaimInMempool(),
  ///     SwapInStep.confirmClaim     => await _stepConfirmClaim(),
  ///   };
  /// }
  /// ```
  Future<S> executeStep(E step);

  /// Construct the error/failed state for this machine.
  ///
  /// Called by the [run] loop when a step throws. The base class can't
  /// construct sealed-class variants (SwapInFailed, OnchainError, etc.)
  /// so the subclass does it.
  ///
  /// [stepName] is the name of the step that failed. Subclasses should
  /// thread this into the failed state's [MachineState.failedAtStep]
  /// field so that recovery can re-enter the correct step.
  void emitError(
    Object error,
    S fromState,
    StackTrace? stackTrace, {
    String? stepName,
  });

  // ── CAS transition ────────────────────────────────────────────────

  /// Claim a step transition via compare-and-set against the store.
  ///
  /// ## How it works
  ///
  /// Delegates to [OperationStateStore.atomicClaim], which runs the
  /// entire check-and-write inside a single `BEGIN IMMEDIATE` SQLite
  /// transaction.  No race window exists — the database write lock is
  /// held from the initial SELECT through the UPDATE.
  ///
  /// 1. Checks `persisted.state ∈ guard.allowedFrom`.
  /// 2. If the persisted state IS the busy state from a prior crash,
  ///    checks `updatedAt + staleTimeout < now` before allowing reclaim.
  /// 3. If all checks pass → writes the busy state atomically.
  ///
  /// Returns [ClaimResult.claimed] if the transition was claimed,
  /// [ClaimResult.raceForward] if the state moved past our step (re-read
  /// and try the next step), or [ClaimResult.busyBackoff] if another
  /// process is actively executing this step (stop the loop).
  ///
  /// When the current state has [MachineState.failedAtStep] set, the
  /// CAS automatically accepts the current (failed) state name in
  /// addition to the guard's [StepGuard.allowedFrom] set.  The busy-
  /// state is still written to disk, so a second process will see it
  /// and back off (or reclaim it after [StepGuard.staleTimeout]).
  @protected
  Future<ClaimResult> claimTransition(StepGuard<E> guard, S currentState) =>
      logger.span('claimTransition', () async {
        applyTelemetry({'hostr.operation.step': guard.step.name});
        final id = currentState.operationId;
        if (id == null) return ClaimResult.claimed; // pre-creation — no risk

        final busyState = busyStateFor(guard.step, currentState);
        if (busyState == null) return ClaimResult.claimed; // no busy guard

        // If the current state has failedAtStep, also accept the current
        // state name (e.g. 'failed') so the CAS writes the busy state
        // and acts as a mutex against other processes.
        final allowed = currentState.failedAtStep != null
            ? {...guard.allowedFrom, currentState.stateName}
            : guard.allowedFrom;

        final result = store.atomicClaim(
          namespace: namespace,
          id: id,
          allowedStates: allowed,
          busyStateName: busyState.stateName,
          busyStateJson: busyState.toJson(),
          staleTimeout: guard.staleTimeout,
        );

        switch (result.outcome) {
          case CasOutcome.claimed:
            // Update the Cubit stream for UI listeners.
            // The store already wrote to SQLite inside the transaction.
            super.emit(busyState);
            return ClaimResult.claimed;

          case CasOutcome.busyBackoff:
            logger.i(
              '${guard.step.name}: busy "${busyState.stateName}" is '
              '${result.busyAge?.inSeconds}s old '
              '(stale after ${guard.staleTimeout.inSeconds}s) — backing off',
            );
            return ClaimResult.busyBackoff;

          case CasOutcome.raceForward:
            if (result.persistedJson != null) {
              _syncFromPersisted(result.persistedJson!);
            }
            logger.i(
              '${guard.step.name}: CAS rejected — '
              'persisted state not in $allowed',
            );
            return ClaimResult.raceForward;
        }
      }, attributes: {'step': guard.step.name});

  // ── Run loop ──────────────────────────────────────────────────────

  /// Core state-machine loop.
  ///
  /// On every iteration:
  ///   1. Re-read persisted state from the store (not `this.state`).
  ///   2. Find the step whose [StepGuard.allowedFrom] matches.
  ///      For non-terminal failed states, uses [MachineState.failedAtStep]
  ///      to re-enter the correct step — no subclass hooks needed.
  ///   3. Claim the transition via CAS.
  ///   4. Execute the step.
  ///
  /// Stops when the state is terminal, no step matches, or the
  /// background gate rejects the step.
  Future<void> run() => logger.span('run', () async {
    applyTelemetry();
    while (true) {
      // ── 1. Re-read from persistence ──
      final current = await _reloadOrCurrent();

      // ── 2. Terminal check ──
      if (current.isTerminal) {
        logger.i('State "${current.stateName}" is terminal — exiting run loop');
        break;
      }

      // ── 3. Find matching step ──
      final guard = _matchStep(current);
      if (guard == null) {
        logger.w('No step matches state "${current.stateName}" — stopping');
        break;
      }

      // ── 4. Background gate ──
      if (_isBackground && !guard.backgroundAllowed) {
        logger.i(
          'Step "${guard.step.name}" not allowed in background — waiting',
        );
        await Future.delayed(const Duration(seconds: 3));
        continue;
      }

      // ── 5. CAS claim ──
      final claim = await claimTransition(guard, current);
      if (claim == ClaimResult.raceForward) {
        // State moved forward — re-read and try the next step.
        logger.i('CAS miss for "${guard.step.name}" — re-reading');
        continue;
      }
      if (claim == ClaimResult.busyBackoff) {
        // Another process owns this step — wait and re-read. It will
        // finish the step, advance the disk state, and we'll pick it
        // up on the next iteration (or reclaim after stale timeout).
        logger.i(
          'Step "${guard.step.name}" owned by another process — waiting',
        );
        await Future.delayed(const Duration(seconds: 3));
        continue;
      }

      // ── 6. Execute ──
      try {
        final next = await executeStep(guard.step);
        final busyState = busyStateFor(guard.step, current);
        final expectedDiskState = busyState?.stateName ?? current.stateName;
        await _emitIfStillOwned(next, expectedDiskState, guard.step);
      } catch (e, st) {
        logger.e('Step "${guard.step.name}" failed: $e');
        emitError(e, current, st, stepName: guard.step.name);
        break;
      }
    }
  });

  // ── Entry points ──────────────────────────────────────────────────

  /// Start a fresh operation from the initial state.
  Future<void> execute() => logger.span('execute', () async {
    applyTelemetry();
    await run();
  });

  /// Resume from a persisted (non-terminal) state.
  ///
  /// This is functionally identical to [execute] except for the
  /// [isBackground] flag, which gates which steps may execute.
  ///
  /// Non-terminal failed states are handled generically by the [run]
  /// loop using [MachineState.failedAtStep] — no subclass hooks needed.
  ///
  /// Returns `true` if the machine reached a terminal state.
  Future<bool> recover({bool isBackground = false}) =>
      logger.span('recover', () async {
        _isBackground = isBackground;
        applyTelemetry();
        await run();
        return state.isTerminal;
      }, attributes: {'isBackground': isBackground});

  // ── Run-until variant ─────────────────────────────────────────────

  /// Like [run] but stops early when [stopCondition] is satisfied.
  ///
  /// Useful for callers that want partial progress (e.g. escrow-fund
  /// stops at `SwapInClaimed` to avoid blocking on confirmation):
  ///
  /// ```dart
  /// await swap.runUntil((s) => s.stateName == 'claimed');
  /// ```
  Future<void> runUntil(
    bool Function(S) stopCondition,
  ) => logger.span('runUntil', () async {
    applyTelemetry();
    while (true) {
      final current = await _reloadOrCurrent();
      if (current.isTerminal) {
        logger.i(
          'State "${current.stateName}" is terminal — exiting runUntil loop',
        );
        break;
      }
      if (stopCondition(current)) {
        logger.i(
          'Stop condition met at "${current.stateName}" — exiting runUntil loop',
        );
        break;
      }

      final guard = _matchStep(current);
      if (guard == null) break;
      if (_isBackground && !guard.backgroundAllowed) break;
      final claim = await claimTransition(guard, current);
      if (claim == ClaimResult.raceForward) continue;
      if (claim == ClaimResult.busyBackoff) {
        await Future.delayed(const Duration(seconds: 3));
        continue;
      }

      try {
        final next = await executeStep(guard.step);
        final busyState = busyStateFor(guard.step, current);
        final expectedDiskState = busyState?.stateName ?? current.stateName;
        await _emitIfStillOwned(next, expectedDiskState, guard.step);
      } catch (e, st) {
        logger.e('Step "${guard.step.name}" failed: $e');
        emitError(e, current, st, stepName: guard.step.name);
        break;
      }
    }
  });

  // ── Internals ─────────────────────────────────────────────────────

  /// Write [next] to the store only if the persisted state still matches
  /// what we set before executing the step.
  ///
  /// Uses [OperationStateStore.writeIfOwned] which runs atomically inside
  /// a SQLite `BEGIN IMMEDIATE` transaction — no race window.
  ///
  /// [expectedDiskState] is the busy-state name written by
  /// [claimTransition], or [current.stateName] for unguarded steps.
  ///
  /// Returns `true` if the write was performed, `false` if skipped.
  Future<bool> _emitIfStillOwned(
    S next,
    String expectedDiskState,
    E step,
  ) async {
    final id = next.operationId;
    if (id == null) {
      // Pre-creation — no risk of regression.
      emit(next);
      return true;
    }

    final result = store.writeIfOwned(
      namespace: namespace,
      id: id,
      expectedState: expectedDiskState,
      json: next.toJson(),
    );

    if (result.written) {
      logger.i(
        '${step.name}: committed "$expectedDiskState" → "${next.stateName}"',
      );
      emit(next);
      return true;
    }

    logger.w(
      '${step.name}: disk is "${result.persistedJson?['state']}", expected '
      '"$expectedDiskState" — another process advanced the state, '
      'skipping write',
    );
    if (result.persistedJson != null) _syncFromPersisted(result.persistedJson!);
    return false;
  }

  /// Re-read persisted state directly from disk.
  ///
  /// Falls back to [state] (the Cubit state) if nothing is stored yet
  /// (pre-creation).
  Future<S> _reloadOrCurrent() async {
    final id = state.operationId;
    if (id == null) return state;

    final json = await store.read(namespace, id);
    if (json == null) return state;

    final fresh = stateFromJson(json);
    // Sync the Cubit stream if the persisted state diverged (another
    // process moved it forward). Use virtual emit so subclass
    // notification hooks fire (e.g. _fireNotification).
    if (fresh.stateName != state.stateName) {
      logger.i(
        'Persisted state diverged: '
        '"${state.stateName}" → "${fresh.stateName}" '
        '(another process advanced it)',
      );
      emit(fresh);
    }
    return fresh;
  }

  /// Find the first step whose [allowedFrom] contains [current.stateName].
  ///
  /// For non-terminal failed states with [MachineState.failedAtStep] set,
  /// falls back to matching by the failed step name. This allows the run
  /// loop to re-enter the correct step without any subclass-specific hooks.
  StepGuard<E>? _matchStep(S current) {
    final name = current.stateName;
    for (final step in steps) {
      if (step.allowedFrom.contains(name)) {
        return step;
      }
    }

    // ── Fallback: match via failedAtStep ───────────────────────────
    final failedStep = current.failedAtStep;
    if (failedStep != null && !current.isTerminal) {
      for (final step in steps) {
        if (step.step.name == failedStep) {
          logger.i(
            'Matched step "$failedStep" via failedAtStep '
            'from state "$name"',
          );
          return step;
        }
      }
    }

    return null;
  }

  /// Sync the Cubit state from a persisted JSON map (without re-persisting).
  void _syncFromPersisted(Map<String, dynamic> json) {
    try {
      final fresh = stateFromJson(json);
      emit(fresh);
    } catch (_) {
      // Best-effort — don't crash on deserialization failure.
    }
  }
}
