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

final logger = CustomLogger();

/// Bootstraps environment-specific services, storage, and mock servers.
///
/// - Ensures Flutter bindings are initialized
/// - Configures HydratedBloc storage (web vs device)
/// - Applies permissive HTTP overrides for non-prod environments
/// - Starts local mock services for `mock`/`test` environments
/// - Connects to relays through the injected `RelayConnector`
Future<void> setup(String env) async {
  logger.d('${DateTime.now()} Setting up environment: $env');
  await setupBackgroundAndMainCommon(env);
  logger.d('${DateTime.now()} Workmanager setup complete');
  if (!kIsWeb) {
    setupWorkmanager();
  }
}

Future<void> setupBackgroundAndMainCommon(String env) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureFlutterH3Runtime();
  logger.d(
    '${DateTime.now()} Flutter bindings initialized and H3 runtime configured',
  );
  await persistEnvironment(env);
  logger.d('${DateTime.now()} Environment persisted: $env');

  HydratedBloc.storage = await buildHydratedStorage();
  logger.d('${DateTime.now()}  Hydrated storage initialized');
  // Allow self-signed certificates for development/test.
  if ([Env.mock, Env.dev, Env.test].contains(env) && !kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  configureInjection(env);
  getIt.registerSingleton<Hostr>(Hostr(config: getIt<Config>().hostrConfig));
  logger.d('${DateTime.now()} Dependency injection configured');

  // Skip notification permission prompt in test — it blocks CI and
  // screenshot automation with a system dialog that can't be pre-granted.
  if (env != Env.test) {
    await setupNotifications();
    logger.d('${DateTime.now()} Notifications setup complete');
  }

  // Restore NDK session from stored keys before connecting relays.
  await getIt<Hostr>().auth.init();
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
