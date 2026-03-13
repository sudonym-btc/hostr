import 'dev_http_overrides_stub.dart'
    if (dart.library.io) 'dev_http_overrides_native.dart'
    as impl;

void configureDevelopmentHttpOverrides() =>
    impl.configureDevelopmentHttpOverrides();
