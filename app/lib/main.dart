import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/setup.dart';

import 'app.dart';

/// Export items from our app such that they can be used by widgetbook.

export './export.dart';

/// Common entrypoint used by environment-specific `main_*.dart` files.
///
/// - Initializes app dependencies and storage
/// - Sets up the target environment (dev/staging/prod/mock/test)
/// - Boots the Flutter app
void mainCommon(String env) async {
  runZonedGuarded(() async {
    await setup(env);
    runApp(MyApp());
  }, (error, stackTrace) {
    // Route all top-level errors here to avoid crashing without context.
    debugPrint('Caught error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}
