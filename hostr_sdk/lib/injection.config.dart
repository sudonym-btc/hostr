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
import 'package:hostr_sdk/hostr_sdk.dart' as _i520;
import 'package:hostr_sdk/injection.dart' as _i231;
import 'package:hostr_sdk/usecase/auth/auth.dart' as _i1000;
import 'package:hostr_sdk/usecase/badge_awards/badge_awards.dart' as _i92;
import 'package:hostr_sdk/usecase/badge_definitions/badge_definitions.dart'
    as _i978;
import 'package:hostr_sdk/usecase/escrow/escrow.dart' as _i376;
import 'package:hostr_sdk/usecase/escrow/operations/claim/escrow_claim_operation.dart'
    as _i654;
import 'package:hostr_sdk/usecase/escrow/operations/fund/escrow_fund_operation.dart'
    as _i832;
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
import 'package:hostr_sdk/usecase/evm/operations/swap_in/swap_in_models.dart'
    as _i677;
import 'package:hostr_sdk/usecase/listings/listings.dart' as _i906;
import 'package:hostr_sdk/usecase/location/location.dart' as _i56;
import 'package:hostr_sdk/usecase/messaging/messaging.dart' as _i1019;
import 'package:hostr_sdk/usecase/messaging/thread/actions/payment.dart'
    as _i374;
import 'package:hostr_sdk/usecase/messaging/thread/actions/reservation.dart'
    as _i455;
import 'package:hostr_sdk/usecase/messaging/thread/actions/reservation_request.dart'
    as _i799;
import 'package:hostr_sdk/usecase/messaging/thread/actions/review.dart'
    as _i914;
import 'package:hostr_sdk/usecase/messaging/thread/payment_proof_orchestrator.dart'
    as _i636;
import 'package:hostr_sdk/usecase/messaging/thread/thread.dart' as _i378;
import 'package:hostr_sdk/usecase/messaging/thread/trade.dart' as _i475;
import 'package:hostr_sdk/usecase/messaging/thread/trade_subscriptions.dart'
    as _i802;
import 'package:hostr_sdk/usecase/messaging/threads.dart' as _i768;
import 'package:hostr_sdk/usecase/metadata/metadata.dart' as _i149;
import 'package:hostr_sdk/usecase/nwc/nwc.dart' as _i588;
import 'package:hostr_sdk/usecase/payments/operations/bolt11_operation.dart'
    as _i124;
import 'package:hostr_sdk/usecase/payments/operations/lnurl_operation.dart'
    as _i363;
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart' as _i24;
import 'package:hostr_sdk/usecase/payments/payments.dart' as _i226;
import 'package:hostr_sdk/usecase/relays/relays.dart' as _i883;
import 'package:hostr_sdk/usecase/requests/requests.dart' as _i1014;
import 'package:hostr_sdk/usecase/requests/test.requests.dart' as _i200;
import 'package:hostr_sdk/usecase/reservation_requests/reservation_requests.dart'
    as _i49;
import 'package:hostr_sdk/usecase/reservations/reservations.dart' as _i326;
import 'package:hostr_sdk/usecase/reviews/reviews.dart' as _i660;
import 'package:hostr_sdk/usecase/storage/storage.dart' as _i218;
import 'package:hostr_sdk/usecase/zaps/zaps.dart' as _i1045;
import 'package:hostr_sdk/util/custom_logger.dart' as _i331;
import 'package:hostr_sdk/util/main.dart' as _i372;
import 'package:injectable/injectable.dart' as _i526;
import 'package:ndk/ndk.dart' as _i857;
import 'package:web3dart/web3dart.dart' as _i641;

