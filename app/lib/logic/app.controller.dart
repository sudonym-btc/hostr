import 'dart:async';

import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class AppController {
  CustomLogger logger = CustomLogger();
  late AuthCubit authCubit;
  late GlobalGiftWrapCubit giftWrapListCubit;
  late ThreadOrganizerCubit threadOrganizerCubit;
  late EventPublisherCubit eventPublisherCubit;

  late PaymentsManager paymentsManager;
  late SwapManager swapManager;
  late Ndk ndk;
  late NostrService nostrService;
  late NwcService nwc;

  late StreamSubscription sub;

  AppController() {
    ndk = getIt<Ndk>();
    nostrService = getIt<NostrService>();
    nwc = getIt<NwcService>();

    authCubit = AuthCubit(
      keyStorage: getIt(),
      secureStorage: getIt(),
      ndk: getIt(),
      workflow: getIt(),
    );
    giftWrapListCubit = GlobalGiftWrapCubit(
      nostrService: nostrService,
      authCubit: authCubit,
    );
    threadOrganizerCubit = ThreadOrganizerCubit(
      nostrService: nostrService,
      globalMessageCubit: giftWrapListCubit,
      routingService: getIt(),
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

    sub = authCubit.stream.listen((state) async {
      if (state is LoggedIn) {
        KeyPair key = getIt<KeyStorage>().getActiveKeyPairSync()!;
        ndk.accounts.loginPrivateKey(
          pubkey: key.publicKey,
          privkey: key.privateKey!,
        );

        await ndk.userRelayLists.setInitialUserRelayList(
          UserRelayList(
            pubKey: key.publicKey,
            relays: {getIt<Config>().hostrRelay: ReadWriteMarker.readWrite},
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            refreshedTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );

        logger.i('Synching gift wraps ${key.publicKey}');

        giftWrapListCubit.filter = Filter(pTags: [key.publicKey]);
        giftWrapListCubit.sync();
      } else {
        ndk.accounts.accounts.forEach((pubkey, account) {
          ndk.accounts.removeAccount(pubkey: pubkey);
        });
        logger.i('Clearing gift wraps');
        giftWrapListCubit.clear();
      }
    });
  }

  void dispose() {
    sub.cancel();
    authCubit.close();
    giftWrapListCubit.close();
    threadOrganizerCubit.close();
    eventPublisherCubit.close();
    paymentsManager.close();
    swapManager.close();
  }
}
