import 'dart:async';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hostr/background_task_type.dart';
import 'package:hostr/data/sources/h3_engine.dart';
import 'package:hostr/data/sources/operations_db.dart';
import 'package:hostr/main.dart';
import 'package:hostr/route/notification_deep_link_handler.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'injection.dart';
import 'setup/hydrated_storage.dart';

final logger = CustomLogger(tag: 'app');

/// Initializes everything required before business logic can run.
///
/// Safe to call from both the foreground app and background workers.
/// Must complete before `runApp()` or any service-layer code.
///
/// When [logger] is provided it is used for all boot logs **and** injected
/// into the SDK's DI container so every singleton receives the same
/// instance (e.g. with a `hostr-background` tag).
///
/// Responsibilities:
///   - Flutter bindings
///   - Hydrated storage (persisted bloc state)
///   - Dependency injection
///   - H3 geo runtime
Future<void> initCore(String env, {CustomLogger? logger}) async {
  final log = (logger ?? CustomLogger()).scope('init-core');
  final total = Stopwatch()..start();
  var sw = Stopwatch()..start();

  WidgetsFlutterBinding.ensureInitialized();
  log.d('ensureInitialized: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  await Future.wait([
    persistEnvironment(env),
    buildHydratedStorage().then((storage) => HydratedBloc.storage = storage),
  ]);
  log.d('persistEnv + hydratedStorage: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  configureInjection(env);
  log.d('configureInjection: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  final operationsDb = await openOperationsDb();
  log.d('openOperationsDb: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  getIt.registerSingleton<Hostr>(
    Hostr(
      config: getIt<Config>().buildHostrConfig(
        logger: logger,
        operationsDb: operationsDb,
        configureCryptography: () {
          Cryptography.instance = FlutterCryptography.defaultInstance;
        },
        showNotification:
            ({required int id, String? title, String? body, String? payload}) =>
                FlutterLocalNotificationsPlugin().show(
                  id: id,
                  title: title,
                  body: body,
                  payload: payload,
                ),
      ),
      environment: env,
    ),
  );
  log.d('registerHostr: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  await getIt<Hostr>().initAuth();
  log.d('initAuth: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  configureFlutterH3Runtime();
  log.d('H3 runtime: ${sw.elapsedMilliseconds}ms');

  total.stop();
  log.d('TOTAL: ${total.elapsedMilliseconds}ms (env=$env)');
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
  logger.d('lockOrientation: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  final env = await readPersistedEnvironment();
  logger.d('readPersistedEnv: ${sw.elapsedMilliseconds}ms');

  // Skip notification permission prompt in test — it blocks CI and
  // screenshot automation with a system dialog that can't be pre-granted.
  if (env != Env.test && env != Env.mock) {
    sw.reset();
    await setupNotifications();
    logger.d('notifications: ${sw.elapsedMilliseconds}ms');
  }

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    sw.reset();
    setupWorkmanager();
    logger.d('workmanager: ${sw.elapsedMilliseconds}ms');
  }

  total.stop();
  logger.d('total elapsed: ${total.elapsedMilliseconds}ms');
}

Future<void> _lockAppOrientation() async {
  if (kIsWeb) return;
  if (!(Platform.isAndroid || Platform.isIOS)) return;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

void setupWorkmanager() {
  Workmanager().initialize(callbackDispatcher);
  // Only register periodic tasks at launch — processing tasks are scheduled
  // on-demand by _scheduleOnchainOperations() when the app enters background.
  // Use ExistingWorkPolicy.keep to avoid re-registering on every cold start.
  Workmanager().registerPeriodicTask(
    BackgroundTaskType.periodicSync.identifier,
    BackgroundTaskType.periodicSync.taskName,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
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
    onDidReceiveNotificationResponse: handleNotificationResponse,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  final launchDetails = await flutterLocalNotificationsPlugin
      .getNotificationAppLaunchDetails();
  final launchPayload = launchDetails?.notificationResponse?.payload;
  if (launchPayload != null && launchPayload.isNotEmpty) {
    dispatchNotificationPayload(launchPayload);
  }
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
