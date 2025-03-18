// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/setup.dart';

import 'app.dart';

/**
 * Export items from our app such that they can be used by widgetbook
 */

export './export.dart';

void mainCommon(String env) async {
  runZonedGuarded(() async {
    await setup(env);
    runApp(MyApp());
  }, (error, stackTrace) {
    print('Caught error: $error');
    print('Stack trace: $stackTrace');
  });
}
