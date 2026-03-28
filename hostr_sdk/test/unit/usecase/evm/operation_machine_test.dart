@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/evm/operations/operation_machine.dart';
import 'package:hostr_sdk/usecase/evm/operations/operation_state_store.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// ── Concrete state + step implementations for testing ──────────────────

enum _Step { alpha, bravo, charlie }

class _State implements MachineState {
  @override
  final String? operationId;
  @override
  final bool isTerminal;
  @override
  final String stateName;
  @override
  final String? failedAtStep;

  const _State({
    this.operationId,
    this.isTerminal = false,
    required this.stateName,
    this.failedAtStep,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': operationId,
    'state': stateName,
    'isTerminal': isTerminal,
    if (failedAtStep != null) 'failedAtStep': failedAtStep,
    'updatedAt': DateTime.now().toIso8601String(),
  };
}

class _FakeStore extends Fake implements OperationStateStore {
  Map<String, dynamic>? _stored;
  CasClaimResult nextClaimResult = CasClaimResult.claimed;
  WriteIfOwnedResult nextWriteResult = WriteIfOwnedResult.success;
  int claimCallCount = 0;
  int writeCallCount = 0;

  @override
  CasClaimResult atomicClaim({
    required String namespace,
    required String id,
    required Set<String> allowedStates,
    required String busyStateName,
    required Map<String, dynamic> busyStateJson,
    required Duration staleTimeout,
  }) {
    claimCallCount++;
    if (nextClaimResult.outcome == CasOutcome.claimed) {
      _stored = busyStateJson;
    }
    return nextClaimResult;
  }

  @override
  WriteIfOwnedResult writeIfOwned({
    required String namespace,
    required String id,
    required String expectedState,
    required Map<String, dynamic> json,
  }) {
    writeCallCount++;
    if (nextWriteResult.written) {
      _stored = json;
    }
    return nextWriteResult;
  }

  @override
  Future<Map<String, dynamic>?> read(String namespace, String id) async =>
      _stored;

  @override
  Future<void> write(
    String namespace,
    String id,
    Map<String, dynamic> json,
  ) async {
    _stored = json;
  }
}

class _TestMachine extends OperationMachine<_State, _Step> {
  final List<StepGuard<_Step>> stepGuards;
  final _State Function(_Step step)? executeStepFn;
  final _State? Function(_Step step, _State current)? busyStateFn;
  bool onRunCompleteCalled = false;

  _TestMachine({
    required super.store,
    required super.logger,
    required super.initialState,
    required this.stepGuards,
    this.executeStepFn,
    this.busyStateFn,
  });

  @override
  String get namespace => 'test';

  @override
  List<StepGuard<_Step>> get steps => stepGuards;

  @override
  _State stateFromJson(Map<String, dynamic> json) => _State(
    operationId: json['id'] as String?,
    stateName: json['state'] as String,
    isTerminal: json['isTerminal'] == true,
    failedAtStep: json['failedAtStep'] as String?,
  );

  @override
  _State? busyStateFor(_Step step, _State currentState) =>
      busyStateFn?.call(step, currentState);

  @override
  Future<_State> executeStep(_Step step) async {
    if (executeStepFn != null) return executeStepFn!(step);
    throw UnimplementedError('executeStep not configured');
  }

  @override
  void emitError(
    Object error,
    _State fromState,
    StackTrace? stackTrace, {
    String? stepName,
  }) {
    emit(
      _State(
        operationId: fromState.operationId,
        stateName: 'failed',
        failedAtStep: stepName,
      ),
    );
  }

