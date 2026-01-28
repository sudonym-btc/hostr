import 'dart:async';

import 'package:hostr/export.dart';
import 'package:hostr/logic/cubit/messaging/threads.cubit.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

/// Coordinates session-driven side effects when auth state changes.
///
/// Responsibilities on LoggedIn:
/// - Ensure initial user relay list is set for the active pubkey.
/// - Trigger gift-wrap sync for the active pubkey.
///
/// Responsibilities on LoggedOut:
/// - Clear gift-wrap list.
@lazySingleton
class SessionCoordinator {
  final Config _config;
  final KeyStorage _keyStorage;
  final CustomLogger _logger = CustomLogger();

  StreamSubscription<AuthState>? _sub;

  SessionCoordinator(this._config, this._keyStorage);

  void start({
    required AuthCubit authCubit,
    required Ndk ndk,
    required ThreadsCubit threadsCubit,
  }) {
    _sub?.cancel();
    _sub = authCubit.stream.listen((state) async {
      if (state is LoggedIn) {
        final pubKey = ndk.accounts.getPublicKey()!;
        threadsCubit.sync();

        await ndk.userRelayLists.setInitialUserRelayList(
          UserRelayList(
            pubKey: pubKey,
            relays: {_config.hostrRelay: ReadWriteMarker.readWrite},
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            refreshedTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );
      } else {
        _logger.i('User logged out');
        threadsCubit.stop();
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