const String _dev = 'dev';
const String _staging = 'staging';
const String _prod = 'prod';
const String _test = 'test';
const String _mock = 'mock';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final hostrSdkModule = _$HostrSdkModule();
    gh.singleton<_i910.HostrConfig>(() => hostrSdkModule.hostrConfig);
    gh.singleton<_i331.CustomLogger>(() => hostrSdkModule.logger);
    gh.singleton<_i857.Ndk>(() => hostrSdkModule.ndk(gh<_i910.HostrConfig>()));
    gh.singleton<_i218.AuthStorage>(
      () => _i218.AuthStorage(gh<_i910.HostrConfig>()),
    );
    gh.singleton<_i1014.Requests>(
      () => _i1014.Requests(ndk: gh<_i857.Ndk>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i158.Rootstock>(
      () => _i158.Rootstock(
        config: gh<_i910.HostrConfig>(),
        logger: gh<_i331.CustomLogger>(),
      ),
    );
    gh.singleton<_i56.Location>(
      () => _i56.Location(logger: gh<_i331.CustomLogger>()),
    );
    gh.singleton<_i1014.Requests>(
      () => _i200.TestRequests(ndk: gh<_i857.Ndk>()),
      registerFor: {_test, _mock},
    );
    gh.factoryParam<_i514.RifRelay, _i641.Web3Client, dynamic>(
      (client, _) => _i514.RifRelay(
        gh<_i910.HostrConfig>(),
        client,
        gh<_i331.CustomLogger>(),
      ),
    );
    gh.factory<_i350.BoltzClient>(
      () =>
          _i350.BoltzClient(gh<_i910.HostrConfig>(), gh<_i372.CustomLogger>()),
    );
    gh.singleton<_i1000.Auth>(
      () => _i1000.Auth(
        ndk: gh<_i857.Ndk>(),
        authStorage: gh<_i218.AuthStorage>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i1019.Messaging>(
      () => _i1019.Messaging(
        gh<_i857.Ndk>(),
        gh<_i1014.Requests>(),
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
    gh.singleton<_i445.EscrowMethods>(
      () => _i445.EscrowMethods(
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
    gh.singleton<_i660.Reviews>(
      () => _i660.Reviews(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
      ),
    );
    gh.singleton<_i218.RelayStorage>(
      () => _i218.RelayStorage(gh<_i910.HostrConfig>(), gh<_i1000.Auth>()),
    );
    gh.singleton<_i218.NwcStorage>(
      () => _i218.NwcStorage(gh<_i910.HostrConfig>(), gh<_i1000.Auth>()),
    );
    gh.singleton<_i883.Relays>(
      () => _i883.Relays(
        ndk: gh<_i857.Ndk>(),
        relayStorage: gh<_i218.RelayStorage>(),
        logger: gh<_i372.CustomLogger>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factoryParam<_i62.RootstockSwapInOperation, _i677.SwapInParams, dynamic>(
      (params, _) => _i62.RootstockSwapInOperation(
        rootstock: gh<_i158.Rootstock>(),
        auth: gh<_i520.Auth>(),
        logger: gh<_i372.CustomLogger>(),
        params: params,
      ),
    );
    gh.singleton<_i943.EscrowTrusts>(
      () => _i943.EscrowTrusts(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
      ),
    );
    gh.singleton<_i588.Nwc>(
      () => _i588.MockNwc(
        gh<_i218.NwcStorage>(),
        gh<_i857.Ndk>(),
        gh<_i331.CustomLogger>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i305.Evm>(
      () => _i305.Evm(
        auth: gh<_i1000.Auth>(),
        rootstock: gh<_i158.Rootstock>(),
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
    gh.factoryParam<_i363.LnurlPayOperation, _i24.LnurlPayParameters, dynamic>(
      (params, _) =>
          _i363.LnurlPayOperation(params: params, nwc: gh<_i588.Nwc>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i883.Relays>(
      () => _i883.MockRelays(
        ndk: gh<_i857.Ndk>(),
        relayStorage: gh<_i218.RelayStorage>(),
        logger: gh<_i372.CustomLogger>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i49.ReservationRequests>(
      () => _i49.ReservationRequests(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
        ndk: gh<_i857.Ndk>(),
        auth: gh<_i1000.Auth>(),
      ),
    );
    gh.factoryParam<_i378.Thread, String, dynamic>(
      (anchor, _) => _i378.Thread(
        anchor,
        logger: gh<_i520.CustomLogger>(),
        auth: gh<_i520.Auth>(),
        messaging: gh<_i520.Messaging>(),
      ),
    );
    gh.factoryParam<_i832.EscrowFundOperation, _i520.EscrowFundParams, dynamic>(
      (params, _) => _i832.EscrowFundOperation(
        gh<_i520.Auth>(),
        gh<_i520.Evm>(),
        gh<_i520.CustomLogger>(),
        params,
      ),
    );
    gh.singleton<_i1045.Zaps>(
      () => _i1045.MockZaps(nwc: gh<_i520.Nwc>(), ndk: gh<_i857.Ndk>()),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i326.Reservations>(
      () => _i326.Reservations(
        requests: gh<_i1014.Requests>(),
        logger: gh<_i372.CustomLogger>(),
        messaging: gh<_i1019.Messaging>(),
        auth: gh<_i1000.Auth>(),
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
        params: params,
      ),
    );
    gh.singleton<_i149.MetadataUseCase>(
      () => _i149.MetadataUseCase(
        auth: gh<_i520.Auth>(),
        requests: gh<_i520.Requests>(),
        logger: gh<_i520.CustomLogger>(),
      ),
    );
    gh.singleton<_i1045.Zaps>(
      () => _i1045.Zaps(nwc: gh<_i520.Nwc>(), ndk: gh<_i857.Ndk>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factoryParam<
      _i636.ThreadPaymentProofOrchestrator,
      _i520.ThreadTrade,
      _i520.TradeSubscriptions
    >(
      (trade, subscriptions) => _i636.ThreadPaymentProofOrchestrator(
        trade: trade,
        subscriptions: subscriptions,
        auth: gh<_i520.Auth>(),
        reservations: gh<_i520.Reservations>(),
        logger: gh<_i520.CustomLogger>(),
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
    gh.factoryParam<
      _i654.EscrowClaimOperation,
      _i520.EscrowClaimParams,
      dynamic
    >(
      (params, _) => _i654.EscrowClaimOperation(
        gh<_i520.Auth>(),
        gh<_i520.Evm>(),
        gh<_i520.CustomLogger>(),
        gh<_i520.Rootstock>(),
        params,
      ),
    );
    gh.factoryParam<
      _i124.Bolt11PayOperation,
      _i24.Bolt11PayParameters,
      dynamic
    >(
      (params, _) =>
          _i124.Bolt11PayOperation(params: params, nwc: gh<_i588.Nwc>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i376.EscrowUseCase>(
      () => _i376.EscrowUseCase(
        logger: gh<_i372.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        escrows: gh<_i303.Escrows>(),
        escrowTrusts: gh<_i943.EscrowTrusts>(),
        evm: gh<_i305.Evm>(),
      ),
    );
    gh.factoryParam<_i475.ThreadTrade, _i378.Thread, dynamic>(
      (thread, _) => _i475.ThreadTrade(
        thread: thread,
        logger: gh<_i331.CustomLogger>(),
        auth: gh<_i1000.Auth>(),
        listings: gh<_i906.Listings>(),
        metadata: gh<_i149.MetadataUseCase>(),
      ),
    );
    gh.factory<_i374.PaymentActions>(
      () => _i374.PaymentActions(trade: gh<_i520.ThreadTrade>()),
    );
    gh.factory<_i799.ReservationRequestActions>(
      () => _i799.ReservationRequestActions(trade: gh<_i520.ThreadTrade>()),
    );
    gh.factory<_i914.ReviewActions>(
      () => _i914.ReviewActions(trade: gh<_i520.ThreadTrade>()),
    );
    gh.factoryParam<_i802.TradeSubscriptions, _i520.Thread, dynamic>(
      (thread, _) => _i802.TradeSubscriptions(
        thread: thread,
        logger: gh<_i520.CustomLogger>(),
        reservations: gh<_i520.Reservations>(),
        zaps: gh<_i520.Zaps>(),
        escrow: gh<_i520.EscrowUseCase>(),
        reviews: gh<_i520.Reviews>(),
      ),
    );
    gh.factory<_i455.ReservationActions>(
      () => _i455.ReservationActions(
        trade: gh<_i520.ThreadTrade>(),
        reservations: gh<_i520.Reservations>(),
      ),
    );
    gh.singleton<_i226.Payments>(
      () => _i226.Payments(
        zaps: gh<_i520.Zaps>(),
        nwc: gh<_i520.Nwc>(),
        logger: gh<_i520.CustomLogger>(),
        escrow: gh<_i520.EscrowUseCase>(),
      ),
    );
    gh.singleton<_i768.Threads>(
      () => _i768.Threads(
        messaging: gh<_i1019.Messaging>(),
        requests: gh<_i1014.Requests>(),
        auth: gh<_i1000.Auth>(),
        logger: gh<_i372.CustomLogger>(),
        payments: gh<_i226.Payments>(),
      ),
    );
    return this;
  }
}

class _$HostrSdkModule extends _i231.HostrSdkModule {}
