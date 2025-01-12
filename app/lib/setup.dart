import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'injection.dart';

setup(String env) async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );
  // Allow self signed certificates for development
  if ([Env.mock, Env.dev, Env.test].contains(env)) {
    HttpOverrides.global = MyHttpOverrides();
  }

  configureInjection(env);
  await getIt<RelayConnector>().connect();

  if (env == Env.mock) {
    await seed();
  }
}
