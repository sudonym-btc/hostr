import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hostr/data/sources/nostr/mock.blossom.dart';
import 'package:hostr/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/main.dart';
import 'package:ndk/entities.dart';
import 'package:path_provider/path_provider.dart';

import 'data/sources/nostr/mock.relay.dart';
import 'injection.dart';

setup(String env) async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );
  // Allow self signed certificates for development
  if ([Env.mock, Env.dev, Env.test].contains(env)) {
    HttpOverrides.global = MyHttpOverrides();
  }

  configureInjection(env);

  // If we are testing, launch a mock relay server
  if (env == Env.mock || env == Env.test) {
    MockBlossomServer blossomServer = MockBlossomServer();
    await blossomServer.start();
    MockRelay mockRelay = MockRelay(name: "Mock Relay", explicitPort: 5044);
    await mockRelay.startServer(events: [
      ...MOCK_EVENTS,
      Nip65(
              pubKey: MockKeys.guest.publicKey,
              relays: {getIt<Config>().hostrRelay: ReadWriteMarker.readWrite},
              createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000)
          .toEvent()
        ..sign(MockKeys.guest.privateKey!),
      Nip65(
              pubKey: MockKeys.hoster.publicKey,
              relays: {getIt<Config>().hostrRelay: ReadWriteMarker.readWrite},
              createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000)
          .toEvent()
        ..sign(MockKeys.hoster.privateKey!),
      Nip65(
              pubKey: MockKeys.escrow.publicKey,
              relays: {getIt<Config>().hostrRelay: ReadWriteMarker.readWrite},
              createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000)
          .toEvent()
        ..sign(MockKeys.escrow.privateKey!)
    ]);
  }
  await getIt<RelayConnector>().connect();
}
