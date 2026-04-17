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
    if (!getIt.isRegistered<HostrConfig>()) {
      getIt.registerSingleton<HostrConfig>(config);
    }
  }
  Ndk get ndk => getIt<Ndk>();
  Auth get auth => getIt<Auth>();
  Requests get requests => getIt<Requests>();
  MetadataUseCase get metadata => getIt<MetadataUseCase>();
  Nwc get nwc => getIt<Nwc>();
  Zaps get zaps => getIt<Zaps>();
  Listings get listings => getIt<Listings>();
  LnurlUseCase get lnurl => getIt<LnurlUseCase>();
  Location get location => getIt<Location>();
  Reservations get reservations => getIt<Reservations>();
  ReservationGroups get reservationGroups => getIt<ReservationGroups>();
  ReservationTransitions get reservationTransitions =>
      getIt<ReservationTransitions>();
  GiftWraps get giftWraps => getIt<GiftWraps>();
  EscrowUseCase get escrow => getIt<EscrowUseCase>();
  Escrows get escrows => getIt<Escrows>();
  EscrowMethods get escrowMethods => getIt<EscrowMethods>();
  BadgeDefinitions get badgeDefinitions => getIt<BadgeDefinitions>();
  BadgeAwards get badgeAwards => getIt<BadgeAwards>();
  Messaging get messaging => getIt<Messaging>();
  ReservationRequests get reservationRequests => getIt<ReservationRequests>();
  Payments get payments => getIt<Payments>();
  Reviews get reviews => getIt<Reviews>();
  TradeAccountAllocator get tradeAccountAllocator =>
      getIt<TradeAccountAllocator>();
  TradeAudit get tradeAudit => getIt<TradeAudit>();
  Evm get evm => getIt<Evm>();
  Relays get relays => getIt<Relays>();
  Verification get verification => getIt<Verification>();
  BlossomUseCase get blossom => getIt<BlossomUseCase>();
  UserConfigStore get userConfig => getIt<UserConfigStore>();
  FundsMonitorService get fundsMonitor => getIt<FundsMonitorService>();
  OperationStateStore get operationStateStore => getIt<OperationStateStore>();
  SwapInTracker get swapInTracker => getIt<SwapInTracker>();
  SwapOutTracker get swapOutTracker => getIt<SwapOutTracker>();
  BackgroundWorker get backgroundWorker => getIt<BackgroundWorker>();
  Heartbeats get heartbeats => getIt<Heartbeats>();
  UserSubscriptions get userSubscriptions => getIt<UserSubscriptions>();
  PaymentProofOrchestrator get paymentProofOrchestrator =>
      getIt<PaymentProofOrchestrator>();
  Calendar get calendar => getIt<Calendar>();

  Trade trade(String tradeId) {
    final thread = messaging.threads.findPreferredThreadByTradeId(tradeId);
    final listingAnchor =
        thread?.state.value.reservationRequests
            .map((e) => e.parsedTags.listingAnchor)
            .where((a) => a.isNotEmpty)
            .firstOrNull ??
        userSubscriptions.allMyReservations$.stream.items
            .where(
              (r) =>
                  r.getDtag() == tradeId &&
                  r.parsedTags.listingAnchor.isNotEmpty,
            )
            .map((r) => r.parsedTags.listingAnchor)
            .firstOrNull;
    if (listingAnchor == null) {
      throw StateError('Unable to resolve listing anchor for trade $tradeId');
    }
    return getIt<Trade>(param1: tradeId, param2: listingAnchor);
  }

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

    // Discover Boltz swap capabilities and attach swap providers to
    // matching EVM chains. This must complete before any escrow flow
    // tries to compute swap amounts.
    await evm.init();

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
        final hasNip65 = await relays.syncNip65(pubkey);

        // If syncNip65 found an existing relay list the user is a
        // returning user with healthy connectivity — safe to run ensures
        // now. New users (no NIP-65 yet) will trigger ensures when they
        // save their profile for the first time via MetadataUseCase.upsert.
        if (hasNip65) {
          await metadata.ensureUserConfig(pubkey);
        } else {
          logger.i(
            'No NIP-65 relay list found — skipping ensure calls until '
            'profile is saved.',
          );
        }

        // Start user-scoped Nostr subscriptions and the payment-proof
        // orchestrator. UserSubscriptions must start first so its streams
        // are live before the orchestrator subscribes to them.
        await userSubscriptions.start();
        paymentProofOrchestrator.start();
        fundsMonitor.start();
        nwc.start();
        await backgroundWorker.watch(onProgress: _onProgressFromConfig());

        await calendar.start();
      } else {
        logger.i('User logged out');
        await backgroundWorker.stop();
        await calendar.stop();
        await fundsMonitor.stop();
        await paymentProofOrchestrator.reset();
        await userSubscriptions.reset();
        messaging.threads.reset();
        await nwc.reset();
        await reservations.reset();
        await evm.reset();
      }
    });
  }

  /// Lightweight connect for background workers.
  ///
  /// Connects to bootstrap relays and syncs the user's NIP-65 relay list
  /// so that queries work correctly, but does **not** start any long-lived
  /// subscriptions (UserSubscriptions, PaymentProofOrchestrator, NWC,
  /// Calendar, AutoWithdraw, etc.).
  ///
  /// Use this instead of [connect] in Workmanager callbacks to keep the
  /// background isolate fast and resource-light.
  Future<void> connectForBackground() async {
    await relays.connect();
    await relays.ensureConnected();
  }

  Future<void> _stopAuthListener() async {
    await _authStateSubscription?.cancel();
  }

  /// Bridges [HostrConfig.showNotification] into an [OnBackgroundProgress]
  /// callback that the recovery pipeline understands.
  OnBackgroundProgress? _onProgressFromConfig() {
    final show = config.showNotification;
    if (show == null) return null;
    return (notification) => show(
      id: notification.operationId.hashCode,
      title: 'Hostr',
      body: notification.body,
      payload: notification.payload,
    );
  }

  Future<void> dispose() async {
    _authInitialized = false;
    _connected = false;
    await _stopAuthListener();
    await backgroundWorker.stop();
    await calendar.stop();
    await fundsMonitor.stop();
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
    //
    await ndk.requests.closeAllSubscription();
    await ndk.relays.closeAllTransports();
    await ndk.accounts.dispose();
  }
}
