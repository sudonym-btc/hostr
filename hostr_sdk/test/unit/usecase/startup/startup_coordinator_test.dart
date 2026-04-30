@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/startup/main.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('StartupCoordinator', () {
    late BehaviorSubject<AuthState> authState;
    late _FakeAuth auth;
    late _ControlledPublicProfile publicProfile;
    late _ControlledUserProfile userProfile;
    late _ControlledBackgroundProfile backgroundProfile;
    late StartupCoordinator coordinator;
    late List<StartupSnapshot> snapshots;

    setUp(() {
      authState = BehaviorSubject<AuthState>.seeded(LoggedOut());
      auth = _FakeAuth(authState);
      publicProfile = _ControlledPublicProfile(
        items: const [
          StartupItemProgress(
            id: StartupItemId.relays,
            label: 'Connecting to relays',
            state: StartupItemState.running,
          ),
        ],
      );
      userProfile = _ControlledUserProfile(
        items: const [
          StartupItemProgress(
            id: StartupItemId.inbox,
            label: 'Opening inbox',
            state: StartupItemState.running,
          ),
        ],
      );
      backgroundProfile = _ControlledBackgroundProfile(
        items: const [
          StartupItemProgress(
            id: StartupItemId.relayHints,
            label: 'Loading relay list',
            state: StartupItemState.running,
          ),
        ],
      );
      coordinator = StartupCoordinator(
        auth: auth,
        publicProfile: publicProfile,
        userProfile: userProfile,
        backgroundProfile: backgroundProfile,
      );
      snapshots = [];
      coordinator.snapshots.listen(snapshots.add);
    });

    tearDown(() async {
      await coordinator.dispose();
      await authState.close();
    });

    test('launches public startup immediately', () async {
      coordinator.start();
      await pumpEventQueue();

      expect(publicProfile.launches, 1);
      expect(userProfile.launches, 0);
      expect(snapshots.last.scope, StartupScope.public);
      expect(snapshots.last.items.single.id, StartupItemId.relays);
    });

    test('switches to user startup when auth logs in', () async {
      coordinator.start();
      await pumpEventQueue();

      auth.pubkey = 'pubkey';
      authState.add(const LoggedIn('pubkey'));
      await pumpEventQueue();

      expect(publicProfile.launches, 1);
      expect(userProfile.launches, 1);
      expect(snapshots.last.scope, StartupScope.user);

      publicProfile.complete(const PublicStartupReady());
      await pumpEventQueue();

      expect(
        snapshots.last.scope,
        StartupScope.user,
        reason:
            'Public completion should not reopen the gate while user '
            'startup is now the target.',
      );
      expect(snapshots.last.result, isNull);

      userProfile.complete(
        const UserStartupReady(
          pubkey: 'pubkey',
          hasMetadata: true,
          inboxLive: true,
        ),
      );
      await pumpEventQueue();

      expect(snapshots.last.scope, StartupScope.user);
      expect(snapshots.last.result, isA<UserStartupReady>());
    });

    test(
      'stops user startup and returns to public snapshots on logout',
      () async {
        await coordinator.dispose();
        await authState.close();

        authState = BehaviorSubject<AuthState>.seeded(const LoggedIn('pubkey'));
        auth = _FakeAuth(authState)..pubkey = 'pubkey';
        coordinator = StartupCoordinator(
          auth: auth,
          publicProfile: publicProfile,
          userProfile: userProfile,
          backgroundProfile: backgroundProfile,
        );
        snapshots = [];
        coordinator.snapshots.listen(snapshots.add);

        coordinator.start();
        await pumpEventQueue();

        expect(userProfile.launches, 1);
        expect(snapshots.last.scope, StartupScope.user);

        auth.pubkey = null;
        authState.add(LoggedOut());
        await pumpEventQueue();

        expect(userProfile.stops, greaterThanOrEqualTo(1));
        expect(snapshots.last.scope, StartupScope.public);
      },
    );

    test(
      'stops previous user services before launching a different logged-in user',
      () async {
        await coordinator.dispose();
        await authState.close();
        final baselineStops = userProfile.stops;

        authState = BehaviorSubject<AuthState>.seeded(
          const LoggedIn('pubkey-a'),
        );
        auth = _FakeAuth(authState)..pubkey = 'pubkey-a';
        userProfile.stopCompleter = Completer<void>();
        coordinator = StartupCoordinator(
          auth: auth,
          publicProfile: publicProfile,
          userProfile: userProfile,
          backgroundProfile: backgroundProfile,
        );
        snapshots = [];
        coordinator.snapshots.listen(snapshots.add);

        coordinator.start();
        await pumpEventQueue();

        expect(userProfile.launches, 1);

        auth.pubkey = 'pubkey-b';
        authState.add(const LoggedIn('pubkey-b'));
        await pumpEventQueue();

        expect(userProfile.stops, baselineStops + 1);
        expect(
          userProfile.launches,
          1,
          reason: 'New user startup must wait for old user cleanup.',
        );

        userProfile.stopCompleter!.complete();
        await pumpEventQueue();

        expect(userProfile.launches, 2);
      },
    );

    test(
      'does not replay a previous user ready snapshot for a new user',
      () async {
        coordinator.start();
        await pumpEventQueue();

        auth.pubkey = 'pubkey-a';
        authState.add(const LoggedIn('pubkey-a'));
        await pumpEventQueue();

        userProfile.complete(
          const UserStartupReady(
            pubkey: 'pubkey-a',
            hasMetadata: true,
            inboxLive: true,
          ),
        );
        await pumpEventQueue();

        expect(snapshots.last.result, isA<UserStartupReady>());

        auth.pubkey = null;
        authState.add(LoggedOut());
        await pumpEventQueue();

        final emittedBeforeSecondLogin = snapshots.length;
        auth.pubkey = 'pubkey-b';
        authState.add(const LoggedIn('pubkey-b'));
        await pumpEventQueue();

        final emittedForSecondLogin = snapshots.skip(emittedBeforeSecondLogin);
        expect(
          emittedForSecondLogin,
          isNot(
            contains(
              predicate<StartupSnapshot>((snapshot) {
                final result = snapshot.result;
                return result is UserStartupReady &&
                    result.pubkey == 'pubkey-a';
              }),
            ),
          ),
          reason:
              'A new login must wait for that user startup result instead of '
              'replaying the previous user readiness snapshot.',
        );
        expect(userProfile.launches, 2);
      },
    );

    test(
      'launches background startup on demand without retargeting gate',
      () async {
        coordinator.start();
        await pumpEventQueue();

        final backgroundRun = coordinator.launchBackground();
        await pumpEventQueue();

        expect(backgroundProfile.launches, 1);
        expect(snapshots.last.scope, StartupScope.public);

        backgroundProfile.complete(const BackgroundStartupReady(pubkey: null));
        await backgroundRun;
        await pumpEventQueue();

        expect(snapshots.last.scope, StartupScope.public);
        expect(backgroundProfile.stops, 0);

        final nextBackgroundRun = coordinator.launchBackground();
        await pumpEventQueue();
        expect(backgroundProfile.launches, 2);

        backgroundProfile.complete(
          const BackgroundStartupReady(pubkey: null),
          run: 1,
        );
        await nextBackgroundRun;
      },
    );
  });
}

