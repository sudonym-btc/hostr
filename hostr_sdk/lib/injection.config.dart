// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:hostr_sdk/config.dart' as _i910;
import 'package:hostr_sdk/datasources/app_database.dart' as _i995;
import 'package:hostr_sdk/datasources/notification_log.dart' as _i226;
import 'package:hostr_sdk/datasources/storage.dart' as _i111;
import 'package:hostr_sdk/injection.dart' as _i231;
import 'package:hostr_sdk/usecase/auth/auth.dart' as _i1000;
import 'package:hostr_sdk/usecase/auth/auth_identity_resolver.dart' as _i259;
import 'package:hostr_sdk/usecase/background_worker/background_worker.dart'
    as _i843;
import 'package:hostr_sdk/usecase/badge_awards/badge_awards.dart' as _i92;
import 'package:hostr_sdk/usecase/badge_definitions/badge_definitions.dart'
    as _i978;
import 'package:hostr_sdk/usecase/blossom/blossom.dart' as _i824;
import 'package:hostr_sdk/usecase/calendar/calendar.dart' as _i733;
import 'package:hostr_sdk/usecase/deterministic_keys/account_seed_store.dart'
    as _i756;
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys.dart'
    as _i150;
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys_impl.dart'
    as _i1020;
import 'package:hostr_sdk/usecase/dm_relays/dm_relays.dart' as _i452;
import 'package:hostr_sdk/usecase/escrow_daemon/escrow_daemon.dart' as _i861;
import 'package:hostr_sdk/usecase/escrow_methods/escrows_methods.dart' as _i445;
import 'package:hostr_sdk/usecase/escrows/escrows.dart' as _i303;
import 'package:hostr_sdk/usecase/gift_wraps/gift_wraps.dart' as _i308;
import 'package:hostr_sdk/usecase/heartbeat/heartbeat.dart' as _i175;
import 'package:hostr_sdk/usecase/listings/listings.dart' as _i906;
import 'package:hostr_sdk/usecase/lnurl/lnurl.dart' as _i908;
import 'package:hostr_sdk/usecase/location/location.dart' as _i56;
import 'package:hostr_sdk/usecase/messaging/messaging.dart' as _i1019;
import 'package:hostr_sdk/usecase/messaging/thread/thread.dart' as _i378;
import 'package:hostr_sdk/usecase/messaging/threads.dart' as _i768;
import 'package:hostr_sdk/usecase/metadata/metadata.dart' as _i149;
import 'package:hostr_sdk/usecase/nwc/nwc.cubit.dart' as _i613;
import 'package:hostr_sdk/usecase/nwc/nwc.dart' as _i588;
import 'package:hostr_sdk/usecase/order_groups/order_groups.dart' as _i493;
import 'package:hostr_sdk/usecase/order_requests/order_requests.dart' as _i916;
import 'package:hostr_sdk/usecase/order_transitions/order_transitions.dart'
    as _i666;
import 'package:hostr_sdk/usecase/orders/orders.dart' as _i227;
import 'package:hostr_sdk/usecase/payments/operations/bolt11_operation.dart'
    as _i124;
import 'package:hostr_sdk/usecase/payments/operations/lnurl_operation.dart'
    as _i363;
import 'package:hostr_sdk/usecase/payments/payments.dart' as _i228;
import 'package:hostr_sdk/usecase/relays/relays.dart' as _i883;
import 'package:hostr_sdk/usecase/requests/in_memory.requests.dart' as _i286;
import 'package:hostr_sdk/usecase/requests/requests.dart' as _i1014;
import 'package:hostr_sdk/usecase/reviews/reviews.dart' as _i660;
import 'package:hostr_sdk/usecase/startup/startup_coordinator.dart' as _i145;
import 'package:hostr_sdk/usecase/startup/startup_core.dart' as _i716;
import 'package:hostr_sdk/usecase/startup/startup_profiles.dart' as _i327;
import 'package:hostr_sdk/usecase/storage/storage.dart' as _i218;
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_allocator_impl.dart'
    as _i698;
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_cache.dart'
    as _i202;
