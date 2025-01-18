import 'cubit/main.dart';
import 'services/main.dart';

class AppController {
  late AuthCubit authCubit;
  late GlobalGiftWrapCubit giftWrapListCubit;
  late ThreadOrganizerCubit threadOrganizerCubit;

  late PaymentsManager paymentsManager;
  late SwapManager swapManager;

  AppController() {
    authCubit = AuthCubit();
    giftWrapListCubit = GlobalGiftWrapCubit(authCubit: authCubit);
    threadOrganizerCubit =
        ThreadOrganizerCubit(globalMessageCubit: giftWrapListCubit);
    paymentsManager = PaymentsManager();
    swapManager = SwapManager(paymentsManager: paymentsManager);
  }

  void dispose() {
    print('disposing app controller');
    authCubit.close();
    giftWrapListCubit.close();
    threadOrganizerCubit.close();
    paymentsManager.close();
    swapManager.close();
  }
}
