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
import 'package:hostr_sdk/datasources/boltz/boltz.dart' as _i350;
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
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys.dart'
    as _i149;
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys_impl.dart'
    as _i1020;
import 'package:hostr_sdk/usecase/escrow/escrow.dart' as _i376;
import 'package:hostr_sdk/usecase/escrow/operations/claim/escrow_claim_models.dart'
    as _i676;
import 'package:hostr_sdk/usecase/escrow/operations/claim/escrow_claim_operation.dart'
    as _i654;
import 'package:hostr_sdk/usecase/escrow/operations/fund/escrow_fund_models.dart'
    as _i560;
import 'package:hostr_sdk/usecase/escrow/operations/fund/escrow_fund_operation.dart'
    as _i832;
import 'package:hostr_sdk/usecase/escrow/operations/fund/escrow_fund_recoverer.dart'
    as _i787;
import 'package:hostr_sdk/usecase/escrow/operations/fund/escrow_fund_registry.dart'
    as _i608;
import 'package:hostr_sdk/usecase/escrow/operations/release/escrow_release_models.dart'
    as _i526;
import 'package:hostr_sdk/usecase/escrow/operations/release/escrow_release_operation.dart'
    as _i460;
import 'package:hostr_sdk/usecase/escrow_methods/escrows_methods.dart' as _i445;
import 'package:hostr_sdk/usecase/escrow_trusts/escrow_trusts.dart' as _i943;
import 'package:hostr_sdk/usecase/escrows/escrows.dart' as _i303;
import 'package:hostr_sdk/usecase/evm/chain/rootstock/operations/swap_in/swap_in_operation.dart'
    as _i62;
import 'package:hostr_sdk/usecase/evm/chain/rootstock/operations/swap_out/swap_out_operation.dart'
    as _i458;
import 'package:hostr_sdk/usecase/evm/chain/rootstock/rif_relay/rif_relay.dart'
    as _i514;
import 'package:hostr_sdk/usecase/evm/chain/rootstock/rootstock.dart' as _i158;
import 'package:hostr_sdk/usecase/evm/evm.dart' as _i305;
import 'package:hostr_sdk/usecase/evm/main.dart' as _i785;
import 'package:hostr_sdk/usecase/evm/operations/auto_withdraw/auto_withdraw_service.dart'
    as _i503;
import 'package:hostr_sdk/usecase/evm/operations/operation_state_store.dart'
    as _i842;
import 'package:hostr_sdk/usecase/evm/operations/swap_in/swap_in_models.dart'
    as _i677;
import 'package:hostr_sdk/usecase/evm/operations/swap_out/swap_out_quote_service.dart'
    as _i148;
import 'package:hostr_sdk/usecase/evm/operations/swap_recoverer.dart' as _i249;
import 'package:hostr_sdk/usecase/gift_wraps/gift_wraps.dart' as _i308;
import 'package:hostr_sdk/usecase/heartbeat/heartbeat.dart' as _i175;
import 'package:hostr_sdk/usecase/listings/listings.dart' as _i906;
import 'package:hostr_sdk/usecase/location/location.dart' as _i56;
import 'package:hostr_sdk/usecase/messaging/messaging.dart' as _i1019;
import 'package:hostr_sdk/usecase/messaging/thread/thread.dart' as _i378;
import 'package:hostr_sdk/usecase/messaging/threads.dart' as _i768;
import 'package:hostr_sdk/usecase/metadata/metadata.dart' as _i149;
import 'package:hostr_sdk/usecase/nwc/nwc.cubit.dart' as _i613;
import 'package:hostr_sdk/usecase/nwc/nwc.dart' as _i588;
import 'package:hostr_sdk/usecase/payments/operations/bolt11_operation.dart'
    as _i124;
import 'package:hostr_sdk/usecase/payments/operations/lnurl_operation.dart'
    as _i363;
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart' as _i24;
import 'package:hostr_sdk/usecase/payments/payments.dart' as _i226;
import 'package:hostr_sdk/usecase/relays/relays.dart' as _i883;
import 'package:hostr_sdk/usecase/requests/in_memory.requests.dart' as _i286;
import 'package:hostr_sdk/usecase/requests/requests.dart' as _i1014;
import 'package:hostr_sdk/usecase/reservation_pairs/reservation_pairs.dart'
    as _i966;
import 'package:hostr_sdk/usecase/reservation_requests/reservation_requests.dart'
    as _i49;
import 'package:hostr_sdk/usecase/reservation_transitions/reservation_transitions.dart'
    as _i826;
