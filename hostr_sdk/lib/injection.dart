import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:marketplace_evm/marketplace_evm.dart';
import 'package:ndk/ndk.dart' show Ndk;
import 'package:sqlite3/common.dart';
import 'config.dart';
import 'datasources/app_database.dart';
import 'datasources/storage.dart';
import 'injection.config.dart';
import 'usecase/auth/auth.dart';
import 'usecase/auth/auth_identity_resolver.dart' show AuthIdentityResolver;
import 'usecase/calendar/calendar.dart';
import 'usecase/dm_relays/dm_relays.dart' show DmRelays;
import 'usecase/escrows/escrows.dart';
import 'usecase/gift_wraps/gift_wraps.dart' show GiftWraps;
import 'usecase/listings/listings.dart' show Listings;
import 'usecase/messaging/messaging.dart' show Messaging;
import 'usecase/messaging/threads.dart' show Threads;
import 'usecase/metadata/metadata.dart' show MetadataUseCase;
import 'usecase/nwc/nwc.dart';
import 'usecase/orders/orders.dart' show Orders;
import 'usecase/payments/payments.dart';
import 'usecase/relays/relays.dart';
import 'usecase/requests/requests.dart';
import 'usecase/storage/storage.dart';
import 'usecase/trades/payment_proof_orchestrator.dart'
    show PaymentProofOrchestrator;
import 'usecase/user_config/user_config_store.dart';
import 'usecase/user_subscriptions/user_subscriptions.dart';
import 'usecase/zaps/zaps.dart';

class HostrScope implements EvmDriverFactory {
  final GetIt container;

  HostrScope(this.container);

  @override
  EvmChain createChain(EvmChainConfig config, AACapability? aa) =>
      call<EvmChain>(param1: config, param2: aa);

  @override
  EscrowFundPreparer createEscrowFund(EscrowFundParams params) =>
      call<EscrowFundPreparer>(param1: params);

  @override
  EscrowClaimOperation createEscrowClaim(EscrowClaimParams params) =>
      call<EscrowClaimOperation>(param1: params);

  @override
  EscrowReleaseOperation createEscrowRelease(EscrowReleaseParams params) =>
      call<EscrowReleaseOperation>(param1: params);

  @override
  SwapRecoverer get swapRecoverer => call<SwapRecoverer>();

  @override
  void registerBoltzClient(BoltzClient client) {
    if (!isRegistered<BoltzClient>()) registerSingleton(client);
  }

  T call<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return container<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  bool isRegistered<T extends Object>({String? instanceName}) {
    return container.isRegistered<T>(instanceName: instanceName);
  }

  void registerSingleton<T extends Object>(T instance, {String? instanceName}) {
    container.registerSingleton<T>(instance, instanceName: instanceName);
  }
}

@InjectableInit(ignoreUnregisteredTypes: [HostrConfig, HostrScope])
GetIt createHostrScope({
  required String environment,
  required HostrConfig config,
}) {
  final scope = GetIt.asNewInstance();
  scope.registerSingleton<HostrConfig>(config);
  scope.registerSingleton<HostrScope>(HostrScope(scope));
  scope.init(environment: environment);
  return scope;
}

@module
abstract class HostrSdkModule {
  @singleton
  Auth auth(
    Ndk ndk,
    AuthStorage authStorage,
    CustomLogger logger,
    AuthIdentityResolver identityResolver,
    HostrScope scope,
  ) => Auth(
    ndk: ndk,
    authStorage: authStorage,
    logger: logger,
    identityResolver: identityResolver,
    scope: scope,
  );

  @singleton
  PaymentProofOrchestrator paymentProofOrchestrator(
    UserSubscriptions userSubs,
    Threads threads,
    Auth auth,
    Orders orders,
    Listings listings,
    MetadataUseCase metadata,
    CustomLogger logger,
    HostrConfig config,
    TradeAccountAllocator tradeAccountAllocator,
  ) => PaymentProofOrchestrator(
    userSubs: userSubs,
    threads: threads,
    auth: auth,
    orders: orders,
    listings: listings,
    metadata: metadata,
    logger: logger,
    config: config,
    tradeAccountAllocator: tradeAccountAllocator,
  );

  @singleton
  GiftWraps giftWraps(
    Ndk ndk,
    Requests requests,
    CustomLogger logger,
    HostrConfig config,
  ) => GiftWraps(ndk: ndk, requests: requests, logger: logger, config: config);

  @singleton
  Threads threads(
    Auth auth,
    UserSubscriptions userSubscriptions,
    CustomLogger logger,
    HostrScope scope,
  ) => Threads(
    auth: auth,
    userSubscriptions: userSubscriptions,
    logger: logger,
    scope: scope,
  );

  @singleton
  Messaging messaging(
    Ndk ndk,
    Requests requests,
    DmRelays dmRelays,
    CustomLogger logger,
    HostrConfig config,
    Relays relays,
    HostrScope scope,
  ) => Messaging(ndk, requests, dmRelays, logger, scope, config, relays);

  // Explicit factories keep optional constructor parameters fully injected.
  // The generator treats nullable parameters as different registration types.
  @Singleton(env: Env.allButTestAndMock)
  Relays relays(
    Ndk ndk,
    RelayStorage storage,
    CustomLogger logger,
    HostrConfig config,
    Requests requests,
  ) => Relays(
    ndk: ndk,
    relayStorage: storage,
    logger: logger,
    config: config,
    requests: requests,
  );

