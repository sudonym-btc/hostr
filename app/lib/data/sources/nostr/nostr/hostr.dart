import 'dart:async';

import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' show Ndk;

import 'usecase/auth/auth.dart';
import 'usecase/badge_awards/badge_awards.dart';
import 'usecase/badge_definitions/badge_definitions.dart';
import 'usecase/escrow_methods/escrows_methods.dart';
import 'usecase/escrow_trusts/escrows_trusts.dart';
import 'usecase/escrows/escrows.dart';
import 'usecase/evm/evm.dart';
import 'usecase/listings/listings.dart';
import 'usecase/messaging/messaging.dart';
import 'usecase/metadata/metadata.dart';
import 'usecase/nwc/nwc.dart';
import 'usecase/payments/payments.dart';
import 'usecase/relays/relays.dart';
import 'usecase/requests/requests.dart';
import 'usecase/reservation_requests/reservation_requests.dart';
import 'usecase/reservations/reservations.dart';
import 'usecase/swap/swap.dart';
import 'usecase/zaps/zaps.dart';

abstract class Hostr {
  final Ndk ndk;
  Hostr({required this.ndk});

  CustomLogger logger = CustomLogger();
  Auth get auth => getIt<Auth>();
  Requests get requests => getIt<Requests>();
  MetadataUseCase get metadata => getIt<MetadataUseCase>();
  Nwc get nwc => getIt<Nwc>();
  Zaps get zaps => getIt<Zaps>();
  Listings get listings => getIt<Listings>();
  Reservations get reservations => getIt<Reservations>();
  Escrows get escrows => getIt<Escrows>();
  EscrowTrusts get escrowTrusts => getIt<EscrowTrusts>();
  EscrowMethods get escrowMethods => getIt<EscrowMethods>();
  BadgeDefinitions get badgeDefinitions => getIt<BadgeDefinitions>();
  BadgeAwards get badgeAwards => getIt<BadgeAwards>();
  Messaging get messaging => getIt<Messaging>();
  ReservationRequests get reservationRequests => getIt<ReservationRequests>();
  Payments get payments => getIt<Payments>();
  Swap get swaps => getIt<Swap>();
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
      } else {
        logger.i('User logged out');
        messaging.threads.stop();
      }
    });
  }

  void stop() {
    _authStateSubscription?.cancel();
  }

  void dispose() {
    stop();
  }
}

@Singleton(as: Hostr)
class ProdHostr extends Hostr {
  ProdHostr(Ndk ndk) : super(ndk: ndk);
}
