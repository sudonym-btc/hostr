import 'package:get_it/get_it.dart';
import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/injection.config.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

final getIt = GetIt.instance;

@injectableInit
void configureInjection(String environment, {required HostrConfig config}) {
  getIt.registerSingleton<HostrConfig>(config);
  getIt.registerSingleton<Ndk>(Ndk(config.ndkConfig));
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
