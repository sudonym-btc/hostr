import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';
import 'package:sqlite3/common.dart';

import 'config.dart';
import 'datasources/storage.dart';
import 'injection.config.dart';
import 'usecase/calendar/calendar.dart';
import 'util/custom_logger.dart';
import 'util/telemetry.dart';

/// SDK-private dependency container, isolated from the host app's GetIt.
final getIt = GetIt.asNewInstance();

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
  CommonDatabase get operationsDb => _hostrConfig.operationsDb;

  @singleton
  CustomLogger get logger => _hostrConfig.logger;

  @singleton
  Telemetry get telemetry => _hostrConfig.telemetry;

  @singleton
  CalendarPort get calendarPort =>
      _hostrConfig.calendarPort ?? const NoopCalendarPort();

  @lazySingleton
  Ndk ndk(HostrConfig config) {
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
