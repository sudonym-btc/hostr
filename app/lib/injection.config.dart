// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:hostr/config/env/base.config.dart' as _i198;
import 'package:hostr/config/env/development.config.dart' as _i273;
import 'package:hostr/config/env/mock.config.dart' as _i659;
import 'package:hostr/config/env/production.config.dart' as _i319;
import 'package:hostr/data/repositories/nostr/escrow.repository.dart' as _i641;
import 'package:hostr/data/repositories/nostr/listing.repository.dart' as _i279;
import 'package:hostr/data/repositories/nostr/message.repository.dart' as _i694;
import 'package:hostr/data/repositories/nostr/profile.repository.dart' as _i752;
import 'package:hostr/data/sources/api/google_maps.dart' as _i148;
import 'package:hostr/data/sources/local/secure_storage.dart' as _i731;
import 'package:hostr/data/sources/nostr/nostr_provider/mock.nostr_provider.dart'
    as _i900;
import 'package:hostr/data/sources/nostr/nostr_provider/nostr_provider.dart'
    as _i452;
import 'package:hostr/data/sources/nostr/relay_connector.dart' as _i188;
import 'package:hostr/data/sources/rpc/rootstock.dart' as _i935;
import 'package:hostr/logic/cubit/auth.cubit.dart' as _i978;
import 'package:hostr/logic/services/request_delegation.dart' as _i420;
import 'package:injectable/injectable.dart' as _i526;

const String _mock = 'mock';
const String _test = 'test';
const String _dev = 'dev';
const String _staging = 'staging';
const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<_i978.AuthCubit>(() => _i978.AuthCubit());
    gh.factory<_i420.RequestDelegation>(() => _i420.RequestDelegation());
    gh.factory<_i752.ProfileRepository>(() => _i752.ProdProfileRepository());
    gh.singleton<_i452.NostrProvider>(
      () => _i900.MockNostProvider(),
      registerFor: {
        _mock,
        _test,
      },
    );
    gh.factory<_i148.GoogleMaps>(() => _i148.GoogleMapsImpl());
    gh.factory<_i188.RelayConnector>(
      () => _i188.MockRelayConnector(),
      registerFor: {_mock},
    );
    gh.factory<_i935.Rootstock>(() => _i935.RootstockImpl());
    gh.singleton<_i452.NostrProvider>(
      () => _i452.ProdNostrProvider(),
      registerFor: {
        _dev,
        _staging,
        _prod,
      },
    );
    gh.factory<_i198.Config>(
      () => _i273.DevelopmentConfig(),
      registerFor: {_dev},
    );
    gh.singleton<_i420.UrlLauncher>(
      () => _i420.MockUrlLauncher(),
      registerFor: {_test},
    );
    gh.factory<_i279.ListingRepository>(() => _i279.ProdListingRepository());
    gh.factory<_i694.MessageRepository>(() => _i694.ProdMessageRepository());
    gh.factory<_i198.Config>(
      () => _i659.MockConfig(),
      registerFor: {_mock},
    );
    gh.singleton<_i731.SecureStorage>(
      () => _i731.MockSecureStorage(),
      registerFor: {_test},
    );
    gh.factory<_i641.EscrowRepository>(() => _i641.ProdEscrowRepository());
    gh.factory<_i188.RelayConnector>(
      () => _i188.ProdRelayConnector(),
      registerFor: {
        _dev,
        _test,
        _staging,
        _prod,
      },
    );
    gh.singleton<_i731.SecureStorage>(
      () => _i731.ImplSecureStorage(),
      registerFor: {
        _dev,
        _mock,
        _staging,
        _prod,
      },
    );
    gh.singleton<_i420.UrlLauncher>(
      () => _i420.ImplUrlLauncher(),
      registerFor: {
        _dev,
        _mock,
        _staging,
        _prod,
      },
    );
    gh.factory<_i198.Config>(
      () => _i319.ProductionConfig(),
      registerFor: {_prod},
    );
    return this;
  }
}
