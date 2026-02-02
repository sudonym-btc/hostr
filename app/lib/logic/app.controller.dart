import 'dart:async';

import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/ndk.dart';

class AppController {
  CustomLogger logger = CustomLogger();
  late AuthCubit authCubit;
  late EventPublisherCubit eventPublisherCubit;

  late Ndk ndk;
  late Hostr hostrService;
  late Threads threads;

  late StreamSubscription sub;
  late SessionCoordinator sessionCoordinator;

  AppController() {
    ndk = getIt<Ndk>();
    hostrService = getIt<Hostr>();

    authCubit = AuthCubit();
    eventPublisherCubit = EventPublisherCubit(
      hostr: hostrService,
      workflow: getIt(),
    );
    threads = hostrService.messaging.threads;

    sessionCoordinator = getIt<SessionCoordinator>();
    sessionCoordinator.start(authCubit: authCubit, ndk: ndk, threads: threads);
  }

  void dispose() {
    sessionCoordinator.dispose();
    authCubit.close();
    eventPublisherCubit.close();
    threads.close();
  }
}
