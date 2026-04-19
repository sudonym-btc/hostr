@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/startup/main.dart';
import 'package:test/test.dart';

void main() {
  group('StartupTracker', () {
    test('emits the full item list as parallel tasks advance', () async {
      final snapshots = <StartupSnapshot>[];
      final token = StartupRunToken();
      final tracker = StartupTracker(
        scope: StartupScope.user,
        context: StartupLaunchContext(token: token, emit: snapshots.add),
        items: const [
          StartupItemProgress(
            id: StartupItemId.relays,
            label: 'Connecting to relays',
          ),
          StartupItemProgress(
            id: StartupItemId.profile,
            label: 'Loading profile',
          ),
        ],
      );

      final relays = Completer<void>();
      final profile = Completer<String>();

      final relaysFuture = tracker.run(
        StartupItemId.relays,
        () => relays.future,
      );
      final profileFuture = tracker.run(
        StartupItemId.profile,
        () => profile.future,
      );

      await pumpEventQueue();

      expect(snapshots.last.items, hasLength(2));
      expect(
        _states(snapshots.last),
        equals({
          StartupItemId.relays: StartupItemState.running,
          StartupItemId.profile: StartupItemState.running,
        }),
      );

      relays.complete();
      await relaysFuture;

      expect(
        _states(snapshots.last),
        equals({
          StartupItemId.relays: StartupItemState.complete,
          StartupItemId.profile: StartupItemState.running,
        }),
      );

      profile.complete('metadata');
      await profileFuture;

      tracker.ready(
        const UserStartupReady(
          pubkey: 'pubkey',
          hasMetadata: true,
          inboxLive: true,
        ),
      );

      expect(snapshots.last.isReady, isTrue);
      expect(snapshots.last.result, isA<UserStartupReady>());
      expect(snapshots.last.items, hasLength(2));
    });

    test(
      'marks optional task as degraded without failing the profile',
      () async {
        final snapshots = <StartupSnapshot>[];
        final tracker = StartupTracker(
          scope: StartupScope.user,
          context: StartupLaunchContext(
            token: StartupRunToken(),
            emit: snapshots.add,
          ),
          items: const [
            StartupItemProgress(
              id: StartupItemId.inbox,
              label: 'Opening inbox',
            ),
          ],
        );

        final result = await tracker.runOptional<bool>(
          StartupItemId.inbox,
          () => Future<bool>.error(StateError('not live')),
        );

        expect(result, isNull);
        expect(snapshots.last.items.single.state, StartupItemState.degraded);
        expect(snapshots.last.hasFailed, isFalse);
      },
    );
  });
}

Map<StartupItemId, StartupItemState> _states(StartupSnapshot snapshot) {
  return {for (final item in snapshot.items) item.id: item.state};
}