import 'package:hostr_sdk/usecase/reservations/reservations.dart' as _i326;
import 'package:hostr_sdk/usecase/reviews/reviews.dart' as _i660;
import 'package:hostr_sdk/usecase/storage/storage.dart' as _i218;
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_allocator.dart'
    as _i1068;
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_allocator_impl.dart'
    as _i698;
import 'package:hostr_sdk/usecase/trade_audit/trade_audit.dart' as _i179;
import 'package:hostr_sdk/usecase/trades/actions/payment.dart' as _i395;
import 'package:hostr_sdk/usecase/trades/actions/reservation.dart' as _i949;
import 'package:hostr_sdk/usecase/trades/actions/reservation_request.dart'
    as _i814;
import 'package:hostr_sdk/usecase/trades/actions/review.dart' as _i558;
import 'package:hostr_sdk/usecase/trades/payment_proof_orchestrator.dart'
    as _i850;
import 'package:hostr_sdk/usecase/trades/trade.dart' as _i981;
import 'package:hostr_sdk/usecase/user_config/user_config_store.dart' as _i794;
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart'
    as _i576;
import 'package:hostr_sdk/usecase/verification/verification.dart' as _i301;
import 'package:hostr_sdk/usecase/zaps/zaps.dart' as _i1045;
import 'package:hostr_sdk/util/custom_logger.dart' as _i331;
import 'package:hostr_sdk/util/main.dart' as _i372;
import 'package:hostr_sdk/util/telemetry.dart' as _i337;
import 'package:injectable/injectable.dart' as _i526;
import 'package:ndk/ndk.dart' as _i857;
import 'package:sqlite3/common.dart' as _i216;
import 'package:web3dart/web3dart.dart' as _i641;

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
    gh.factory<_i148.SwapOutQuoteService>(() => _i148.SwapOutQuoteService());
    gh.singleton<_i910.HostrConfig>(() => hostrSdkModule.hostrConfig);
    gh.singleton<_i111.KeyValueStorage>(() => hostrSdkModule.keyValueStorage);
    gh.singleton<_i216.CommonDatabase>(() => hostrSdkModule.operationsDb);
    gh.singleton<_i331.CustomLogger>(() => hostrSdkModule.logger);
    gh.singleton<_i337.Telemetry>(() => hostrSdkModule.telemetry);
    gh.singleton<_i733.CalendarPort>(() => hostrSdkModule.calendarPort);
    gh.lazySingleton<_i857.Ndk>(
      () => hostrSdkModule.ndk(gh<_i910.HostrConfig>()),
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
    gh.singleton<_i259.AuthIdentityResolver>(
      () => _i259.AuthIdentityResolver(logger: gh<_i331.CustomLogger>()),
    );
    gh.singleton<_i56.Location>(
      () => _i56.Location(logger: gh<_i331.CustomLogger>()),
    );
    gh.singleton<_i824.BlossomUseCase>(
      () => _i824.BlossomUseCase(
        ndk: gh<_i857.Ndk>(),
        config: gh<_i910.HostrConfig>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i1000.Auth>(
      () => _i1000.Auth(
        ndk: gh<_i857.Ndk>(),
        authStorage: gh<_i218.AuthStorage>(),
        logger: gh<_i372.CustomLogger>(),
        identityResolver: gh<_i259.AuthIdentityResolver>(),
      ),
    );
    gh.singleton<_i218.RelayStorage>(
      () => _i218.RelayStorage(gh<_i910.HostrConfig>(), gh<_i1000.Auth>()),
    );
    gh.singleton<_i218.NwcStorage>(
      () => _i218.NwcStorage(gh<_i910.HostrConfig>(), gh<_i1000.Auth>()),
    );
    gh.singleton<_i883.Relays>(
      () => _i883.MockRelays(
        ndk: gh<_i857.Ndk>(),
        relayStorage: gh<_i218.RelayStorage>(),
        logger: gh<_i372.CustomLogger>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i1014.Requests>(
      () => _i286.InMemoryRequests(
        ndk: gh<_i857.Ndk>(),
        auth: gh<_i1000.Auth>(),
        logger: gh<_i372.CustomLogger>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i608.EscrowFundRegistry>(
      () => _i608.EscrowFundRegistry(gh<_i331.CustomLogger>()),
    );
    gh.singleton<_i842.OperationStateStore>(
      () => _i842.OperationStateStore(
        gh<_i216.CommonDatabase>(),
        gh<_i331.CustomLogger>(),
        gh<_i1000.Auth>(),
      ),
    );
    gh.singleton<_i149.DeterministicKeys>(
      () => _i1020.DeterministicKeysImpl(
        auth: gh<_i1000.Auth>(),
        logger: gh<_i331.CustomLogger>(),
      ),
    );
    gh.factoryParam<_i514.RifRelay, _i641.Web3Client, _i910.RifRelayConfig>(
      (client, rifRelayConfig) => _i514.RifRelay(
        gh<_i910.HostrConfig>(),
        client,
        rifRelayConfig,
        gh<_i372.CustomLogger>(),
      ),
    );
    gh.factory<_i350.BoltzClient>(
      () =>
          _i350.BoltzClient(gh<_i910.HostrConfig>(), gh<_i372.CustomLogger>()),
    );
    gh.singleton<_i794.UserConfigStore>(
      () => _i794.UserConfigStore(
        gh<_i111.KeyValueStorage>(),
        gh<_i331.CustomLogger>(),
        gh<_i1000.Auth>(),
      ),
    );
    gh.factory<_i249.SwapRecoverer>(
      () => _i249.SwapRecoverer(
        gh<_i785.OperationStateStore>(),
        gh<_i1000.Auth>(),
        gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i883.Relays>(
      () => _i883.Relays(
        ndk: gh<_i857.Ndk>(),
        relayStorage: gh<_i218.RelayStorage>(),
        logger: gh<_i372.CustomLogger>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i588.Nwc>(
      () => _i588.MockNwc(
        gh<_i218.NwcStorage>(),
        gh<_i857.Ndk>(),
        gh<_i331.CustomLogger>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i1014.Requests>(
      () => _i1014.Requests(
        ndk: gh<_i857.Ndk>(),
        logger: gh<_i372.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i826.ReservationTransitions>(
      () => _i826.ReservationTransitions(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
        ndk: gh<_i857.Ndk>(),
      ),
    );
    gh.singleton<_i1045.Zaps>(
      () => _i1045.MockZaps(nwc: gh<_i588.Nwc>(), ndk: gh<_i857.Ndk>()),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i308.GiftWraps>(
      () => _i308.GiftWraps(
        ndk: gh<_i857.Ndk>(),
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i588.Nwc>(
      () => _i588.Nwc(
        gh<_i218.NwcStorage>(),
        gh<_i857.Ndk>(),
        gh<_i331.CustomLogger>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i158.Rootstock>(
      () => _i158.Rootstock(
        config: gh<_i910.HostrConfig>(),
        auth: gh<_i1000.Auth>(),
        logger: gh<_i331.CustomLogger>(),
      ),
    );
    gh.singleton<_i149.MetadataUseCase>(
      () => _i149.MetadataUseCase(
        auth: gh<_i1000.Auth>(),
        ndk: gh<_i857.Ndk>(),
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i305.Evm>(
      () => _i305.Evm(
        rootstock: gh<_i158.Rootstock>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i503.AutoWithdrawService>(
      () => _i503.AutoWithdrawService(
        gh<_i305.Evm>(),
        gh<_i842.OperationStateStore>(),
        gh<_i794.UserConfigStore>(),
        gh<_i910.HostrConfig>(),
        gh<_i331.CustomLogger>(),
      ),
    );
    gh.singleton<_i92.BadgeAwards>(
      () => _i92.BadgeAwards(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i978.BadgeDefinitions>(
      () => _i978.BadgeDefinitions(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i906.Listings>(
      () => _i906.Listings(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.factory<_i613.NwcCubit>(
      () => _i613.NwcCubit(
        nwc: gh<_i588.Nwc>(),
        logger: gh<_i331.CustomLogger>(),
        url: gh<String>(),
      ),
    );
    gh.singleton<_i1019.Messaging>(
      () => _i1019.Messaging(
        gh<_i857.Ndk>(),
        gh<_i1014.Requests>(),
        gh<_i331.CustomLogger>(),
      ),
    );
    gh.singleton<_i445.EscrowMethods>(
      () => _i445.EscrowMethods(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i331.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
      ),
    );
    gh.singleton<_i943.EscrowTrusts>(
      () => _i943.EscrowTrusts(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i331.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
      ),
    );
    gh.singleton<_i175.Heartbeats>(
      () => _i175.Heartbeats(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
      ),
    );
    gh.factoryParam<_i363.LnurlPayOperation, _i24.LnurlPayParameters, dynamic>(
      (params, _) => _i363.LnurlPayOperation(
        params: params,
        nwc: gh<_i588.Nwc>(),
        logger: gh<_i372.CustomLogger>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factoryParam<
      _i124.Bolt11PayOperation,
      _i24.Bolt11PayParameters,
      dynamic
    >(
      (params, _) => _i124.Bolt11PayOperation(
        params: params,
        nwc: gh<_i588.Nwc>(),
        logger: gh<_i331.CustomLogger>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i326.Reservations>(
      () => _i326.Reservations(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
        messaging: gh<_i1019.Messaging>(),
        auth: gh<_i1000.Auth>(),
        transitions: gh<_i826.ReservationTransitions>(),
        listings: gh<_i906.Listings>(),
      ),
    );
    gh.singleton<_i1045.Zaps>(
      () => _i1045.Zaps(nwc: gh<_i588.Nwc>(), ndk: gh<_i857.Ndk>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factoryParam<_i62.RootstockSwapInOperation, _i677.SwapInParams, dynamic>(
      (params, _) => _i62.RootstockSwapInOperation(
        rootstock: gh<_i158.Rootstock>(),
        auth: gh<_i1000.Auth>(),
        logger: gh<_i372.CustomLogger>(),
        params: params,
      ),
    );
    gh.singleton<_i376.EscrowUseCase>(
      () => _i376.EscrowUseCase(
        logger: gh<_i372.CustomLogger>(),
        evm: gh<_i305.Evm>(),
        escrowFundRegistry: gh<_i608.EscrowFundRegistry>(),
      ),
    );
    gh.singleton<_i179.TradeAudit>(
      () => _i179.TradeAudit(
        reservations: gh<_i326.Reservations>(),
        transitions: gh<_i826.ReservationTransitions>(),
        listings: gh<_i906.Listings>(),
        logger: gh<_i372.CustomLogger>(),
        evm: gh<_i305.Evm>(),
      ),
    );
    gh.singleton<_i303.Escrows>(
      () => _i303.Escrows(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
        escrowMethods: gh<_i445.EscrowMethods>(),
        escrowTrusts: gh<_i943.EscrowTrusts>(),
      ),
    );
    gh.singleton<_i226.Payments>(
      () => _i226.Payments(
        zaps: gh<_i1045.Zaps>(),
        nwc: gh<_i588.Nwc>(),
        logger: gh<_i331.CustomLogger>(),
        metadata: gh<_i149.MetadataUseCase>(),
        auth: gh<_i1000.Auth>(),
      ),
    );
    gh.singleton<_i660.Reviews>(
      () => _i660.Reviews(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
        reservations: gh<_i326.Reservations>(),
        listings: gh<_i906.Listings>(),
      ),
    );
    gh.singleton<_i966.ReservationPairs>(
      () => _i966.ReservationPairs(
        reservations: gh<_i326.Reservations>(),
        logger: gh<_i372.CustomLogger>(),
        evm: gh<_i305.Evm>(),
      ),
    );
    gh.singleton<_i1068.TradeAccountAllocator>(
      () => _i698.TradeAccountAllocatorImpl(
        auth: gh<_i1000.Auth>(),
        hd: gh<_i149.DeterministicKeys>(),
        evm: gh<_i305.Evm>(),
        reservations: gh<_i326.Reservations>(),
        logger: gh<_i331.CustomLogger>(),
      ),
    );
    gh.singleton<_i49.ReservationRequests>(
      () => _i49.ReservationRequests(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        tradeAccountAllocator: gh<_i1068.TradeAccountAllocator>(),
      ),
    );
    gh.factoryParam<
      _i460.EscrowReleaseOperation,
      _i526.EscrowReleaseParams,
      dynamic
    >(
      (params, _) => _i460.EscrowReleaseOperation(
        gh<_i1000.Auth>(),
        gh<_i1068.TradeAccountAllocator>(),
        gh<_i785.Evm>(),
        gh<_i331.CustomLogger>(),
        params,
      ),
    );
    gh.factoryParam<
      _i654.EscrowClaimOperation,
      _i676.EscrowClaimParams,
      dynamic
    >(
      (params, _) => _i654.EscrowClaimOperation(
        gh<_i1000.Auth>(),
        gh<_i1068.TradeAccountAllocator>(),
        gh<_i785.Evm>(),
        gh<_i331.CustomLogger>(),
        params,
      ),
    );
    gh.factoryParam<
      _i458.RootstockSwapOutOperation,
      _i785.SwapOutParams,
      dynamic
    >(
      (params, _) => _i458.RootstockSwapOutOperation(
        rootstock: gh<_i785.Rootstock>(),
        auth: gh<_i1000.Auth>(),
        logger: gh<_i372.CustomLogger>(),
        nwc: gh<_i588.Nwc>(),
        quoteService: gh<_i785.SwapOutQuoteService>(),
        payments: gh<_i226.Payments>(),
        params: params,
      ),
    );
    gh.factoryParam<
      _i832.EscrowFundOperation,
      _i560.EscrowFundParams?,
      dynamic
    >(
      (params, _) => _i832.EscrowFundOperation(
        gh<_i1000.Auth>(),
        gh<_i1068.TradeAccountAllocator>(),
        gh<_i785.Evm>(),
        gh<_i331.CustomLogger>(),
        params,
      ),
    );
    gh.singleton<_i576.UserSubscriptions>(
      () => _i576.UserSubscriptions(
        auth: gh<_i1000.Auth>(),
        giftWraps: gh<_i308.GiftWraps>(),
        heartbeats: gh<_i175.Heartbeats>(),
        reservations: gh<_i326.Reservations>(),
        transitions: gh<_i826.ReservationTransitions>(),
        reservationPairs: gh<_i966.ReservationPairs>(),
        reviews: gh<_i660.Reviews>(),
        zaps: gh<_i1045.Zaps>(),
        escrow: gh<_i376.EscrowUseCase>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.factory<_i787.EscrowFundRecoverer>(
      () => _i787.EscrowFundRecoverer(
        gh<_i842.OperationStateStore>(),
        gh<_i1000.Auth>(),
        gh<_i1068.TradeAccountAllocator>(),
        gh<_i305.Evm>(),
        gh<_i372.CustomLogger>(),
        gh<_i608.EscrowFundRegistry>(),
      ),
    );
    gh.singleton<_i768.Threads>(
      () => _i768.Threads(
        userSubscriptions: gh<_i576.UserSubscriptions>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i733.Calendar>(
      () => _i733.Calendar(
        userSubscriptions: gh<_i576.UserSubscriptions>(),
        listings: gh<_i906.Listings>(),
        metadata: gh<_i149.MetadataUseCase>(),
        logger: gh<_i331.CustomLogger>(),
        port: gh<_i733.CalendarPort>(),
      ),
    );
    gh.singleton<_i843.BackgroundWorker>(
      () => _i843.BackgroundWorker(
        auth: gh<_i1000.Auth>(),
        userSubscriptions: gh<_i576.UserSubscriptions>(),
        heartbeats: gh<_i175.Heartbeats>(),
        evm: gh<_i305.Evm>(),
        autoWithdraw: gh<_i503.AutoWithdrawService>(),
        listings: gh<_i906.Listings>(),
        metadata: gh<_i149.MetadataUseCase>(),
        operationStore: gh<_i842.OperationStateStore>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.factoryParam<_i378.Thread, String, dynamic>(
      (anchor, _) => _i378.Thread(
        anchor,
        logger: gh<_i331.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        messaging: gh<_i1019.Messaging>(),
        userSubscriptions: gh<_i576.UserSubscriptions>(),
      ),
    );
    gh.singleton<_i850.PaymentProofOrchestrator>(
      () => _i850.PaymentProofOrchestrator(
        userSubs: gh<_i576.UserSubscriptions>(),
        threads: gh<_i768.Threads>(),
        auth: gh<_i1000.Auth>(),
        reservations: gh<_i326.Reservations>(),
        listings: gh<_i906.Listings>(),
        metadata: gh<_i149.MetadataUseCase>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.factoryParam<_i981.Trade, String, String>(
      (tradeId, listingAnchor) => _i981.Trade(
        tradeId: tradeId,
        listingAnchor: listingAnchor,
        logger: gh<_i331.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        listings: gh<_i906.Listings>(),
        metadata: gh<_i149.MetadataUseCase>(),
        userSubscriptions: gh<_i576.UserSubscriptions>(),
        reservationPairs: gh<_i966.ReservationPairs>(),
        threads: gh<_i768.Threads>(),
      ),
    );
    gh.factory<_i949.ReservationActions>(
      () => _i949.ReservationActions(
        trade: gh<_i981.Trade>(),
        reservations: gh<_i326.Reservations>(),
      ),
    );
    gh.factory<_i395.PaymentActions>(
      () => _i395.PaymentActions(trade: gh<_i981.Trade>()),
    );
    gh.factory<_i814.ReservationRequestActions>(
      () => _i814.ReservationRequestActions(trade: gh<_i981.Trade>()),
    );
    gh.factory<_i558.ReviewActions>(
      () => _i558.ReviewActions(trade: gh<_i981.Trade>()),
    );
    return this;
  }
}

class _$HostrSdkModule extends _i231.HostrSdkModule {}
