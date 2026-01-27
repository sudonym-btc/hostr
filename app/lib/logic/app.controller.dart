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
  late SwapManager swapManager;
  late Ndk ndk;
  late NostrService nostrService;
  late NwcService nwc;
  late ThreadsCubit threadsCubit;

  late StreamSubscription sub;
  late SessionCoordinator sessionCoordinator;

  AppController() {
    ndk = getIt<Ndk>();
    nostrService = getIt<NostrService>();
    nwc = getIt<NwcService>();

    authCubit = AuthCubit(
      keyStorage: getIt(),
      secureStorage: getIt(),
      authService: getIt(),
    );
    eventPublisherCubit = EventPublisherCubit(
      nostrService: nostrService,
      workflow: getIt(),
    );
    paymentsManager = PaymentsManager(dio: getIt(), nwcService: nwc);
    swapManager = SwapManager(
      paymentsManager: paymentsManager,
      swapService: getIt(),
      workflow: getIt(),
    );
    threadsCubit = ThreadsCubit(nostrService);

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
    swapManager.close();
  }
}
