import 'dart:io';

import 'package:hostr/config/http_overrides.dart';
import 'package:hostr/data/mock/seed.dart';

import 'injection.dart';

void setup(String env) {
// Allow self signed certificates for development
  if ([Env.mock, Env.dev, Env.test].contains(env)) {
    HttpOverrides.global = MyHttpOverrides();
  }

  configureInjection(env);
  if (env == Env.mock) {
    seed();
  }
}
