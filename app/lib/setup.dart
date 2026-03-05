import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

/// Initializes everything required before business logic can run.
///
/// Safe to call from both the foreground app and background workers.
/// Must complete before `runApp()` or any service-layer code.
///
/// Responsibilities:
///   - Flutter bindings
///   - Hydrated storage (persisted bloc state)
///   - Dependency injection
///   - H3 geo runtime
Future<void> initCore(String env) async {
  final total = Stopwatch()..start();
  var sw = Stopwatch()..start();

  WidgetsFlutterBinding.ensureInitialized();
  logger.d('[initCore] ensureInitialized: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  await Future.wait([
    persistEnvironment(env),
    buildHydratedStorage().then((storage) => HydratedBloc.storage = storage),
  ]);
  logger.d(
    '[initCore] persistEnv + hydratedStorage: ${sw.elapsedMilliseconds}ms',
  );

  sw.reset();
  configureInjection(env);
  logger.d('[initCore] configureInjection: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  getIt.registerSingleton<Hostr>(
    Hostr(config: getIt<Config>().hostrConfig, environment: env),
  );
  logger.d('[initCore] registerHostr: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  await getIt<Hostr>().initAuth();
  logger.d('[initCore] initAuth: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  configureFlutterH3Runtime();
  logger.d('[initCore] H3 runtime: ${sw.elapsedMilliseconds}ms');

  total.stop();
  logger.d('[initCore] TOTAL: ${total.elapsedMilliseconds}ms (env=$env)');
}

/// Post-`runApp` setup for the foreground app only.
///
/// Call this *after* `runApp()` so the render pipeline is active.
///
/// Responsibilities:
///   - Orientation lock
///   - Local notifications
///   - Workmanager periodic task registration
Future<void> initApp() async {
  final total = Stopwatch()..start();
  var sw = Stopwatch()..start();

  await _lockAppOrientation();
  logger.d('[initApp] lockOrientation: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  final env = await readPersistedEnvironment();
  logger.d('[initApp] readPersistedEnv: ${sw.elapsedMilliseconds}ms');

  // Skip notification permission prompt in test — it blocks CI and
  // screenshot automation with a system dialog that can't be pre-granted.
  if (env != Env.test && env != Env.mock) {
    sw.reset();
    await setupNotifications();
    logger.d('[initApp] notifications: ${sw.elapsedMilliseconds}ms');
  }

  if (!kIsWeb) {
    sw.reset();
    setupWorkmanager();
    logger.d('[initApp] workmanager: ${sw.elapsedMilliseconds}ms');
  }

  total.stop();
  logger.d('[initApp] TOTAL: ${total.elapsedMilliseconds}ms');
}

Future<void> _lockAppOrientation() async {
  if (kIsWeb) return;
  if (!(Platform.isAndroid || Platform.isIOS)) return;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

void setupWorkmanager() {
  Workmanager().initialize(callbackDispatcher);
  // Only register periodic/processing tasks — don't register a one-off task
  // every launch, as that triggers an immediate background execution.
  // Use ExistingWorkPolicy.keep to avoid re-registering on every cold start.
  Workmanager().registerPeriodicTask(
    iOSBackgroundAppRefresh,
    'sync',
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
  // Workmanager().registerProcessingTask(iOSBackgroundProcessingTask, 'sync');
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

const String _environmentPrefsKey = 'hostr.env';

Future<void> persistEnvironment(String env) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_environmentPrefsKey, env);
}

Future<String> readPersistedEnvironment() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_environmentPrefsKey) ?? Env.prod;
}
