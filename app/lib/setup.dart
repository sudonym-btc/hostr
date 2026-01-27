import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hostr/data/sources/nostr/mock.blossom.dart';
import 'package:hostr/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/main.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:path_provider/path_provider.dart';

import 'data/sources/nostr/mock.relay.dart';
import 'injection.dart';

/// Bootstraps environment-specific services, storage, and mock servers.
///
/// - Ensures Flutter bindings are initialized
/// - Configures HydratedBloc storage (web vs device)
/// - Applies permissive HTTP overrides for non-prod environments
/// - Starts local mock services for `mock`/`test` environments
/// - Connects to relays through the injected `RelayConnector`
Future<void> setup(String env) async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );
  // Allow self-signed certificates for development/test.
  if ([Env.mock, Env.dev, Env.test].contains(env)) {
    HttpOverrides.global = MyHttpOverrides();
  }

  configureInjection(env);

  // If we are testing, launch a mock relay server
  if (env == Env.mock || env == Env.test) {
    await setupMockRelay();
  }

  // Restore NDK session from stored keys before connecting relays.
  await getIt<AuthService>().ensureNdkLoggedIn();
  await getIt<RelayConnector>().connect();
}

Future<void> setupMockRelay() async {
  MockBlossomServer blossomServer = MockBlossomServer();
  await blossomServer.start();
  MockRelay mockRelay = MockRelay(
    name: "Mock Relay",
    explicitPort: 5432,
    events: [
      ...await MOCK_EVENTS(),

      /// Preferred relay lists
      Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.guest.privateKey!,
        event: Nip65(
          pubKey: MockKeys.guest.publicKey,
          relays: {getIt<Config>().hostrRelay: ReadWriteMarker.readWrite},
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
        ).toEvent(),
      ),
      Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.hoster.privateKey!,
        event: Nip65(
          pubKey: MockKeys.hoster.publicKey,
          relays: {getIt<Config>().hostrRelay: ReadWriteMarker.readWrite},
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
        ).toEvent(),
      ),
      Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.escrow.privateKey!,
        event: Nip65(
          pubKey: MockKeys.escrow.publicKey,
          relays: {getIt<Config>().hostrRelay: ReadWriteMarker.readWrite},
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
        ).toEvent(),
      ),
    ],
  );
  await mockRelay.startServer();
}
