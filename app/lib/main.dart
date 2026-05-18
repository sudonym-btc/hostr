import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hostr/app.dart';
import 'package:hostr/background.dart';
import 'package:hostr/injection.dart' show Env;
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
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const _BootstrapLoadingApp());
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

class _BootstrapLoadingApp extends StatelessWidget {
  const _BootstrapLoadingApp();

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF101010);
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: background,
        body: Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  final logger = CustomLogger(tag: 'hostr-background');
  logger.d('invoked');

  Workmanager().executeTask((task, inputData) async {
    final env = inputData?['env'] as String? ?? Env.prod;
    return await executeBackgroundTask(env, task, inputData);
  });
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
}
