import 'package:get_it/get_it.dart';
import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/datasources/storage.dart';
import 'package:hostr_sdk/injection.config.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

final getIt = GetIt.instance;

late HostrConfig _hostrConfig;

@injectableInit
void configureInjection(String environment, {required HostrConfig config}) {
  _hostrConfig = config;
  getIt.init(environment: environment);
}

@module
abstract class HostrSdkModule {
  @singleton
  HostrConfig get hostrConfig => _hostrConfig;

  @singleton
  KeyValueStorage get keyValueStorage => _hostrConfig.keyValueStorage;

  @singleton
  CustomLogger get logger => _hostrConfig.logger;

  @singleton
  Ndk ndk(HostrConfig config) {
    _hostrConfig.logger.d(
      "Configuring NDK with bootstrap relays: ${config.bootstrapRelays}",
    );
    return Ndk(config.ndkConfig);
  }
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
