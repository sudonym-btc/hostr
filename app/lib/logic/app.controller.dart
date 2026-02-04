import 'dart:async';

import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/ndk.dart';

class AppController {
  CustomLogger logger = CustomLogger();

  late Ndk ndk;
  late Hostr hostrService;
  late Threads threads;

  late StreamSubscription sub;

  AppController() {
    ndk = getIt<Ndk>();
    hostrService = getIt<Hostr>();
    hostrService.start();
  }

  void dispose() {
    threads.close();
  }
}
