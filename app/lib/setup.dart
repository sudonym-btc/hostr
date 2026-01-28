import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hostr/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

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
    await getIt<Hostr>().requests.mock();
  }

  // Restore NDK session from stored keys before connecting relays.
  await getIt<Hostr>().auth.ensureNdkLoggedIn();
  await getIt<RelayConnector>().connect();
}
