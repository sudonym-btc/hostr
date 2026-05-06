import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';
import 'package:sqlite3/common.dart';

import 'config.dart';
import 'datasources/app_database.dart';
import 'datasources/storage.dart';
import 'injection.config.dart';
import 'usecase/calendar/calendar.dart';
import 'util/custom_logger.dart';
import 'util/telemetry.dart';

/// Legacy SDK-private dependency container, isolated from the host app's
/// GetIt.
///
/// New code should prefer the per-[Hostr] scope exposed by HostrRuntime and
/// HostrSession. This remains mutable for older tests and CLI code that reset
/// the SDK container directly.
GetIt getIt = GetIt.asNewInstance();

class HostrScope {
  final GetIt container;

  HostrScope(this.container);

  T call<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return container<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  bool isRegistered<T extends Object>({String? instanceName}) {
    return container.isRegistered<T>(instanceName: instanceName);
  }

  void registerSingleton<T extends Object>(T instance, {String? instanceName}) {
    container.registerSingleton<T>(instance, instanceName: instanceName);
  }
}

late HostrConfig _hostrConfig;
late HostrScope _hostrScope;

@injectableInit
void configureInjection(String environment, {required HostrConfig config}) {
  getIt = createHostrScope(environment: environment, config: config);
}

GetIt createHostrScope({
  required String environment,
  required HostrConfig config,
}) {
  _hostrConfig = config;
  final scope = GetIt.asNewInstance();
  _hostrScope = HostrScope(scope);
  scope.init(environment: environment);
  return scope;
}

@module
abstract class HostrSdkModule {
  @singleton
  HostrConfig get hostrConfig => _hostrConfig;

  @singleton
  HostrScope get hostrScope => _hostrScope;

  @singleton
  KeyValueStorage get keyValueStorage => _hostrConfig.keyValueStorage;

  @singleton
  AppDatabase get appDatabase => _hostrConfig.appDatabase;

  @singleton
  CommonDatabase get operationsDb => _hostrConfig.appDatabase.db;

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
