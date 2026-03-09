import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hostr/app.dart';
import 'package:hostr/background.dart';
import 'package:hostr/setup.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
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
      await initCore(env);
      runApp(const MyApp());
      await initApp();
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
  final logger = CustomLogger(tag: 'hostr-background');
  logger.d('invoked');

  Workmanager().executeTask((task, inputData) async {
    final env = await readPersistedEnvironment();
    return await executeBackgroundTask(env, task, inputData);
  });
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
}
