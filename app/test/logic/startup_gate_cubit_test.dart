import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/logic/cubit/startup_gate.cubit.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  group('StartupGateCubit', () {
    late _FakeStartupCoordinator startup;
    late StartupGateCubit cubit;

    setUp(() {
      startup = _FakeStartupCoordinator();
      cubit = StartupGateCubit(startup: startup);
    });

    tearDown(() async {
      await cubit.close();
      await startup.dispose();
    });

    test('maps in-progress snapshots to StartupGateInProgress', () async {
      final states = <StartupGateState>[];
      final sub = cubit.stream.listen(states.add);

      startup.emit(
        const StartupSnapshot(
          scope: StartupScope.user,
          items: [
            StartupItemProgress(
              id: StartupItemId.profile,
              label: 'Loading profile',
              state: StartupItemState.running,
            ),
          ],
        ),
      );
      await pumpEventQueue();

      expect(
        states.last,
        const StartupGateInProgress(
          items: [
            StartupItemProgress(
              id: StartupItemId.profile,
              label: 'Loading profile',
              state: StartupItemState.running,
            ),
          ],
        ),
      );

      await sub.cancel();
    });

    test('maps user readiness with missing metadata', () async {
      final states = <StartupGateState>[];
      final sub = cubit.stream.listen(states.add);

      startup.emit(
        const StartupSnapshot(
          scope: StartupScope.user,
          items: [],
          result: UserStartupReady(
            pubkey: 'pubkey',
            hasMetadata: false,
            inboxLive: true,
          ),
        ),
      );
      await pumpEventQueue();

      expect(states.last, const StartupGateReady(hasMetadata: false));

      await sub.cancel();
    });

    test('maps public readiness to hasMetadata true', () async {
      final states = <StartupGateState>[];
      final sub = cubit.stream.listen(states.add);

      startup.emit(
        const StartupSnapshot(
          scope: StartupScope.public,
          items: [],
          result: PublicStartupReady(),
        ),
      );
      await pumpEventQueue();

      expect(states.last, const StartupGateReady(hasMetadata: true));

      await sub.cancel();
    });

    test('maps failures to StartupGateError', () async {
      final states = <StartupGateState>[];
      final sub = cubit.stream.listen(states.add);

      startup.emit(
        const StartupSnapshot(
          scope: StartupScope.user,
          items: [],
          error: 'boom',
        ),
      );
      await pumpEventQueue();

      expect(states.last, const StartupGateError('boom'));

      await sub.cancel();
    });

    test('retry delegates to startup coordinator', () async {
      await cubit.retry();

      expect(startup.retryCalls, 1);
    });
  });
}

class _FakeStartupCoordinator extends Fake implements StartupCoordinator {
  final BehaviorSubject<StartupSnapshot> _snapshots = BehaviorSubject();
  int retryCalls = 0;

  void emit(StartupSnapshot snapshot) {
    _snapshots.add(snapshot);
  }

  @override
  ValueStream<StartupSnapshot> get snapshots => _snapshots;

  @override
  Future<void> retryActive() async {
    retryCalls += 1;
  }

  @override
  Future<void> dispose() => _snapshots.close();
}