import 'package:hostr_sdk/usecase/trade_audit/trade_audit.dart' as _i179;
import 'package:hostr_sdk/usecase/trades/actions/order.dart' as _i135;
import 'package:hostr_sdk/usecase/trades/actions/order_request.dart' as _i366;
import 'package:hostr_sdk/usecase/trades/actions/payment.dart' as _i395;
import 'package:hostr_sdk/usecase/trades/payment_proof_orchestrator.dart'
    as _i850;
import 'package:hostr_sdk/usecase/trades/trade.dart' as _i981;
import 'package:hostr_sdk/usecase/user_config/user_config_store.dart' as _i794;
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart'
    as _i576;
import 'package:hostr_sdk/usecase/verification/verification.dart' as _i301;
import 'package:hostr_sdk/usecase/zaps/zaps.dart' as _i1045;
import 'package:injectable/injectable.dart' as _i526;
import 'package:marketplace_evm/marketplace_evm.dart' as _i1025;
import 'package:marketplace_evm/usecase/escrow/escrow_verification.dart'
    as _i417;
import 'package:marketplace_evm/usecase/evm/evm.dart' as _i471;
import 'package:marketplace_evm/usecase/payments/operations/pay_models.dart'
    as _i772;
import 'package:marketplace_evm/usecase/trade_account_allocator/trade_account_allocator.dart'
    as _i702;
import 'package:marketplace_evm/util/custom_logger.dart' as _i662;
import 'package:ndk/ndk.dart' as _i857;
import 'package:sqlite3/common.dart' as _i216;