  @override
  void onRunComplete(_State state) {
    onRunCompleteCalled = true;
  }
}

void main() {
  late _FakeStore store;
  late CustomLogger logger;

  setUp(() {
    store = _FakeStore();
    logger = CustomLogger();
  });

  group('StepGuard', () {
    test('stores step, allowedFrom, and defaults', () {
      const guard = StepGuard(step: _Step.alpha, allowedFrom: {'init'});
      expect(guard.step, _Step.alpha);
      expect(guard.allowedFrom, {'init'});
      expect(guard.staleTimeout, const Duration(minutes: 30));
      expect(guard.backgroundAllowed, isTrue);
    });

    test('respects custom staleTimeout and backgroundAllowed', () {
      const guard = StepGuard(
        step: _Step.bravo,
        allowedFrom: {'ready'},
        staleTimeout: Duration(seconds: 10),
        backgroundAllowed: false,
      );
      expect(guard.staleTimeout, const Duration(seconds: 10));
      expect(guard.backgroundAllowed, isFalse);
    });
  });

  group('claimTransition', () {
    test('returns claimed for pre-creation state (null operationId)', () async {
      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: null, stateName: 'init'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
      );

      const guard = StepGuard(step: _Step.alpha, allowedFrom: {'init'});
      final result = await machine.claimTransition(
        guard,
        const _State(operationId: null, stateName: 'init'),
      );

      expect(result, ClaimResult.claimed);
      expect(store.claimCallCount, 0); // no CAS for null ID
    });

    test('returns claimed when busyStateFor returns null (no CAS)', () async {
      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: 'op1', stateName: 'init'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
        busyStateFn: (_, _) => null,
      );

      const guard = StepGuard(step: _Step.alpha, allowedFrom: {'init'});
      final result = await machine.claimTransition(
        guard,
        const _State(operationId: 'op1', stateName: 'init'),
      );

      expect(result, ClaimResult.claimed);
      expect(store.claimCallCount, 0);
    });

    test('delegates to store.atomicClaim and returns claimed', () async {
      store.nextClaimResult = CasClaimResult.claimed;

      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: 'op1', stateName: 'init'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
        busyStateFn: (_, current) =>
            _State(operationId: current.operationId, stateName: 'busy_alpha'),
      );

      const guard = StepGuard(step: _Step.alpha, allowedFrom: {'init'});
      final result = await machine.claimTransition(
        guard,
        const _State(operationId: 'op1', stateName: 'init'),
      );

      expect(result, ClaimResult.claimed);
      expect(store.claimCallCount, 1);
      // Cubit state should be updated to the busy state.
      expect(machine.state.stateName, 'busy_alpha');
    });

