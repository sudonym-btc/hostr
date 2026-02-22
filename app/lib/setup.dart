import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hostr/data/sources/h3_engine.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/screens/shared/profile/background_tasks.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'injection.dart';
import 'setup/hydrated_storage.dart';

/// Bootstraps environment-specific services, storage, and mock servers.
///
/// - Ensures Flutter bindings are initialized
/// - Configures HydratedBloc storage (web vs device)
/// - Applies permissive HTTP overrides for non-prod environments
/// - Starts local mock services for `mock`/`test` environments
/// - Connects to relays through the injected `RelayConnector`
Future<void> setup(String env) async {
  await setupBackgroundAndMainCommon(env);
  if (!kIsWeb) {
    setupWorkmanager();
  }
}

Future<void> setupBackgroundAndMainCommon(String env) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureFlutterH3Runtime();
  await persistEnvironment(env);

  HydratedBloc.storage = await buildHydratedStorage();
  // Allow self-signed certificates for development/test.
  if ([Env.mock, Env.dev, Env.test].contains(env) && !kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  configureInjection(env);
  getIt.registerSingleton<Hostr>(Hostr(config: getIt<Config>().hostrConfig));
  await setupNotifications();
  // If we are testing, launch a mock relay server
  if (env == Env.mock || env == Env.test) {
    await getIt<Hostr>().requests.mock();
  }

  // Restore NDK session from stored keys before connecting relays.
  await getIt<Hostr>().auth.init();
  // Connect to bootstrap relays without blocking app startup.
  // This must happen regardless of auth state so the app can read
  // public data (listings, profiles, etc.) before the user logs in.
  unawaited(
    getIt<Hostr>().relays.connect().catchError((e) {
      getIt<Hostr>().logger.w('Initial relay connection failed: $e');
      // Retry once after a short delay — cold start over wireless debug
      // can fail the first attempt if the network stack isn't fully ready.
      return Future.delayed(const Duration(seconds: 3), () {
        return getIt<Hostr>().relays.connect();
      });
    }).catchError((e) {
      getIt<Hostr>().logger.e('Relay connection retry also failed: $e');
    }),
  );
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
  await setupBackgroundAndMainCommon(env);
}

void setupWorkmanager() {
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  // Only register periodic/processing tasks — don't register a one-off task
  // every launch, as that triggers an immediate background execution.
  // Use ExistingWorkPolicy.keep to avoid re-registering on every cold start.
  Workmanager().registerPeriodicTask(
    iOSBackgroundAppRefresh,
    'sync',
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
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
