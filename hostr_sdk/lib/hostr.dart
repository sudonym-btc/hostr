import 'package:ndk/ndk.dart' show Ndk;
import 'package:get_it/get_it.dart';

import 'config.dart';
import 'injection.dart';
import 'usecase/main.dart';
import 'util/custom_logger.dart' show CustomLogger;

class Hostr {
  final HostrConfig config;
  final CustomLogger logger;
  final GetIt scope;

  Hostr({required this.config, String environment = Env.prod})
    : logger = config.logger,
      scope = createHostrScope(environment: environment, config: config) {
    getIt = scope;
  }
  Ndk get ndk => scope<Ndk>();
  Auth get auth => scope<Auth>();
  Requests get requests => scope<Requests>();
  MetadataUseCase get metadata => scope<MetadataUseCase>();
  Nwc get nwc => scope<Nwc>();
  Zaps get zaps => scope<Zaps>();
  Listings get listings => scope<Listings>();
  LnurlUseCase get lnurl => scope<LnurlUseCase>();
  Location get location => scope<Location>();
  Reservations get orderWorkflows => scope<Reservations>();
  OrderGroupVerification get orderGroupVerification =>
      scope<OrderGroupVerification>();
  GiftWraps get giftWraps => scope<GiftWraps>();
  DmRelays get dmRelays => scope<DmRelays>();
  EscrowUseCase get escrow => scope<EscrowUseCase>();
  Escrows get escrows => scope<Escrows>();
  EscrowMethods get escrowMethods => scope<EscrowMethods>();
  BadgeDefinitions get badgeDefinitions => scope<BadgeDefinitions>();
  BadgeAwards get badgeAwards => scope<BadgeAwards>();
  Messaging get messaging => scope<Messaging>();
  ReservationRequests get reservationRequests => scope<ReservationRequests>();
  Payments get payments => scope<Payments>();
  Reviews get reviews => scope<Reviews>();
  TradeAccountAllocator get tradeAccountAllocator =>
      scope<TradeAccountAllocator>();
  TradeAudit get tradeAudit => scope<TradeAudit>();
  Evm get evm => scope<Evm>();
  Relays get relays => scope<Relays>();
  Verification get verification => scope<Verification>();
  BlossomUseCase get blossom => scope<BlossomUseCase>();
  UserConfigStore get userConfig => scope<UserConfigStore>();
  FundsMonitorService get fundsMonitor => scope<FundsMonitorService>();
  OperationStateStore get operationStateStore => scope<OperationStateStore>();
  SwapInTracker get swapInTracker => scope<SwapInTracker>();
  SwapOutTracker get swapOutTracker => scope<SwapOutTracker>();
  BackgroundWorker get backgroundWorker => scope<BackgroundWorker>();
  Heartbeats get heartbeats => scope<Heartbeats>();
  IdentityClaimsUseCase get identityClaims => scope<IdentityClaimsUseCase>();
  UserSubscriptions get userSubscriptions => scope<UserSubscriptions>();
  EscrowDaemon get escrowDaemon => scope<EscrowDaemon>();
  AccountSeedStore get accountSeedStore => scope<AccountSeedStore>();
  PaymentProofOrchestrator get paymentProofOrchestrator =>
      scope<PaymentProofOrchestrator>();
  Calendar get calendar => scope<Calendar>();
  StartupCoordinator get startup => scope<StartupCoordinator>();

  Trade trade(String tradeId, Iterable<String> participants) {
    return scope<Trade>(
      param1: TradeContext(tradeId: tradeId, participants: participants),
    );
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
    await orderWorkflows.dispose();
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
