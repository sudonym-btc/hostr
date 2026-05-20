import 'dart:async';

import 'package:injectable/injectable.dart' hide Order;
import 'package:rxdart/rxdart.dart';

import '../auth/auth.dart';
import 'startup_models.dart';
import 'startup_profiles.dart';

@Singleton()
class StartupCoordinator {
  final Auth _auth;
  final PublicStartupProfile _publicProfile;
  final UserStartupProfile _userProfile;
  final BackgroundStartupProfile _backgroundProfile;

  final BehaviorSubject<StartupSnapshot> _snapshots =
      BehaviorSubject<StartupSnapshot>();
  final Map<StartupScope, StartupSnapshot> _latestSnapshots = {};

  StreamSubscription<AuthState>? _authSub;
  StartupScope _targetScope = StartupScope.public;
  Future<StartupResult>? _publicRun;
  Future<StartupResult>? _userRun;
  Future<StartupResult>? _backgroundRun;
  StartupRunToken? _publicToken;
  StartupRunToken? _userToken;
  StartupRunToken? _backgroundToken;
  String? _runningUserPubkey;
  bool _started = false;
  Future<void> _authTransitionQueue = Future<void>.value();

  StartupCoordinator({
    required Auth auth,
    required PublicStartupProfile publicProfile,
    required UserStartupProfile userProfile,
    required BackgroundStartupProfile backgroundProfile,
  }) : _auth = auth,
       _publicProfile = publicProfile,
       _userProfile = userProfile,
       _backgroundProfile = backgroundProfile;

  ValueStream<StartupSnapshot> get snapshots => _snapshots;

  bool get isStarted => _started;

  void start() {
    if (_started) return;
    _started = true;

    final initialAuth = _auth.authState.value;
    _setTarget(
      initialAuth is LoggedIn && !_auth.needsBunkerRecovery
          ? StartupScope.user
          : StartupScope.public,
    );
    _startPublic();

    _authSub = _auth.authState.skip(1).listen(_enqueueAuthState);
    _enqueueAuthState(initialAuth);
  }

  Future<StartupResult> awaitPublicReady() {
    start();
    return _publicRun ?? _startPublic();
  }

  Future<StartupResult> awaitUserReady() {
    start();
    final pubkey = _activePubkey;
    if (pubkey == null) {
      throw StateError('Cannot await user startup without an active user');
    }
    return _userRun ?? _startUser(pubkey);
  }

  Future<StartupResult> ensureAuthenticatedUserReady() => awaitUserReady();

  Future<StartupResult> launchBackground({bool restart = false}) {
    if (!restart && _backgroundRun != null) return _backgroundRun!;

    _backgroundToken?.cancel();
    final token = StartupRunToken();
    _backgroundToken = token;
    _backgroundRun = _launchProfile(_backgroundProfile, token);
    unawaited(
      _backgroundRun!.then<void>(
        (_) {
          if (_backgroundToken == token) {
            _backgroundRun = null;
            _backgroundToken = null;
          }
        },
        onError: (_) {
          if (_backgroundToken == token) {
            _backgroundRun = null;
            _backgroundToken = null;
          }
        },
      ),
    );
    return _backgroundRun!;
  }

  Future<void> retryActive() async {
    start();

    if (_targetScope == StartupScope.user) {
      _userToken?.cancel();
      _userRun = null;
      _runningUserPubkey = null;
      await _userProfile.stop();

      final pubkey = _activePubkey;
      if (pubkey == null) {
        _setTarget(StartupScope.public);
        _startPublic(restart: true);
        return;
      }

      _startUser(pubkey);
      return;
    }

    _publicToken?.cancel();
    _publicRun = null;
    await _publicProfile.stop();
    _startPublic(restart: true);
  }

