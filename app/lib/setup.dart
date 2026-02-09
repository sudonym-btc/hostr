import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/screens/shared/profile/background_tasks.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'injection.dart';

/// Bootstraps environment-specific services, storage, and mock servers.
///
/// - Ensures Flutter bindings are initialized
/// - Configures HydratedBloc storage (web vs device)
/// - Applies permissive HTTP overrides for non-prod environments
/// - Starts local mock services for `mock`/`test` environments
/// - Connects to relays through the injected `RelayConnector`
Future<void> setup(String env) async {
  WidgetsFlutterBinding.ensureInitialized();
  await persistEnvironment(env);

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );
  // Allow self-signed certificates for development/test.
  if ([Env.mock, Env.dev, Env.test].contains(env)) {
    HttpOverrides.global = MyHttpOverrides();
  }

  configureInjection(env);
  getIt.registerSingleton<Hostr>(Hostr(config: getIt<Config>().hostrConfig));

  setupWorkmanager();
  await setupNotifications();
  // If we are testing, launch a mock relay server
  if (env == Env.mock || env == Env.test) {
    await getIt<Hostr>().requests.mock();
  }

  // Restore NDK session from stored keys before connecting relays.
  await getIt<Hostr>().auth.init();
  await getIt<Hostr>().relays.connect();
}

const String _environmentPrefsKey = 'hostr.env';

Future<void> persistEnvironment(String env) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_environmentPrefsKey, env);
}

Future<String> readPersistedEnvironment() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_environmentPrefsKey) ?? Env.prod;
}

Future<void> setupBackground(String env) async {
  WidgetsFlutterBinding.ensureInitialized();

  if ([Env.mock, Env.dev, Env.test].contains(env)) {
    HttpOverrides.global = MyHttpOverrides();
  }

  if (!getIt.isRegistered<Config>()) {
    configureInjection(env);
  }
  if (!getIt.isRegistered<Hostr>()) {
    getIt.registerSingleton<Hostr>(Hostr(config: getIt<Config>().hostrConfig));
  }

  await getIt<Hostr>().auth.init();
  await getIt<Hostr>().relays.connect();
}

void setupWorkmanager() {
  Workmanager().initialize(callbackDispatcher);
  Workmanager().registerOneOffTask(iOSBackgroundAppRefresh, "simpleTask");
  Workmanager().registerPeriodicTask(iOSBackgroundAppRefresh, 'sync');
  Workmanager().registerProcessingTask(iOSBackgroundProcessingTask, 'sync');
}

Future<void> setupNotifications() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  final LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Open notification');
  final WindowsInitializationSettings initializationSettingsWindows =
      WindowsInitializationSettings(
        appName: 'Flutter Local Notifications Example',
        appUserModelId: 'Com.Dexterous.FlutterLocalNotificationsExample',
        // Search online for GUID generators to make your own
        guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
      );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    linux: initializationSettingsLinux,
    windows: initializationSettingsWindows,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: notificationTapBackground,
  );
}
