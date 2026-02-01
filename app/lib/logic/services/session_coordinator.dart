import 'dart:async';

import 'package:hostr/data/sources/nostr/nostr/usecase/auth/auth.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/metadata/metadata.dart';
import 'package:hostr/export.dart';
import 'package:injectable/injectable.dart';
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
  final Config config;
  final Auth auth;
  final MetadataUseCase metadataUseCase;
  final CustomLogger _logger = CustomLogger();

  StreamSubscription<AuthState>? _sub;

  SessionCoordinator({
    required this.config,
    required this.auth,
    required this.metadataUseCase,
  });

  void start({
    required AuthCubit authCubit,
    required Ndk ndk,
    required Threads threads,
  }) {
    auth.init();

    _sub?.cancel();

    _sub = authCubit.stream.listen((state) async {
      if (state is LoggedIn) {
        threads.sync();

        // // Update an existing profile with any missing info (e.g. evm address)
        // await metadataUseCase.upsertMetadata();

        // // Ensure initial user relay list is set
        // await ndk.userRelayLists.broadcastAddNip65Relay(
        //   relayUrl: config.hostrRelay,
        //   marker: ReadWriteMarker.readWrite,
        //   broadcastRelays: [...config.relays],
        // );
      } else {
        _logger.i('User logged out');
        threads.stop();
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
