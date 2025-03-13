import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/injection.config.dart';
import 'package:injectable/injectable.dart';
// import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';

final getIt = GetIt.instance;

@injectableInit
void configureInjection(String environment) {
  print('Setting up injection for $environment');

  getIt.init(environment: environment);

  Dio dio = Dio();
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    print('Dio creating http cleint');
    HttpClient client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      print('badCertificateCallback called for: $host:$port');
      return true;
    };
    return client;
  };

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
