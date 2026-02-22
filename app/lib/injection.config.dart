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
import 'package:hostr/data/sources/api/google_maps.dart' as _i575;
import 'package:hostr/data/sources/h3_engine.dart' as _i175;
import 'package:hostr/data/sources/image_preloader.dart' as _i776;
import 'package:hostr/data/sources/local/mode_storage.dart' as _i640;
import 'package:hostr/data/sources/local/secure_storage.dart' as _i311;
import 'package:hostr/injection.dart' as _i490;
import 'package:hostr/logic/cubit/mode.cubit.dart' as _i237;
import 'package:injectable/injectable.dart' as _i526;
import 'package:models/util/location/h3.dart' as _i854;

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
    gh.lazySingleton<_i776.ImagePreloader>(() => _i776.ImagePreloader());
    gh.lazySingleton<_i361.Dio>(() => dioModule.dio());
    gh.factory<_i467.Config>(() => _i292.TestConfig(), registerFor: {_test});
    gh.factory<_i467.Config>(() => _i331.MockConfig(), registerFor: {_mock});
    gh.singleton<_i854.H3Engine>(() => _i175.H3EngineIml());
    gh.singleton<_i311.SecureStorage>(
      () => _i311.ImplSecureStorage(),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factory<_i467.Config>(
      () => _i598.DevelopmentConfig(),
      registerFor: {_dev},
    );
    gh.factory<_i237.ModeCubit>(
      () => _i237.ModeCubit(modeStorage: gh<_i640.ModeStorage>()),
    );
    gh.factory<_i575.GoogleMaps>(
      () => _i575.GoogleMapsMock(),
      registerFor: {_test, _mock},
    );
    gh.singleton<_i311.SecureStorage>(
      () => _i311.MockSecureStorage(),
      registerFor: {_test, _mock},
    );
    gh.factory<_i575.GoogleMaps>(
      () => _i575.GoogleMapsImpl(),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factory<_i467.Config>(
      () => _i1071.ProductionConfig(),
      registerFor: {_prod},
    );
    return this;
  }
}

class _$DioModule extends _i490.DioModule {}
