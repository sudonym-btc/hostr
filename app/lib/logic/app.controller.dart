import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

class AppController {
  late AuthCubit authCubit;
  late GlobalGiftWrapCubit giftWrapListCubit;
  late ThreadOrganizerCubit threadOrganizerCubit;

  late PaymentsManager paymentsManager;
  late SwapManager swapManager;
  late Ndk ndk;

  AppController() {
    authCubit = AuthCubit();
    giftWrapListCubit = GlobalGiftWrapCubit(authCubit: authCubit);
    threadOrganizerCubit =
        ThreadOrganizerCubit(globalMessageCubit: giftWrapListCubit);
    paymentsManager = PaymentsManager();
    swapManager = SwapManager(paymentsManager: paymentsManager);
    ndk = getIt<Ndk>();

    authCubit.stream.listen((state) {
      if (state is LoggedIn) {
        ndk.accounts.loginPrivateKey(
            pubkey: getIt<KeyStorage>().getActiveKeyPairSync()!.publicKey,
            privkey: getIt<KeyStorage>().getActiveKeyPairSync()!.privateKey!);

        ndk.userRelayLists.setInitialUserRelayList(UserRelayList(
            pubKey: getIt<KeyStorage>().getActiveKeyPairSync()!.publicKey,
            relays: {getIt<Config>().hostrRelay: ReadWriteMarker.readWrite},
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            refreshedTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000));
      } else {
        ndk.accounts.accounts.forEach((pubkey, account) {
          ndk.accounts.removeAccount(pubkey: pubkey);
        });
      }
    });
  }

  void dispose() {
    authCubit.close();
    giftWrapListCubit.close();
    threadOrganizerCubit.close();
    paymentsManager.close();
    swapManager.close();
  }
}
