import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:hostr/injection.config.dart';

final getIt = GetIt.instance;

@injectableInit
void configureInjection(String environment) {
  getIt.init(environment: environment);
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