const String _test = 'test';
const String _mock = 'mock';
const String _dev = 'dev';
const String _staging = 'staging';
const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final hostrSdkModule = _$HostrSdkModule();
    gh.lazySingleton<_i857.Ndk>(
      () => hostrSdkModule.ndk(gh<_i910.HostrConfig>()),
    );
    gh.singleton<_i111.KeyValueStorage>(
      () => hostrSdkModule.keyValueStorage(gh<_i910.HostrConfig>()),
    );
    gh.singleton<_i995.AppDatabase>(
      () => hostrSdkModule.appDatabase(gh<_i910.HostrConfig>()),
    );
    gh.singleton<_i216.CommonDatabase>(
      () => hostrSdkModule.operationsDb(gh<_i910.HostrConfig>()),
    );
    gh.singleton<_i1025.CustomLogger>(
      () => hostrSdkModule.logger(gh<_i910.HostrConfig>()),
    );
    gh.singleton<_i1025.Telemetry>(
      () => hostrSdkModule.telemetry(gh<_i910.HostrConfig>()),
    );
    gh.singleton<_i733.CalendarPort>(
      () => hostrSdkModule.calendarPort(gh<_i910.HostrConfig>()),
    );
    gh.singleton<_i218.AuthStorage>(
      () => _i218.AuthStorage(gh<_i910.HostrConfig>()),
    );
    gh.singleton<_i301.Verification>(
      () => _i301.MockVerification(ndk: gh<_i857.Ndk>()),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i301.Verification>(
      () => _i301.Verification(ndk: gh<_i857.Ndk>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factory<_i1025.SwapQuoteService>(
      () => hostrSdkModule.swapQuoteService(gh<_i1025.CustomLogger>()),
    );
    gh.singleton<_i1025.SwapInTracker>(
      () => hostrSdkModule.swapInTracker(gh<_i1025.CustomLogger>()),
    );
    gh.singleton<_i1025.SwapOutTracker>(
      () => hostrSdkModule.swapOutTracker(gh<_i1025.CustomLogger>()),
    );
    gh.singleton<_i908.LnurlUseCase>(
      () => _i908.MockLnurlUseCase(),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i908.LnurlUseCase>(
      () => _i908.LnurlUseCase(),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i259.AuthIdentityResolver>(
      () => _i259.AuthIdentityResolver(logger: gh<_i662.CustomLogger>()),
    );
    gh.singleton<_i56.Location>(
      () => _i56.Location(logger: gh<_i662.CustomLogger>()),
    );
    gh.singleton<_i1000.Auth>(
      () => hostrSdkModule.auth(
        gh<_i857.Ndk>(),
        gh<_i218.AuthStorage>(),
        gh<_i1025.CustomLogger>(),
        gh<_i259.AuthIdentityResolver>(),
        gh<_i231.HostrScope>(),
      ),
    );
    gh.singleton<_i1025.Evm>(
      () => hostrSdkModule.evm(
        gh<_i910.HostrConfig>(),
        gh<_i1000.Auth>(),
        gh<_i1025.CustomLogger>(),
        gh<_i231.HostrScope>(),
      ),
    );
    gh.singleton<_i226.NotificationLog>(
      () => _i226.NotificationLog(gh<_i216.CommonDatabase>()),
    );
    gh.singleton<_i1025.EscrowUseCase>(
      () => hostrSdkModule.escrowUseCase(
        gh<_i1025.CustomLogger>(),
        gh<_i1025.Evm>(),
        gh<_i231.HostrScope>(),
      ),
    );
    gh.singleton<_i1025.OperationStateStore>(
      () => hostrSdkModule.operationStateStore(
        gh<_i216.CommonDatabase>(),
        gh<_i1025.CustomLogger>(),
        gh<_i1000.Auth>(),
      ),
    );
    gh.singleton<_i824.BlossomUseCase>(
      () => _i824.BlossomUseCase(
        ndk: gh<_i857.Ndk>(),
        config: gh<_i910.HostrConfig>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i218.NwcStorage>(
      () => _i218.NwcStorage(gh<_i910.HostrConfig>(), gh<_i1000.Auth>()),
    );
    gh.singleton<_i218.AccountSeedStorage>(
      () =>
          _i218.AccountSeedStorage(gh<_i910.HostrConfig>(), gh<_i1000.Auth>()),
    );
    gh.singleton<_i1014.Requests>(
      () => _i286.InMemoryRequests(
        ndk: gh<_i857.Ndk>(),
        auth: gh<_i1000.Auth>(),
        logger: gh<_i1025.CustomLogger>(),
        config: gh<_i910.HostrConfig>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i1025.EscrowVerification>(
      () => hostrSdkModule.escrowVerification(
        gh<_i1025.Evm>(),
        gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i218.RelayStorage>(
      () => _i218.RelayStorage(
        gh<_i216.CommonDatabase>(),
        gh<_i910.HostrConfig>(),
        gh<_i1000.Auth>(),
      ),
    );
    gh.singleton<_i794.UserConfigStore>(
      () => _i794.UserConfigStore(
        gh<_i216.CommonDatabase>(),
        gh<_i662.CustomLogger>(),
        gh<_i1000.Auth>(),
      ),
    );
    gh.factory<_i1025.SwapRecoverer>(
      () => hostrSdkModule.swapRecoverer(
        gh<_i1025.OperationStateStore>(),
        gh<_i1000.Auth>(),
        gh<_i1025.Evm>(),
        gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i1014.Requests>(
      () => _i1014.Requests(
        ndk: gh<_i857.Ndk>(),
        logger: gh<_i1025.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        config: gh<_i910.HostrConfig>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i883.Relays>(
      () => hostrSdkModule.relays(
        gh<_i857.Ndk>(),
        gh<_i218.RelayStorage>(),
        gh<_i1025.CustomLogger>(),
        gh<_i910.HostrConfig>(),
        gh<_i1014.Requests>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i883.Relays>(
      () => hostrSdkModule.mockRelays(
        gh<_i857.Ndk>(),
        gh<_i218.RelayStorage>(),
        gh<_i1025.CustomLogger>(),
        gh<_i910.HostrConfig>(),
        gh<_i1014.Requests>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i588.Nwc>(
      () => _i588.Nwc(
        gh<_i218.NwcStorage>(),
        gh<_i857.Ndk>(),
        gh<_i662.CustomLogger>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i92.BadgeAwards>(
      () => _i92.BadgeAwards(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i978.BadgeDefinitions>(
      () => _i978.BadgeDefinitions(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i175.Heartbeats>(
      () => _i175.Heartbeats(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
      ),
    );
    gh.singleton<_i445.EscrowMethods>(
      () => _i445.EscrowMethods(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        evm: gh<_i471.Evm>(),
      ),
    );
    gh.singleton<_i588.Nwc>(
      () => _i588.MockNwc(
        gh<_i218.NwcStorage>(),
        gh<_i857.Ndk>(),
        gh<_i662.CustomLogger>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i452.DmRelays>(
      () => _i452.DmRelays(
        ndk: gh<_i857.Ndk>(),
        requests: gh<_i1014.Requests>(),
        relays: gh<_i883.Relays>(),
        auth: gh<_i1000.Auth>(),
        config: gh<_i910.HostrConfig>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i1045.Zaps>(
      () => hostrSdkModule.zaps(
        gh<_i588.Nwc>(),
        gh<_i857.Ndk>(),
        gh<_i910.HostrConfig>(),
        gh<_i1014.Requests>(),
        gh<_i1025.CustomLogger>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i716.StartupCore>(
      () => _i716.StartupCore(relays: gh<_i883.Relays>(), evm: gh<_i471.Evm>()),
    );
    gh.singleton<_i327.BackgroundStartupProfile>(
      () => _i327.BackgroundStartupProfile(
        core: gh<_i716.StartupCore>(),
        auth: gh<_i1000.Auth>(),
        relays: gh<_i883.Relays>(),
      ),
    );
    gh.singleton<_i308.GiftWraps>(
      () => hostrSdkModule.giftWraps(
        gh<_i857.Ndk>(),
        gh<_i1014.Requests>(),
        gh<_i1025.CustomLogger>(),
        gh<_i910.HostrConfig>(),
      ),
    );
    gh.singleton<_i149.MetadataUseCase>(
      () => _i149.MetadataUseCase(
        ndk: gh<_i857.Ndk>(),
        relays: gh<_i883.Relays>(),
        escrowMethods: gh<_i445.EscrowMethods>(),
        blossom: gh<_i824.BlossomUseCase>(),
        evm: gh<_i471.Evm>(),
        config: gh<_i910.HostrConfig>(),
        requests: gh<_i1014.Requests>(),
        logger: gh<_i662.CustomLogger>(),
      ),
    );
    gh.singleton<_i756.AccountSeedStore>(
      () => _i756.AccountSeedStore(
        auth: gh<_i1000.Auth>(),
        ndk: gh<_i857.Ndk>(),
        requests: gh<_i1014.Requests>(),
        storage: gh<_i218.AccountSeedStorage>(),
        logger: gh<_i1025.CustomLogger>(),
        config: gh<_i910.HostrConfig>(),
      ),
    );
    gh.singleton<_i666.OrderTransitions>(
      () => _i666.OrderTransitions(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
        ndk: gh<_i857.Ndk>(),
      ),
    );
    gh.lazySingleton<_i1025.EvmNwc>(
      () => hostrSdkModule.evmNwc(gh<_i588.Nwc>()),
    );
    gh.singleton<_i1019.Messaging>(
      () => hostrSdkModule.messaging(
        gh<_i857.Ndk>(),
        gh<_i1014.Requests>(),
        gh<_i452.DmRelays>(),
        gh<_i1025.CustomLogger>(),
        gh<_i910.HostrConfig>(),
        gh<_i883.Relays>(),
        gh<_i231.HostrScope>(),
      ),
    );
    gh.singleton<_i303.Escrows>(
      () => _i303.Escrows(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
        escrowMethods: gh<_i445.EscrowMethods>(),
      ),
    );
    gh.factory<_i613.NwcCubit>(
      () => _i613.NwcCubit(
        nwc: gh<_i588.Nwc>(),
        logger: gh<_i662.CustomLogger>(),
        url: gh<String>(),
      ),
    );
    gh.singleton<_i906.Listings>(
      () => _i906.Listings(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
        metadata: gh<_i149.MetadataUseCase>(),
      ),
    );
    gh.singleton<_i1045.Zaps>(
      () => hostrSdkModule.mockZaps(
        gh<_i588.Nwc>(),
        gh<_i857.Ndk>(),
        gh<_i910.HostrConfig>(),
        gh<_i1014.Requests>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.factoryParam<
      _i124.Bolt11PayOperation,
      _i772.Bolt11PayParameters,
      dynamic
    >(
      (params, _) => _i124.Bolt11PayOperation(
        params: params,
        nwc: gh<_i1025.EvmNwc>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factoryParam<
      _i363.LnurlPayOperation,
      _i1025.LnurlPayParameters,
      dynamic
    >(
      (params, _) => _i363.LnurlPayOperation(
        params: params,
        lnurl: gh<_i908.LnurlUseCase>(),
        nwc: gh<_i1025.EvmNwc>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i327.PublicStartupProfile>(
      () => _i327.PublicStartupProfile(core: gh<_i716.StartupCore>()),
    );
    gh.singleton<_i227.Orders>(
      () => _i227.Orders(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
        messaging: gh<_i1019.Messaging>(),
        auth: gh<_i1000.Auth>(),
        transitions: gh<_i666.OrderTransitions>(),
        listings: gh<_i906.Listings>(),
        relays: gh<_i883.Relays>(),
      ),
    );
    gh.singleton<_i150.DeterministicKeys>(
      () => _i1020.DeterministicKeysImpl(
        auth: gh<_i1000.Auth>(),
        seedStore: gh<_i756.AccountSeedStore>(),
        logger: gh<_i662.CustomLogger>(),
      ),
    );
    gh.singleton<_i660.Reviews>(
      () => _i660.Reviews(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
        orders: gh<_i227.Orders>(),
        listings: gh<_i906.Listings>(),
        escrowVerification: gh<_i417.EscrowVerification>(),
      ),
    );
    gh.singleton<_i179.TradeAudit>(
      () => _i179.TradeAudit(
        orders: gh<_i227.Orders>(),
        transitions: gh<_i666.OrderTransitions>(),
        listings: gh<_i906.Listings>(),
        logger: gh<_i1025.CustomLogger>(),
        evm: gh<_i1025.Evm>(),
      ),
    );
    gh.singleton<_i228.Payments>(
      () => _i228.Payments(
        zaps: gh<_i1045.Zaps>(),
        nwc: gh<_i588.Nwc>(),
        lnurl: gh<_i908.LnurlUseCase>(),
        logger: gh<_i662.CustomLogger>(),
        metadata: gh<_i149.MetadataUseCase>(),
        auth: gh<_i1000.Auth>(),
        config: gh<_i910.HostrConfig>(),
      ),
    );
    gh.singleton<_i493.OrderGroups>(
      () => _i493.OrderGroups(
        orders: gh<_i227.Orders>(),
        logger: gh<_i1025.CustomLogger>(),
        evm: gh<_i1025.Evm>(),
      ),
    );
    gh.singleton<_i576.UserSubscriptions>(
      () => _i576.UserSubscriptions(
        auth: gh<_i1000.Auth>(),
        giftWraps: gh<_i308.GiftWraps>(),
        heartbeats: gh<_i175.Heartbeats>(),
        orders: gh<_i227.Orders>(),
        transitions: gh<_i666.OrderTransitions>(),
        orderGroups: gh<_i493.OrderGroups>(),
        reviews: gh<_i660.Reviews>(),
        zaps: gh<_i1045.Zaps>(),
        escrow: gh<_i1025.EscrowUseCase>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i202.TradeAccountCache>(
      () => _i202.TradeAccountCache(
        auth: gh<_i1000.Auth>(),
        hd: gh<_i150.DeterministicKeys>(),
        logger: gh<_i662.CustomLogger>(),
      ),
    );
    gh.singleton<_i733.Calendar>(
      () => _i733.Calendar(
        userSubscriptions: gh<_i576.UserSubscriptions>(),
        listings: gh<_i906.Listings>(),
        metadata: gh<_i149.MetadataUseCase>(),
        logger: gh<_i662.CustomLogger>(),
        port: gh<_i733.CalendarPort>(),
      ),
    );
    gh.factoryParam<
      _i1025.EvmChain,
      _i1025.EvmChainConfig,
      _i1025.AACapability?
    >(
      (config, aa) => hostrSdkModule.evmChain(
        config,
        aa,
        gh<_i1000.Auth>(),
        gh<_i1025.CustomLogger>(),
        gh<_i1025.SwapQuoteService>(),
        gh<_i588.Nwc>(),
        gh<_i228.Payments>(),
      ),
    );
    gh.factoryParam<_i378.Thread, String, dynamic>(
      (anchor, _) => _i378.Thread(
        anchor,
        logger: gh<_i662.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        messaging: gh<_i1019.Messaging>(),
        userSubscriptions: gh<_i576.UserSubscriptions>(),
      ),
    );
    gh.singleton<_i861.EscrowDaemon>(
      () => _i861.EscrowDaemon(
        auth: gh<_i1000.Auth>(),
        evm: gh<_i1025.Evm>(),
        listings: gh<_i906.Listings>(),
        metadata: gh<_i149.MetadataUseCase>(),
        messaging: gh<_i1019.Messaging>(),
        escrows: gh<_i303.Escrows>(),
        orders: gh<_i227.Orders>(),
        userSubscriptions: gh<_i576.UserSubscriptions>(),
        escrowVerification: gh<_i1025.EscrowVerification>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i768.Threads>(
      () => hostrSdkModule.threads(
        gh<_i1000.Auth>(),
        gh<_i576.UserSubscriptions>(),
        gh<_i1025.CustomLogger>(),
        gh<_i231.HostrScope>(),
      ),
    );
    gh.singleton<_i1025.TradeAccountAllocator>(
      () => _i698.TradeAccountAllocatorImpl(
        auth: gh<_i1000.Auth>(),
        hd: gh<_i150.DeterministicKeys>(),
        evm: gh<_i1025.Evm>(),
        orders: gh<_i227.Orders>(),
        threads: gh<_i768.Threads>(),
        cache: gh<_i202.TradeAccountCache>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i850.PaymentProofOrchestrator>(
      () => hostrSdkModule.paymentProofOrchestrator(
        gh<_i576.UserSubscriptions>(),
        gh<_i768.Threads>(),
        gh<_i1000.Auth>(),
        gh<_i227.Orders>(),
        gh<_i906.Listings>(),
        gh<_i149.MetadataUseCase>(),
        gh<_i1025.CustomLogger>(),
        gh<_i910.HostrConfig>(),
        gh<_i1025.TradeAccountAllocator>(),
      ),
    );
    gh.factoryParam<
      _i1025.EscrowFundPreparer,
      _i1025.EscrowFundParams?,
      dynamic
    >(
      (params, _) => hostrSdkModule.escrowFundPreparer(
        params,
        gh<_i1000.Auth>(),
        gh<_i1025.TradeAccountAllocator>(),
        gh<_i1025.Evm>(),
        gh<_i1025.SwapQuoteService>(),
        gh<_i1025.CustomLogger>(),
      ),
    );
    gh.factoryParam<
      _i1025.EscrowClaimOperation,
      _i1025.EscrowClaimParams,
      dynamic
    >(
      (params, _) => hostrSdkModule.escrowClaimOperation(
        params,
        gh<_i1000.Auth>(),
        gh<_i1025.TradeAccountAllocator>(),
        gh<_i1025.Evm>(),
        gh<_i1025.CustomLogger>(),
      ),
    );
    gh.factoryParam<
      _i1025.EscrowReleaseOperation,
      _i1025.EscrowReleaseParams,
      dynamic
    >(
      (params, _) => hostrSdkModule.escrowReleaseOperation(
        params,
        gh<_i1000.Auth>(),
        gh<_i1025.TradeAccountAllocator>(),
        gh<_i1025.Evm>(),
        gh<_i1025.CustomLogger>(),
      ),
    );
    gh.singleton<_i1025.FundsMonitorService>(
      () => hostrSdkModule.fundsMonitorService(
        gh<_i1025.Evm>(),
        gh<_i576.UserSubscriptions>(),
        gh<_i1000.Auth>(),
        gh<_i1025.TradeAccountAllocator>(),
        gh<_i1025.OperationStateStore>(),
        gh<_i794.UserConfigStore>(),
        gh<_i1025.CustomLogger>(),
        gh<_i303.Escrows>(),
        gh<_i910.HostrConfig>(),
      ),
    );
    gh.singleton<_i916.OrderRequests>(
      () => _i916.OrderRequests(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i1025.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        tradeAccountAllocator: gh<_i702.TradeAccountAllocator>(),
        relays: gh<_i883.Relays>(),
      ),
    );
    gh.singleton<_i843.BackgroundWorker>(
      () => _i843.BackgroundWorker(
        auth: gh<_i1000.Auth>(),
        userSubscriptions: gh<_i576.UserSubscriptions>(),
        heartbeats: gh<_i175.Heartbeats>(),
        evm: gh<_i1025.Evm>(),
        fundsMonitor: gh<_i1025.FundsMonitorService>(),
        listings: gh<_i906.Listings>(),
        metadata: gh<_i149.MetadataUseCase>(),
        operationStore: gh<_i1025.OperationStateStore>(),
        notificationLog: gh<_i226.NotificationLog>(),
        logger: gh<_i1025.CustomLogger>(),
      ),
    );
    gh.factoryParam<_i981.Trade, _i981.TradeContext, dynamic>(
      (context, _) => _i981.Trade(
        context: context,
        logger: gh<_i662.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        listings: gh<_i906.Listings>(),
        metadata: gh<_i149.MetadataUseCase>(),
        escrowMethods: gh<_i445.EscrowMethods>(),
        userSubscriptions: gh<_i576.UserSubscriptions>(),
        orderGroups: gh<_i493.OrderGroups>(),
        threads: gh<_i768.Threads>(),
        tradeAccountAllocator: gh<_i702.TradeAccountAllocator>(),
        orderRequests: gh<_i916.OrderRequests>(),
        orders: gh<_i227.Orders>(),
      ),
    );
    gh.factory<_i135.OrderActions>(
      () => _i135.OrderActions(
        trade: gh<_i981.Trade>(),
        orders: gh<_i227.Orders>(),
      ),
    );
    gh.singleton<_i327.UserStartupProfile>(
      () => _i327.UserStartupProfile(
        core: gh<_i716.StartupCore>(),
        auth: gh<_i1000.Auth>(),
        config: gh<_i910.HostrConfig>(),
        relays: gh<_i883.Relays>(),
        accountSeedStore: gh<_i756.AccountSeedStore>(),
        metadata: gh<_i149.MetadataUseCase>(),
        listings: gh<_i906.Listings>(),
        userSubscriptions: gh<_i576.UserSubscriptions>(),
        paymentProofOrchestrator: gh<_i850.PaymentProofOrchestrator>(),
        fundsMonitor: gh<_i1025.FundsMonitorService>(),
        nwc: gh<_i588.Nwc>(),
        backgroundWorker: gh<_i843.BackgroundWorker>(),
        calendar: gh<_i733.Calendar>(),
        messaging: gh<_i1019.Messaging>(),
        orders: gh<_i227.Orders>(),
      ),
    );
    gh.singleton<_i145.StartupCoordinator>(
      () => _i145.StartupCoordinator(
        auth: gh<_i1000.Auth>(),
        publicProfile: gh<_i327.PublicStartupProfile>(),
        userProfile: gh<_i327.UserStartupProfile>(),
        backgroundProfile: gh<_i327.BackgroundStartupProfile>(),
      ),
    );
    gh.factory<_i366.OrderRequestActions>(
      () => _i366.OrderRequestActions(trade: gh<_i981.Trade>()),
    );
    gh.factory<_i395.PaymentActions>(
      () => _i395.PaymentActions(trade: gh<_i981.Trade>()),
    );
    return this;
  }
}

class _$HostrSdkModule extends _i231.HostrSdkModule {}
