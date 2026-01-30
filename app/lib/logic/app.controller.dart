import 'dart:async';

import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/threads.cubit.dart';
import 'package:ndk/ndk.dart';

class AppController {
  CustomLogger logger = CustomLogger();
  late AuthCubit authCubit;
  late EventPublisherCubit eventPublisherCubit;

  late PaymentsManager paymentsManager;
  late Ndk ndk;
  late Hostr hostrService;
  late ThreadsCubit threadsCubit;

  late StreamSubscription sub;
  late SessionCoordinator sessionCoordinator;

  AppController() {
    ndk = getIt<Ndk>();
    hostrService = getIt<Hostr>();

    authCubit = AuthCubit(keyStorage: getIt(), secureStorage: getIt());
    eventPublisherCubit = EventPublisherCubit(
      hostr: hostrService,
      workflow: getIt(),
    );
    paymentsManager = PaymentsManager(dio: getIt(), hostr: hostrService);
    threadsCubit = ThreadsCubit(hostrService.messaging.threads);

    sessionCoordinator = getIt<SessionCoordinator>();
    sessionCoordinator.start(
      authCubit: authCubit,
      ndk: ndk,
      threadsCubit: threadsCubit,
    );
  }

  void dispose() {
    sessionCoordinator.dispose();
    authCubit.close();
    eventPublisherCubit.close();
    paymentsManager.close();
    threadsCubit.close();
  }
}