class _FakeAuth extends Fake implements Auth {
  final BehaviorSubject<AuthState> _authState;
  String? pubkey;

  _FakeAuth(this._authState);

  @override
  ValueStream<AuthState> get authState => _authState;

  @override
  String? get activePubkey => pubkey;

  @override
  bool get needsBunkerRecovery => false;

  @override
  KeyPair? get activeKeyPair {
    final value = pubkey;
    return value == null ? null : KeyPair('privkey', value, null, null);
  }
}

class _ControlledProfile implements StartupProfile {
  @override
  final StartupScope scope;
  final List<StartupItemProgress> items;
  final List<Completer<StartupResult>> _runs = [];
  Completer<void>? stopCompleter;
  int launches = 0;
  int stops = 0;

  _ControlledProfile({required this.scope, required this.items});

  @override
  Future<StartupResult> launch(StartupLaunchContext context) async {
    launches += 1;
    final completer = Completer<StartupResult>();
    _runs.add(completer);
    context.emit(StartupSnapshot(scope: scope, items: items));

    final result = await completer.future;
    context.token.throwIfCancelled();
    context.emit(
      StartupSnapshot(
        scope: scope,
        items: items
            .map((item) => item.copyWith(state: StartupItemState.complete))
            .toList(growable: false),
        result: result,
      ),
    );
    return result;
  }

  void complete(StartupResult result, {int run = 0}) {
    _runs[run].complete(result);
  }

  @override
  Future<void> stop() async {
    stops += 1;
    await stopCompleter?.future;
    stopCompleter = null;
  }
}

class _ControlledPublicProfile extends _ControlledProfile
    implements PublicStartupProfile {
  _ControlledPublicProfile({required super.items})
    : super(scope: StartupScope.public);
}

class _ControlledUserProfile extends _ControlledProfile
    implements UserStartupProfile {
  _ControlledUserProfile({required super.items})
    : super(scope: StartupScope.user);
}

class _ControlledBackgroundProfile extends _ControlledProfile
    implements BackgroundStartupProfile {
  _ControlledBackgroundProfile({required super.items})
    : super(scope: StartupScope.background);
}
