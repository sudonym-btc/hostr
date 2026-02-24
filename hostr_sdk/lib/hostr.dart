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
  Verification get verification => getIt<Verification>();

  StreamSubscription? _authStateSubscription;

  void start() {
    stop();

    auth.init();

    _authStateSubscription = auth.authState.listen((state) async {
      logger.d('Auth state changed: $state');
      if (state is LoggedIn) {
        // Wait for at least one relay to be connected before issuing any
        // queries. On a cold start over wireless/Tailscale the WebSocket
        // handshake may lag behind the auth restore, causing the first
        // batch of queries to silently return empty results.
        await relays.ensureConnected();

        final pubkey = auth.getActiveKey().publicKey;

        // Fetch the user's NIP-65 relay list and connect to those relays.
        // This also populates NDK's cache so the outbox/inbox model works
        // automatically for subsequent broadcasts and queries.
        await relays.syncNip65(pubkey);

        // Ensure the hostr relay is in the user's published NIP-65 list.
        await relays.publishNip65(
          hostrRelay: config.hostrRelay,
          pubkey: pubkey,
        );

        messaging.threads.sync();

        // Ensure the user's profile has an EVM address tag.
        metadata.ensureEvmAddress();

        final blossomList = await getIt<Ndk>().blossomUserServerList
            .getUserServerList(pubkeys: [pubkey]);
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

        // Ensure the user's escrow method list includes EVM.
        escrowMethods.ensureEscrowMethod();

        // Ensure the user's escrow trust list includes the bootstrap providers.
        if (config.bootstrapEscrowPubkeys.isNotEmpty) {
          escrowTrusts.ensureEscrowTrust(config.bootstrapEscrowPubkeys);
        }

        // Reset the EVM balance subscription for the new user's address.
        evm.resetBalance();

        // Recover any stale swaps (claims/refunds) from previous sessions.
        evm.recoverStaleSwaps();
      } else {
        logger.i('User logged out');
        messaging.threads.stop();
        reservations.dispose();
        evm.dispose();
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
