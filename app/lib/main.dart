import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hostr/app.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/screens/shared/profile/background_tasks.dart';
import 'package:hostr/setup.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Export items from our app such that they can be used by widgetbook.

export './export.dart';

/// Common entrypoint used by environment-specific `main_*.dart` files.
///
/// - Initializes app dependencies and storage
/// - Sets up the target environment (dev/staging/prod/mock/test)
/// - Boots the Flutter app
void mainCommon(String env) async {
  runZonedGuarded(
    () async {
      await setup(env);
      runApp(const MyApp());
    },
    (error, stackTrace) {
      // Route all top-level errors here to avoid crashing without context.
      debugPrint('Caught error: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  print('callbackDispatcher: not in taskexecution');

  Workmanager().executeTask((task, inputData) async {
    try {
      print('callbackDispatcher: $task, inputData: $inputData');
      final env = await readPersistedEnvironment();
      await setupBackground(env);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(iOSBackgroundAppRefresh, 'done');
      prefs.setString(iOSBackgroundProcessingTask, 'done');

      final messages = await getIt<Hostr>().messaging.threads.refresh();
      print('Synced messages: ${messages.length}');
      await FlutterLocalNotificationsPlugin().show(
        id: 2,
        title: 'Hostr',
        body: 'You have ${messages.length} new messages',
      );
      // switch (task) {
      //   case "sync":
      //     print('here we are');
      //     prefs.setString(iOSBackgroundAppRefresh, 'done');
      //     break;
      //   case Workmanager.iOSBackgroundTask:
      //     // iOS Background Fetch task
      //     print('here we are in bg task');
      //     break;
      //   default:
      //     print('here we are in unknown');
      //     // Handle unknown task types
      //     break;
      // }

      return Future.value(true);
    } catch (e, st) {
      print('Error in background task: $e, stackTrace: $st');
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
}
