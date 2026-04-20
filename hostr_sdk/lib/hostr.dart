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
  StartupCoordinator get startup => getIt<StartupCoordinator>();

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

  bool _authInitialized = false;

  /// Loads stored user config and restores auth keys.
  ///
  /// This is fast and network-free — safe to call before `runApp()`.
  /// Must be called exactly once, before foreground startup begins.
  Future<void> initAuth() async {
    if (_authInitialized) return;
    _authInitialized = true;

    // Ensure user config is loaded from disk before anything else.
    await userConfig.initialize();

    // Restore stored keys and sync NDK accounts.
    await auth.init();
  }

  Future<void> dispose() async {
    _authInitialized = false;
    await startup.dispose();
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
    await swapInTracker.dispose();
    await swapOutTracker.dispose();
    await operationStateStore.dispose();
    await userConfig.dispose();

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
    config.telemetry.shutdown();
  }
}
