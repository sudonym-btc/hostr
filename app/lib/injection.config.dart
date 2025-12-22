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
import 'package:hostr/data/sources/nostr/nostr/nostr.service.dart' as _i194;
import 'package:hostr/data/sources/nostr/relay_connector.dart' as _i291;
import 'package:hostr/data/sources/rpc/rootstock.dart' as _i631;
import 'package:hostr/injection.dart' as _i490;
import 'package:hostr/logic/cubit/mode.cubit.dart' as _i237;
import 'package:hostr/logic/cubit/payment/bolt11_payment.cubit.dart' as _i993;
import 'package:hostr/logic/cubit/payment/lnurl_payment.cubit.dart' as _i99;
import 'package:hostr/logic/services/nwc.dart' as _i258;
import 'package:hostr/logic/services/payment.dart' as _i151;
import 'package:hostr/logic/services/swap.dart' as _i432;
import 'package:hostr/logic/services/thread_routing_service.dart' as _i346;
import 'package:hostr/logic/services/zap.dart' as _i915;
import 'package:hostr/logic/workflows/auth_workflow.dart' as _i481;
import 'package:hostr/logic/workflows/event_publishing_workflow.dart' as _i338;
import 'package:hostr/logic/workflows/lnurl_workflow.dart' as _i675;
import 'package:hostr/logic/workflows/payment_workflow.dart' as _i558;
import 'package:hostr/logic/workflows/reservation_workflow.dart' as _i66;
import 'package:hostr/logic/workflows/swap_workflow.dart' as _i795;
import 'package:hostr/main.dart' as _i15;
import 'package:injectable/injectable.dart' as _i526;
import 'package:ndk/ndk.dart' as _i857;

const String _dev = 'dev';
const String _test = 'test';
const String _mock = 'mock';
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
    gh.singleton<_i346.ThreadRoutingService>(
      () => _i346.ThreadRoutingService(),
    );
    gh.lazySingleton<_i361.Dio>(() => dioModule.dio());
    gh.factory<_i291.RelayConnector>(() => _i291.ProdRelayConnector());
    gh.factory<_i467.Config>(
      () => _i598.DevelopmentConfig(),
      registerFor: {_dev},
    );
    gh.factory<_i631.Rootstock>(() => _i631.RootstockImpl());
    gh.factory<_i575.GoogleMaps>(
      () => _i575.GoogleMapsMock(),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i194.NostrService>(() => _i194.ProdNostrService());
    gh.singleton<_i311.SecureStorage>(
      () => _i311.MockSecureStorage(),
      registerFor: {_test},
    );
    gh.factory<_i467.Config>(
      () => _i331.MockConfig(),
      registerFor: {_mock, _test},
    );
    gh.factory<_i151.PaymentService>(
      () => _i151.PaymentService(),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factory<_i915.ZapService>(
      () => _i915.ZapService(),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factory<_i575.GoogleMaps>(
      () => _i575.GoogleMapsImpl(),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factory<_i675.LnUrlWorkflow>(
      () => _i675.LnUrlWorkflow(dio: gh<_i361.Dio>()),
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
    gh.singleton<_i303.NwcStorage>(
      () => _i303.NwcStorage(gh<_i311.SecureStorage>()),
    );
    gh.factory<_i66.ReservationWorkflow>(
      () => _i66.ReservationWorkflow(ndk: gh<_i857.Ndk>()),
    );
    gh.singleton<_i432.SwapService>(
      () => _i432.SwapService(gh<_i800.Config>()),
    );
    gh.factory<_i481.AuthWorkflow>(
      () => _i481.AuthWorkflow(
        keyStorage: gh<_i165.KeyStorage>(),
        secureStorage: gh<_i165.SecureStorage>(),
        ndk: gh<_i857.Ndk>(),
      ),
    );
    gh.singleton<_i258.NwcService>(
      () => _i258.MockNostrWalletConnectService(
        gh<_i165.NwcStorage>(),
        gh<_i857.Ndk>(),
      ),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i258.NwcService>(
      () => _i258.NwcService(gh<_i165.NwcStorage>(), gh<_i857.Ndk>()),
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
        nwcService: gh<_i15.NwcService>(),
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
        nwcService: gh<_i15.NwcService>(),
        workflow: gh<_i675.LnUrlWorkflow>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    return this;
  }
}

class _$DioModule extends _i490.DioModule {}