  @Singleton(env: [Env.test, Env.mock])
  Relays mockRelays(
    Ndk ndk,
    RelayStorage storage,
    CustomLogger logger,
    HostrConfig config,
    Requests requests,
  ) => MockRelays(
    ndk: ndk,
    relayStorage: storage,
    logger: logger,
    config: config,
    requests: requests,
  );

  @Singleton(env: Env.allButTestAndMock)
  Zaps zaps(
    Nwc nwc,
    Ndk ndk,
    HostrConfig config,
    Requests requests,
    CustomLogger logger,
  ) => Zaps(
    nwc: nwc,
    ndk: ndk,
    config: config,
    requests: requests,
    logger: logger,
  );

  @Singleton(env: [Env.test, Env.mock])
  Zaps mockZaps(Nwc nwc, Ndk ndk, HostrConfig config, Requests requests) =>
      MockZaps(nwc: nwc, ndk: ndk, config: config, requests: requests);

  @lazySingleton
  EvmNwc evmNwc(Nwc nwc) => nwc;

  @injectable
  SwapQuoteService swapQuoteService(CustomLogger logger) =>
      SwapQuoteService(logger: logger);

  @singleton
  SwapInTracker swapInTracker(CustomLogger logger) => SwapInTracker(logger);

  @singleton
  SwapOutTracker swapOutTracker(CustomLogger logger) => SwapOutTracker(logger);

  @singleton
  OperationStateStore operationStateStore(
    CommonDatabase db,
    CustomLogger logger,
    Auth auth,
  ) => OperationStateStore(db, logger, auth);

  @singleton
  Evm evm(
    HostrConfig config,
    Auth auth,
    CustomLogger logger,
    HostrScope scope,
  ) => Evm(config, auth, logger, scope);

  @singleton
  EscrowUseCase escrowUseCase(CustomLogger logger, Evm evm, HostrScope scope) =>
      EscrowUseCase(logger: logger, evm: evm, scope: scope);

  @singleton
  EscrowVerification escrowVerification(Evm evm, CustomLogger logger) =>
      EscrowVerification(evm: evm, logger: logger);

  @injectable
  SwapRecoverer swapRecoverer(
    OperationStateStore store,
    Auth auth,
    Evm evm,
    CustomLogger logger,
  ) => SwapRecoverer(store, auth, evm, logger);

  @injectable
  EvmChain evmChain(
    @factoryParam EvmChainConfig config,
    @factoryParam AACapability? aa,
    Auth auth,
    CustomLogger logger,
    SwapQuoteService quoteService,
    Nwc nwc,
    Payments payments,
  ) => EvmChain(
    config: config,
    aa: aa,
    auth: auth,
    logger: logger,
    quoteService: quoteService,
    nwc: nwc,
    payments: payments,
  );

  @injectable
  EscrowFundPreparer escrowFundPreparer(
    @factoryParam EscrowFundParams? params,
    Auth auth,
    TradeAccountAllocator allocator,
    Evm evm,
    SwapQuoteService quoteService,
    CustomLogger logger,
  ) => EscrowFundPreparer(auth, allocator, evm, quoteService, logger, params);

  @injectable
  EscrowClaimOperation escrowClaimOperation(
    @factoryParam EscrowClaimParams params,
    Auth auth,
    TradeAccountAllocator allocator,
    Evm evm,
    CustomLogger logger,
  ) => EscrowClaimOperation(auth, allocator, evm, logger, params);

  @injectable
  EscrowReleaseOperation escrowReleaseOperation(
    @factoryParam EscrowReleaseParams params,
    Auth auth,
    TradeAccountAllocator allocator,
    Evm evm,
    CustomLogger logger,
  ) => EscrowReleaseOperation(auth, allocator, evm, logger, params);

  @singleton
  FundsMonitorService fundsMonitorService(
    Evm evm,
    UserSubscriptions subscriptions,
    Auth auth,
    TradeAccountAllocator allocator,
    OperationStateStore store,
    UserConfigStore preferences,
    CustomLogger logger,
    Escrows escrows,
    HostrConfig config,
  ) => FundsMonitorService(
    evm,
    subscriptions,
    auth,
    allocator,
    store,
    preferences,
    logger,
    escrows,
    config,
  );

  @singleton
  KeyValueStorage keyValueStorage(HostrConfig config) => config.keyValueStorage;

  @singleton
  AppDatabase appDatabase(HostrConfig config) => config.appDatabase;

  @singleton
  CommonDatabase operationsDb(HostrConfig config) => config.appDatabase.db;

  @singleton
  CustomLogger logger(HostrConfig config) => config.logger;

  @singleton
  Telemetry telemetry(HostrConfig config) => config.telemetry;

  @singleton
  CalendarPort calendarPort(HostrConfig config) =>
      config.calendarPort ?? const NoopCalendarPort();

  @lazySingleton
  Ndk ndk(HostrConfig config) {
    return Ndk(config.ndkConfig);
  }
}

abstract class Env {
  static const mock = 'mock';
  static const dev = 'dev';
  static const test = 'test';
  static const staging = 'staging';
  static const prod = 'prod';
  static const allButMock = [Env.dev, Env.test, Env.staging, Env.prod];
  static const allButTest = [Env.dev, Env.mock, Env.staging, Env.prod];
  static const allButTestAndMock = [Env.dev, Env.staging, Env.prod];
}
