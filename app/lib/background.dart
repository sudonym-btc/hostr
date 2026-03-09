import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import 'background_task_type.dart';
import 'config/http_overrides.dart';
import 'injection.dart';
import 'setup.dart';

Future<bool> executeBackgroundTask(
  String env,
  String task,
  Map<String, dynamic>? inputData,
) async {
  final logger = CustomLogger(tag: 'hostr-background');
  final taskType = parseBackgroundTaskType(task);
  logger.d('executeBackgroundTask: $task, inputData: $inputData');

  try {
    // The foreground entrypoint (main_development.dart) sets
    // HttpOverrides.global to trust self-signed dev TLS certs.
    // Workmanager spawns the callback in a fresh isolate where that
    // override is not inherited, so we must apply it here as well.
    if (env != Env.prod) {
      HttpOverrides.global = MyHttpOverrides();
    }

    await initCore(env, logger: logger);
    // Background workers need relay connectivity — the foreground app
    // handles this via the StartupGate widget, but here we call connect()
    // explicitly.
    await getIt<Hostr>().connect();

    final BackgroundWorkerResult result;

    switch (taskType) {
      case BackgroundTaskType.onchainOps:
        // One-off task triggered when the app goes to background with
        // active onchain operations (swaps, escrow fund/claim/release).
        logger.d('Running onchain operations recovery');
        result = await getIt<Hostr>().backgroundWorker.recoverOnchainOperations(
          onProgress: (notification) async {
            await FlutterLocalNotificationsPlugin().show(
              id: notification.operationId.hashCode,
              title: 'Hostr',
              body: notification.body,
            );
          },
        );
        break;
      case BackgroundTaskType.periodicSync:
        // Periodic sync task — messages, reservations, reviews, etc.
        logger.d('Running periodic sync');
        result = await getIt<Hostr>().backgroundWorker.run();
        break;
    }

    logger.d(
      'Background worker completed: ${result.notifications.length} notifications',
    );
    for (int i = 0; i < result.notifications.length; i++) {
      await FlutterLocalNotificationsPlugin().show(
        id: 2 + i,
        title: 'Hostr',
        body: result.notifications[i],
      );
    }

    return Future.value(true);
  } catch (e) {
    logger.e('Error executing background task: $e');
    return Future.value(false);
  }
}
