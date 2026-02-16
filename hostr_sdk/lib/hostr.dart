import 'dart:async';

import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:ndk/ndk.dart' show Ndk;

import 'usecase/main.dart';
import 'util/custom_logger.dart' show CustomLogger;

class Hostr {
  final HostrConfig config;
  final CustomLogger logger;
  Hostr({required this.config, String environment = Env.prod})
    : logger = config.logger {
    configureInjection(environment, config: config);
  }
  Auth get auth => getIt<Auth>();
  Requests get requests => getIt<Requests>();
  MetadataUseCase get metadata => getIt<MetadataUseCase>();
  Nwc get nwc => getIt<Nwc>();
  Zaps get zaps => getIt<Zaps>();
  Listings get listings => getIt<Listings>();
  Location get location => getIt<Location>();
  Reservations get reservations => getIt<Reservations>();
  EscrowUseCase get escrow => getIt<EscrowUseCase>();
  Escrows get escrows => getIt<Escrows>();
  EscrowTrusts get escrowTrusts => getIt<EscrowTrusts>();
  EscrowMethods get escrowMethods => getIt<EscrowMethods>();
  BadgeDefinitions get badgeDefinitions => getIt<BadgeDefinitions>();
  BadgeAwards get badgeAwards => getIt<BadgeAwards>();
  Messaging get messaging => getIt<Messaging>();
  ReservationRequests get reservationRequests => getIt<ReservationRequests>();
  Payments get payments => getIt<Payments>();
  Reviews get reviews => getIt<Reviews>();
  Evm get evm => getIt<Evm>();
  Relays get relays => getIt<Relays>();

  StreamSubscription? _authStateSubscription;

  void start() {
    stop();

    auth.init();

    _authStateSubscription = auth.authState.listen((state) async {
      if (state is LoggedIn) {
        messaging.threads.sync();

        // // Update an existing profile with any missing info (e.g. evm address)
        // await metadataUseCase.upsertMetadata();

        // // Ensure initial user relay list is set
        // await ndk.userRelayLists.broadcastAddNip65Relay(
        //   relayUrl: config.hostrRelay,
        //   marker: ReadWriteMarker.readWrite,
        //   broadcastRelays: [...config.relays],
        // );
        final blossomList = await getIt<Ndk>().blossomUserServerList
            .getUserServerList(pubkeys: [auth.activeKeyPair!.publicKey]);
        print('Blossom list: $blossomList');
        final broadcastResponse = await getIt<Ndk>().blossomUserServerList
            .publishUserServerList(
              serverUrlsOrdered: {
                ...blossomList ?? [],
                ...config.bootstrapBlossom,
              }.toList(),
            );
        print('Blossom list publish response: $broadcastResponse');

        nwc.start();
      } else {
        logger.i('User logged out');
        messaging.threads.stop();
      }
    });
  }

  void stop() {
    _authStateSubscription?.cancel();
  }

  Future<void> dispose() async {
    stop();
    messaging.threads.close();
    reservations.dispose();
    nwc.dispose();
    evm.dispose();
    auth.dispose();
  }
}
