import 'dart:async';

import 'package:ndk/ndk.dart' show Ndk;

import 'config.dart';
import 'injection.dart';
import 'usecase/main.dart';
import 'util/custom_logger.dart' show CustomLogger;

class Hostr {
  final HostrConfig config;
  final CustomLogger logger;
  Hostr({required this.config, String environment = Env.prod})
    : logger = config.logger {
    configureInjection(environment, config: config);
  }
  Ndk get ndk => getIt<Ndk>();
  Auth get auth => getIt<Auth>();
  Requests get requests => getIt<Requests>();
  MetadataUseCase get metadata => getIt<MetadataUseCase>();
  Nwc get nwc => getIt<Nwc>();
  Zaps get zaps => getIt<Zaps>();
  Listings get listings => getIt<Listings>();
  Location get location => getIt<Location>();
  Reservations get reservations => getIt<Reservations>();
  ReservationPairs get reservationPairs => getIt<ReservationPairs>();
  ReservationTransitions get reservationTransitions =>
      getIt<ReservationTransitions>();
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
  TradeAudit get tradeAudit => getIt<TradeAudit>();
  Evm get evm => getIt<Evm>();
  Relays get relays => getIt<Relays>();
  Verification get verification => getIt<Verification>();
  BlossomUseCase get blossom => getIt<BlossomUseCase>();
  UserConfigStore get userConfig => getIt<UserConfigStore>();
  AutoWithdrawService get autoWithdraw => getIt<AutoWithdrawService>();
  OperationStateStore get operationStateStore => getIt<OperationStateStore>();
  EscrowFundRegistry get escrowFundRegistry => getIt<EscrowFundRegistry>();
  BackgroundWorker get backgroundWorker => getIt<BackgroundWorker>();
  UserSubscriptions get userSubscriptions => getIt<UserSubscriptions>();
  PaymentProofOrchestrator get paymentProofOrchestrator =>
      getIt<PaymentProofOrchestrator>();

  StreamSubscription? _authStateSubscription;
  bool _authInitialized = false;
  bool _connected = false;

  /// Loads stored user config and restores auth keys.
  ///
  /// This is fast and network-free — safe to call before `runApp()`.
  /// Must be called exactly once, before [connect].
  Future<void> initAuth() async {
    if (_authInitialized) return;
    _authInitialized = true;

    // Ensure user config is loaded from disk before anything else.
    await userConfig.initialize();

    // Restore stored keys and sync NDK accounts.
    await auth.init();
  }

  /// Connects to bootstrap relays and starts the auth-state listener.
  ///
  /// Call this from the startup gate widget — it blocks on the relay
  /// handshake and can take 300 ms – 15 s depending on the network.
  /// Throws if no relay connects within the timeout.
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> connect() async {
    if (_connected) return;
    _connected = true;
    await _stopAuthListener();

    await relays.connect();

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

        await messaging.threads.sync();

        // Start user-scoped Nostr subscriptions and the payment-proof
        // orchestrator. UserSubscriptions must start first so its streams
        // are live before the orchestrator subscribes to them.
        userSubscriptions.start();
        paymentProofOrchestrator.start();

        // Ensure the user's profile has an EVM address tag.
        metadata.ensureEvmAddress();

        // Ensure the user's blossom server list includes the bootstrap servers.
        // Await this during login to avoid races where media upload happens
        // before the list is visible/available.
        await blossom.ensureBlossomServer(pubkey);

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
        evm.recoverStaleOperations();

        // Start auto-withdrawing EVM balances to Lightning.
        autoWithdraw.start();
      } else {
        logger.i('User logged out');
        autoWithdraw.stop();
        await paymentProofOrchestrator.reset();
        await userSubscriptions.reset();
        messaging.threads.reset();
        await nwc.reset();
        await reservations.reset();
        await evm.reset();
      }
    });
  }

  /// Legacy single-call entry point. Calls [initAuth] then [connect].
  @Deprecated('Use initAuth() + connect() instead')
  Future<void> start() async {
    await initAuth();
    await connect();
  }

  Future<void> _stopAuthListener() async {
    await _authStateSubscription?.cancel();
  }

  Future<void> dispose() async {
    _authInitialized = false;
    _connected = false;
    await _stopAuthListener();
    await autoWithdraw.stop();
    await paymentProofOrchestrator.reset();
    await userSubscriptions.reset();
    await messaging.threads.close();
    await reservations.dispose();
    await nwc.dispose();
    await evm.dispose();
    await auth.dispose();
    userConfig.dispose();

    // Tear down the remaining NDK pieces sequentially.
    //
    // Do NOT call `ndk.destroy()` here: its implementation runs
    // `disconnectAll()`, `closeAllSubscription()`, and
    // `closeAllTransports()` concurrently, which can reintroduce the exact
    // teardown race we are trying to avoid (a subscription tries to
    // read/write while its transport is already closing), producing an
    // intermittent `SocketException: Reading from a closed socket`.
    final ndk = getIt<Ndk>();
    await ndk.requests.closeAllSubscription();
    await ndk.relays.closeAllTransports();
    await ndk.accounts.dispose();
  }
}
