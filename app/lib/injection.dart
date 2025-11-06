import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/injection.config.dart';
import 'package:injectable/injectable.dart';
// import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';

final getIt = GetIt.instance;

@injectableInit
void configureInjection(String environment) {
  debugPrint('Setting up injection for $environment');

  getIt.init(environment: environment);

  // Configure Dio and allow self-signed certificates only outside production.
  final Dio dio = Dio();
  if (environment != Env.prod) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final HttpClient client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  getIt.registerSingleton<Dio>(dio);
}

abstract class Env {
  static const mock = 'mock';
  static const dev = 'dev';
  static const test = 'test';
  static const staging = 'staging';
  static const prod = 'prod';
  static const allButMock = [Env.dev, Env.test, Env.staging, Env.prod];
  static const allButTest = [Env.dev, Env.mock, Env.staging, Env.prod];
  static const allButTestAndMock = [Env.dev, Env.staging, Env.prod];
}
