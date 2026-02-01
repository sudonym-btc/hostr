// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hostr/config/env/base.config.dart' as _i467;
import 'package:hostr/config/env/development.config.dart' as _i598;
import 'package:hostr/config/env/mock.config.dart' as _i331;
import 'package:hostr/config/env/production.config.dart' as _i1071;
import 'package:hostr/config/env/test.config.dart' as _i292;
import 'package:hostr/config/main.dart' as _i800;
import 'package:hostr/data/main.dart' as _i165;
import 'package:hostr/data/sources/api/google_maps.dart' as _i575;
import 'package:hostr/data/sources/boltz/boltz.dart' as _i428;
import 'package:hostr/data/sources/local/key_storage.dart' as _i946;
import 'package:hostr/data/sources/local/mode_storage.dart' as _i640;
import 'package:hostr/data/sources/local/nwc_storage.dart' as _i303;
import 'package:hostr/data/sources/local/relay_storage.dart' as _i315;
import 'package:hostr/data/sources/local/secure_storage.dart' as _i311;
import 'package:hostr/data/sources/nostr/ndk.dart' as _i396;
import 'package:hostr/data/sources/nostr/nostr/hostr.dart' as _i552;
import 'package:hostr/data/sources/nostr/nostr/usecase/auth/auth.dart' as _i34;
import 'package:hostr/data/sources/nostr/nostr/usecase/badge_awards/badge_awards.dart'
    as _i232;
import 'package:hostr/data/sources/nostr/nostr/usecase/badge_definitions/badge_definitions.dart'
    as _i558;
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow_methods/escrows_methods.dart'
    as _i291;
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow_trusts/escrows_trusts.dart'
    as _i445;
import 'package:hostr/data/sources/nostr/nostr/usecase/escrows/escrows.dart'
    as _i42;
import 'package:hostr/data/sources/nostr/nostr/usecase/evm/evm.dart' as _i961;
import 'package:hostr/data/sources/nostr/nostr/usecase/listings/listings.dart'
    as _i456;
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging/messaging.dart'
    as _i463;
import 'package:hostr/data/sources/nostr/nostr/usecase/metadata/metadata.dart'
    as _i249;
import 'package:hostr/data/sources/nostr/nostr/usecase/nwc/nwc.dart' as _i909;
import 'package:hostr/data/sources/nostr/nostr/usecase/payments/payments.dart'
    as _i244;
import 'package:hostr/data/sources/nostr/nostr/usecase/relays/relays.dart'
    as _i886;
import 'package:hostr/data/sources/nostr/nostr/usecase/requests/requests.dart'
    as _i100;
import 'package:hostr/data/sources/nostr/nostr/usecase/requests/test.requests.dart'
    as _i805;
import 'package:hostr/data/sources/nostr/nostr/usecase/reservation_requests/reservation_requests.dart'
    as _i525;
import 'package:hostr/data/sources/nostr/nostr/usecase/reservations/reservations.dart'
    as _i489;
