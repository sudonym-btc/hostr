// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:hostr/config/env/base.config.dart' as _i467;
import 'package:hostr/config/env/development.config.dart' as _i598;
import 'package:hostr/config/env/mock.config.dart' as _i331;
import 'package:hostr/config/env/production.config.dart' as _i1071;
import 'package:hostr/data/repositories/nostr/escrow.repository.dart' as _i911;
import 'package:hostr/data/repositories/nostr/listing.repository.dart' as _i631;
import 'package:hostr/data/repositories/nostr/message.repository.dart' as _i723;
import 'package:hostr/data/repositories/nostr/profile.repository.dart' as _i788;
import 'package:hostr/data/repositories/nostr/zap.repository.dart' as _i61;
import 'package:hostr/data/sources/api/google_maps.dart' as _i575;
import 'package:hostr/data/sources/local/key_storage.dart' as _i946;
import 'package:hostr/data/sources/local/nwc_storage.dart' as _i303;
import 'package:hostr/data/sources/local/relay_storage.dart' as _i315;
import 'package:hostr/data/sources/local/secure_storage.dart' as _i311;
import 'package:hostr/data/sources/nostr/nostr_provider/mock.nostr_provider.dart'
    as _i200;
import 'package:hostr/data/sources/nostr/nostr_provider/nostr_provider.dart'
    as _i788;
import 'package:hostr/data/sources/nostr/relay_connector.dart' as _i291;
import 'package:hostr/data/sources/rpc/rootstock.dart' as _i631;
import 'package:hostr/logic/cubit/auth.cubit.dart' as _i323;
import 'package:hostr/logic/services/nostr_wallet_connect.dart' as _i771;
import 'package:hostr/logic/services/payment.dart' as _i151;
import 'package:hostr/logic/services/request_delegation.dart' as _i942;
import 'package:hostr/logic/services/swap.dart' as _i432;
import 'package:hostr/logic/services/zap.dart' as _i915;
import 'package:injectable/injectable.dart' as _i526;

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
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<_i323.AuthCubit>(() => _i323.AuthCubit());
    gh.factory<_i942.RequestDelegation>(() => _i942.RequestDelegation());
    gh.factory<_i315.RelayStorage>(() => _i315.RelayStorage());
    gh.factory<_i303.NwcStorage>(() => _i303.NwcStorage());
    gh.factory<_i946.KeyStorage>(() => _i946.KeyStorage());
    gh.factory<_i771.NostrWalletConnectService>(
      () => _i771.MockNostrWalletConnectService(),
      registerFor: {
        _test,
        _mock,
      },
    );
    gh.factory<_i291.RelayConnector>(
      () => _i291.MockRelayConnector(),
      registerFor: {_mock},
    );
    gh.factory<_i788.ProfileRepository>(() => _i788.ProdProfileRepository());
    gh.singleton<_i788.NostrProvider>(
      () => _i200.MockNostProvider(),
      registerFor: {
        _mock,
        _test,
      },
    );
    gh.factory<_i631.ListingRepository>(() => _i631.ProdListingRepository());
    gh.factory<_i467.Config>(
      () => _i331.MockConfig(),
      registerFor: {_mock},
    );
    gh.factory<_i723.MessageRepository>(() => _i723.ProdMessageRepository());
    gh.factory<_i61.ZapRepository>(() => _i61.ProdZapRepository());
    gh.factory<_i467.Config>(
      () => _i598.DevelopmentConfig(),
      registerFor: {_dev},
    );
    gh.factory<_i631.Rootstock>(() => _i631.RootstockImpl());
    gh.factory<_i575.GoogleMaps>(
      () => _i575.GoogleMapsMock(),
      registerFor: {
        _test,
        _mock,
      },
    );
    gh.singleton<_i788.NostrProvider>(
      () => _i788.ProdNostrProvider(),
      registerFor: {
        _dev,
        _staging,
        _prod,
      },
    );
    gh.singleton<_i311.SecureStorage>(
      () => _i311.MockSecureStorage(),
      registerFor: {_test},
    );
    gh.factory<_i771.NostrWalletConnectService>(
      () => _i771.NostrWalletConnectService(),
      registerFor: {
        _dev,
        _staging,
        _prod,
      },
    );
    gh.factory<_i151.PaymentService>(
      () => _i151.PaymentService(),
      registerFor: {
        _dev,
        _staging,
        _prod,
      },
    );
    gh.factory<_i432.SwapService>(
      () => _i432.SwapService(),
      registerFor: {
        _dev,
        _staging,
        _prod,
      },
    );
    gh.factory<_i915.ZapService>(
      () => _i915.ZapService(),
      registerFor: {
        _dev,
        _staging,
        _prod,
      },
    );
    gh.factory<_i911.EscrowRepository>(() => _i911.ProdEscrowRepository());
    gh.factory<_i575.GoogleMaps>(
      () => _i575.GoogleMapsImpl(),
      registerFor: {
        _dev,
        _staging,
        _prod,
      },
    );
    gh.singleton<_i942.UrlLauncher>(
      () => _i942.MockUrlLauncher(),
      registerFor: {_test},
    );
    gh.factory<_i291.RelayConnector>(
      () => _i291.ProdRelayConnector(),
      registerFor: {
        _dev,
        _test,
        _staging,
        _prod,
      },
    );
    gh.factory<_i467.Config>(
      () => _i1071.ProductionConfig(),
      registerFor: {_prod},
    );
    gh.singleton<_i942.UrlLauncher>(
      () => _i942.ImplUrlLauncher(),
      registerFor: {
        _dev,
        _mock,
        _staging,
        _prod,
      },
    );
    gh.singleton<_i311.SecureStorage>(
      () => _i311.ImplSecureStorage(),
      registerFor: {
        _dev,
        _mock,
        _staging,
        _prod,
      },
    );
    return this;
  }
}