  Future<void> _handleAuthState(AuthState state) async {
    if (state is! LoggedIn) {
      _runningUserPubkey = null;
      _userToken?.cancel();
      _userRun = null;
      _setTarget(StartupScope.public);
      await _userProfile.stop();
      return;
    }

    if (_auth.needsBunkerRecovery) {
      _runningUserPubkey = null;
      _userToken?.cancel();
      _userRun = null;
      _setTarget(StartupScope.public);
      await _userProfile.stop();
      return;
    }

    final pubkey = _activePubkey;
    if (pubkey == null) {
      _setTarget(StartupScope.public);
      return;
    }

    _setTarget(StartupScope.user);
    if (_runningUserPubkey == pubkey && _userRun != null) return;

    final previousPubkey = _runningUserPubkey;
    if (previousPubkey != null && previousPubkey != pubkey) {
      _userToken?.cancel();
      _userRun = null;
      _runningUserPubkey = null;
      await _userProfile.stop();
    }

    _runningUserPubkey = pubkey;
    _startUser(pubkey);
  }

  void _enqueueAuthState(AuthState state) {
    _authTransitionQueue = _authTransitionQueue
        .catchError((_) {})
        .then((_) => _handleAuthState(state))
        .catchError((Object error) {
          _handleProfileFailure(_targetScope, error);
        });
    unawaited(_authTransitionQueue);
  }

  Future<StartupResult> _startPublic({bool restart = false}) {
    if (!restart && _publicRun != null) return _publicRun!;

    _publicToken?.cancel();
    final token = StartupRunToken();
    _publicToken = token;
    _publicRun = _launchProfile(_publicProfile, token);
    unawaited(_publicRun!.then<void>((_) {}, onError: (_) {}));
    return _publicRun!;
  }

  Future<StartupResult> _startUser(String pubkey) {
    _userToken?.cancel();
    final token = StartupRunToken();
    _userToken = token;
    _runningUserPubkey = pubkey;
    _userRun = _launchProfile(_userProfile, token);
    unawaited(_userRun!.then<void>((_) {}, onError: (_) {}));
    return _userRun!;
  }

  Future<StartupResult> _launchProfile(
    StartupProfile profile,
    StartupRunToken token,
  ) async {
    try {
      return await profile.launch(
        StartupLaunchContext(
          token: token,
          emit: (snapshot) {
            if (!token.isCancelled) {
              _handleSnapshot(snapshot);
            }
          },
        ),
      );
    } catch (e) {
      if (e is! StartupCancelledException) {
        _handleProfileFailure(profile.scope, e);
      }
      rethrow;
    }
  }

  void _handleSnapshot(StartupSnapshot snapshot) {
    _latestSnapshots[snapshot.scope] = snapshot;
    if (snapshot.scope == _targetScope && !_snapshots.isClosed) {
      _snapshots.add(snapshot);
    }
  }

  void _handleProfileFailure(StartupScope scope, Object error) {
    final latest = _latestSnapshots[scope];
    if (latest?.hasFailed ?? false) return;

    _handleSnapshot(
      StartupSnapshot(
        scope: scope,
        items: latest?.items ?? const [],
        error: error,
      ),
    );
  }

  void _setTarget(StartupScope scope) {
    _targetScope = scope;
    final latest = _latestSnapshots[scope];
    if (latest != null &&
        _snapshotMatchesCurrentTarget(latest) &&
        !_snapshots.isClosed) {
      _snapshots.add(latest);
    }
  }

  bool _snapshotMatchesCurrentTarget(StartupSnapshot snapshot) {
    if (snapshot.scope != _targetScope) return false;
    if (snapshot.scope != StartupScope.user) return true;

    final activePubkey = _activePubkey;
    if (activePubkey == null) return false;

    final result = snapshot.result;
    return result is UserStartupReady && result.pubkey == activePubkey;
  }

  Future<void> dispose() async {
    _publicToken?.cancel();
    _userToken?.cancel();
    _backgroundToken?.cancel();
    await _authSub?.cancel();
    await _publicProfile.stop();
    await _userProfile.stop();
    await _backgroundProfile.stop();
    await _snapshots.close();
  }

  String? get _activePubkey => _auth.activePubkey;
}