    test('returns raceForward when store says raceForward', () async {
      store.nextClaimResult = const CasClaimResult.raceForward({
        'state': 'already_done',
        'isTerminal': true,
      });

      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: 'op1', stateName: 'init'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
        busyStateFn: (_, current) =>
            _State(operationId: current.operationId, stateName: 'busy_alpha'),
      );

      const guard = StepGuard(step: _Step.alpha, allowedFrom: {'init'});
      final result = await machine.claimTransition(
        guard,
        const _State(operationId: 'op1', stateName: 'init'),
      );

      expect(result, ClaimResult.raceForward);
    });

    test('returns busyBackoff when store says busyBackoff', () async {
      store.nextClaimResult = const CasClaimResult.busyBackoff(
        age: Duration(seconds: 5),
      );

      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: 'op1', stateName: 'init'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
        busyStateFn: (_, current) =>
            _State(operationId: current.operationId, stateName: 'busy_alpha'),
      );

      const guard = StepGuard(step: _Step.alpha, allowedFrom: {'init'});
      final result = await machine.claimTransition(
        guard,
        const _State(operationId: 'op1', stateName: 'init'),
      );

      expect(result, ClaimResult.busyBackoff);
    });

    test(
      'adds failed stateName to allowedSet when failedAtStep is set',
      () async {
        store.nextClaimResult = CasClaimResult.claimed;

        // Override store to capture the allowedStates argument.
        final capturingStore = _CapturingStore();
        final machine = _TestMachine(
          store: capturingStore,
          logger: logger,
          initialState: const _State(
            operationId: 'op1',
            stateName: 'failed',
            failedAtStep: 'alpha',
          ),
          stepGuards: const [
            StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
          ],
          busyStateFn: (_, current) =>
              _State(operationId: current.operationId, stateName: 'busy_alpha'),
        );

        const guard = StepGuard(step: _Step.alpha, allowedFrom: {'init'});
        await machine.claimTransition(
          guard,
          const _State(
            operationId: 'op1',
            stateName: 'failed',
            failedAtStep: 'alpha',
          ),
        );

        expect(capturingStore.lastAllowedStates, contains('failed'));
        expect(capturingStore.lastAllowedStates, contains('init'));
      },
    );
  });

  group('MachineState contract', () {
    test('basic _State satisfies interface', () {
      const s = _State(operationId: 'x', stateName: 'ready', isTerminal: false);
      expect(s.operationId, 'x');
      expect(s.stateName, 'ready');
      expect(s.isTerminal, false);
      expect(s.failedAtStep, isNull);
      expect(s.toJson(), containsPair('state', 'ready'));
    });

    test('terminal state is recognized', () {
      const s = _State(operationId: 'x', stateName: 'done', isTerminal: true);
      expect(s.isTerminal, true);
    });

    test('failed state carries failedAtStep', () {
      const s = _State(
        operationId: 'x',
        stateName: 'failed',
        failedAtStep: 'bravo',
      );
      expect(s.failedAtStep, 'bravo');
    });
  });

  group('run() loop', () {
    test('exits immediately on terminal state', () async {
      store._stored = const _State(
        operationId: 'op1',
        stateName: 'done',
        isTerminal: true,
      ).toJson();

      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(
          operationId: 'op1',
          stateName: 'done',
          isTerminal: true,
        ),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
      );

      await machine.run();

      expect(machine.onRunCompleteCalled, isTrue);
    });

    test('stops when no step matches', () async {
      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: null, stateName: 'orphan'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
      );

      await machine.run();

      expect(machine.onRunCompleteCalled, isFalse);
      expect(machine.state.stateName, 'orphan');
    });

    test('executes step and advances state', () async {
      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: null, stateName: 'init'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
        busyStateFn: (_, _) => null, // no CAS needed
        executeStepFn: (_) => const _State(
          operationId: 'op1',
          stateName: 'done',
          isTerminal: true,
        ),
      );

      await machine.run();

      expect(machine.state.stateName, 'done');
      expect(machine.state.isTerminal, isTrue);
      expect(machine.onRunCompleteCalled, isTrue);
    });

    test('catches step error and emits failed state', () async {
      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: null, stateName: 'init'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
        busyStateFn: (_, _) => null,
        executeStepFn: (_) => throw Exception('boom'),
      );

      await machine.run();

      expect(machine.state.stateName, 'failed');
      expect(machine.state.failedAtStep, 'alpha');
    });

    test('matches step via failedAtStep fallback', () async {
      // State is 'failed' with failedAtStep='alpha'.
      // The guard for alpha has allowedFrom: {'init'} (not 'failed').
      // The fallback should match via failedAtStep.
      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(
          operationId: null,
          stateName: 'failed',
          failedAtStep: 'alpha',
        ),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
        busyStateFn: (_, _) => null,
        executeStepFn: (_) => const _State(
          operationId: 'op1',
          stateName: 'done',
          isTerminal: true,
        ),
      );

      await machine.run();

      expect(machine.state.stateName, 'done');
      expect(machine.onRunCompleteCalled, isTrue);
    });

    test('multi-step progression through graph', () async {
      var callCount = 0;
      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: null, stateName: 'init'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
          StepGuard(step: _Step.bravo, allowedFrom: {'step1'}),
          StepGuard(step: _Step.charlie, allowedFrom: {'step2'}),
        ],
        busyStateFn: (_, _) => null,
        executeStepFn: (step) {
          callCount++;
          return switch (step) {
            _Step.alpha => const _State(operationId: 'op1', stateName: 'step1'),
            _Step.bravo => const _State(operationId: 'op1', stateName: 'step2'),
            _Step.charlie => const _State(
              operationId: 'op1',
              stateName: 'done',
              isTerminal: true,
            ),
          };
        },
      );

      await machine.run();

      expect(callCount, 3);
      expect(machine.state.stateName, 'done');
      expect(machine.onRunCompleteCalled, isTrue);
    });
  });

  group('recover()', () {
    test('sets isBackground flag', () async {
      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(
          operationId: 'op1',
          stateName: 'done',
          isTerminal: true,
        ),
        stepGuards: const [],
      );

      store._stored = const _State(
        operationId: 'op1',
        stateName: 'done',
        isTerminal: true,
      ).toJson();

      final terminal = await machine.recover(isBackground: true);

      expect(terminal, isTrue);
      expect(machine.isBackground, isTrue);
    });

    test('returns false for non-terminal state', () async {
      final machine = _TestMachine(
        store: store,
        logger: logger,
        initialState: const _State(operationId: null, stateName: 'orphan'),
        stepGuards: const [
          StepGuard(step: _Step.alpha, allowedFrom: {'init'}),
        ],
      );

      final terminal = await machine.recover();

      expect(terminal, isFalse);
    });
  });

  group('ClaimResult', () {
    test('enum values', () {
      expect(ClaimResult.values, hasLength(3));
      expect(ClaimResult.claimed.name, 'claimed');
      expect(ClaimResult.raceForward.name, 'raceForward');
      expect(ClaimResult.busyBackoff.name, 'busyBackoff');
    });
  });
}

// ── Helper: store that captures CAS arguments ──────────────────────────

class _CapturingStore extends Fake implements OperationStateStore {
  Set<String>? lastAllowedStates;

  @override
  CasClaimResult atomicClaim({
    required String namespace,
    required String id,
    required Set<String> allowedStates,
    required String busyStateName,
    required Map<String, dynamic> busyStateJson,
    required Duration staleTimeout,
  }) {
    lastAllowedStates = allowedStates;
    return CasClaimResult.claimed;
  }

  @override
  Future<Map<String, dynamic>?> read(String namespace, String id) async => null;
}