import 'package:hostr/data/sources/nostr/nostr/usecase/swap/swap.dart' as _i443;
import 'package:hostr/data/sources/nostr/nostr/usecase/zaps/zaps.dart' as _i735;
import 'package:hostr/export.dart' as _i1012;
import 'package:hostr/injection.dart' as _i490;
import 'package:hostr/logic/cubit/mode.cubit.dart' as _i237;
import 'package:hostr/logic/cubit/payment/bolt11_payment.cubit.dart' as _i993;
import 'package:hostr/logic/cubit/payment/lnurl_payment.cubit.dart' as _i99;
import 'package:hostr/logic/services/session_coordinator.dart' as _i126;
import 'package:hostr/logic/workflows/event_publishing_workflow.dart' as _i338;
import 'package:hostr/logic/workflows/lnurl_workflow.dart' as _i675;
import 'package:hostr/logic/workflows/payment_workflow.dart' as _i558;
import 'package:hostr/logic/workflows/swap_workflow.dart' as _i795;
import 'package:hostr/main.dart' as _i15;
import 'package:injectable/injectable.dart' as _i526;
import 'package:ndk/ndk.dart' as _i857;

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
    final dioModule = _$DioModule();
    gh.factory<_i640.ModeStorage>(() => _i640.ModeStorage());
    gh.factory<_i315.RelayStorage>(() => _i315.RelayStorage());
    gh.factory<_i338.EventPublishingWorkflow>(
      () => _i338.EventPublishingWorkflow(),
    );
    gh.factory<_i558.PaymentWorkflow>(() => _i558.PaymentWorkflow());
    gh.factory<_i795.SwapWorkflow>(() => _i795.SwapWorkflow());
    gh.singleton<_i946.KeyStorage>(() => _i946.KeyStorage());
    gh.lazySingleton<_i361.Dio>(() => dioModule.dio());
    gh.factory<_i467.Config>(() => _i292.TestConfig(), registerFor: {_test});
    gh.factory<_i467.Config>(() => _i331.MockConfig(), registerFor: {_mock});
    gh.factory<_i467.Config>(
      () => _i598.DevelopmentConfig(),
      registerFor: {_dev},
    );
    gh.factory<_i575.GoogleMaps>(
      () => _i575.GoogleMapsMock(),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i311.SecureStorage>(
      () => _i311.MockSecureStorage(),
      registerFor: {_test},
    );
    gh.factory<_i575.GoogleMaps>(
      () => _i575.GoogleMapsImpl(),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factory<_i675.LnUrlWorkflow>(
      () => _i675.MockLnUrlWorkflow(dio: gh<_i361.Dio>()),
      registerFor: {_test, _mock},
    );
    gh.factory<_i467.Config>(
      () => _i1071.ProductionConfig(),
      registerFor: {_prod},
    );
    gh.factory<_i428.BoltzClient>(() => _i428.BoltzClient(gh<_i800.Config>()));
    gh.factory<_i237.ModeCubit>(
      () => _i237.ModeCubit(modeStorage: gh<_i640.ModeStorage>()),
    );
    gh.singleton<_i857.Ndk>(() => _i396.NostrNdk(gh<_i800.Config>()));
    gh.singleton<_i311.SecureStorage>(
      () => _i311.ImplSecureStorage(),
      registerFor: {_dev, _mock, _staging, _prod},
    );
    gh.factory<_i675.LnUrlWorkflow>(
      () => _i675.LnUrlWorkflow(dio: gh<_i361.Dio>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i100.Requests>(
      () => _i100.Requests(ndk: gh<_i857.Ndk>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i552.Hostr>(() => _i552.ProdHostr(gh<_i857.Ndk>()));
    gh.singleton<_i100.Requests>(
      () => _i805.TestRequests(ndk: gh<_i857.Ndk>()),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i34.Auth>(
      () => _i34.Auth(
        ndk: gh<_i857.Ndk>(),
        keyStorage: gh<_i1012.KeyStorage>(),
        secureStorage: gh<_i1012.SecureStorage>(),
      ),
    );
    gh.singleton<_i463.Messaging>(
      () => _i463.Messaging(gh<_i857.Ndk>(), gh<_i100.Requests>()),
    );
    gh.singleton<_i303.NwcStorage>(
      () => _i303.NwcStorage(gh<_i311.SecureStorage>()),
    );
    gh.singleton<_i232.BadgeAwards>(
      () => _i232.BadgeAwards(requests: gh<_i100.Requests>()),
    );
    gh.singleton<_i558.BadgeDefinitions>(
      () => _i558.BadgeDefinitions(requests: gh<_i100.Requests>()),
    );
    gh.singleton<_i291.EscrowMethods>(
      () => _i291.EscrowMethods(requests: gh<_i100.Requests>()),
    );
    gh.singleton<_i456.Listings>(
      () => _i456.Listings(requests: gh<_i100.Requests>()),
    );
    gh.singleton<_i886.Relays>(
      () => _i886.MockRelays(
        ndk: gh<_i857.Ndk>(),
        relayStorage: gh<_i15.RelayStorage>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i445.EscrowTrusts>(
      () => _i445.EscrowTrusts(
        requests: gh<_i100.Requests>(),
        auth: gh<_i34.Auth>(),
      ),
    );
    gh.singleton<_i886.Relays>(
      () => _i886.Relays(
        ndk: gh<_i857.Ndk>(),
        relayStorage: gh<_i15.RelayStorage>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i42.Escrows>(
      () => _i42.Escrows(
        requests: gh<_i100.Requests>(),
        escrowMethods: gh<_i291.EscrowMethods>(),
        escrowTrusts: gh<_i445.EscrowTrusts>(),
      ),
    );
    gh.singleton<_i489.Reservations>(
      () => _i489.Reservations(
        requests: gh<_i100.Requests>(),
        messaging: gh<_i463.Messaging>(),
        auth: gh<_i34.Auth>(),
      ),
    );
    gh.singleton<_i909.Nwc>(
      () => _i909.Nwc(gh<_i165.NwcStorage>(), gh<_i857.Ndk>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.singleton<_i249.MetadataUseCase>(
      () => _i249.MetadataUseCase(
        auth: gh<_i34.Auth>(),
        requests: gh<_i100.Requests>(),
      ),
    );
    gh.singleton<_i909.Nwc>(
      () => _i909.MockNwc(gh<_i165.NwcStorage>(), gh<_i857.Ndk>()),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i525.ReservationRequests>(
      () => _i525.ReservationRequests(
        requests: gh<_i100.Requests>(),
        ndk: gh<_i857.Ndk>(),
      ),
    );
    gh.singleton<_i735.Zaps>(
      () => _i735.MockZaps(nwc: gh<_i909.Nwc>(), ndk: gh<_i857.Ndk>()),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i961.Evm>(() => _i961.Evm(auth: gh<_i34.Auth>()));
    gh.singleton<_i443.Swap>(() => _i443.Swap(auth: gh<_i34.Auth>()));
    gh.singleton<_i735.Zaps>(
      () => _i735.Zaps(nwc: gh<_i909.Nwc>(), ndk: gh<_i857.Ndk>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factoryParam<
      _i99.LnUrlPaymentCubit,
      _i99.LnUrlPaymentParameters,
      dynamic
    >(
      (params, _) => _i99.LnUrlPaymentCubit(
        params: params,
        workflow: gh<_i675.LnUrlWorkflow>(),
        nwc: gh<_i909.Nwc>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factoryParam<
      _i993.Bolt11PaymentCubit,
      _i993.Bolt11PaymentParameters,
      dynamic
    >(
      (params, _) => _i993.Bolt11PaymentCubit(
        params: params,
        nwc: gh<_i909.Nwc>(),
        workflow: gh<_i675.LnUrlWorkflow>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.lazySingleton<_i126.SessionCoordinator>(
      () => _i126.SessionCoordinator(
        config: gh<_i1012.Config>(),
        auth: gh<_i34.Auth>(),
        metadataUseCase: gh<_i249.MetadataUseCase>(),
      ),
    );
    gh.singleton<_i244.Payments>(
      () => _i244.Payments(
        auth: gh<_i34.Auth>(),
        escrows: gh<_i42.Escrows>(),
        zaps: gh<_i735.Zaps>(),
        nwc: gh<_i909.Nwc>(),
      ),
    );
    return this;
  }
}

class _$DioModule extends _i490.DioModule {}
