import 'package:get_it/get_it.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/injection.config.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';
// import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';

final getIt = GetIt.instance;

@injectableInit
void configureInjection(String environment) {
  print('Setting up injection for $environment');
  getIt.init(environment: environment);

  getIt.registerSingleton<Ndk>(Ndk(
    NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
        bootstrapRelays: getIt<Config>().relays),
  ));
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
