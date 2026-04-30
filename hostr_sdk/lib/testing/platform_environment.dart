import 'platform_environment_stub.dart'
    if (dart.library.io) 'platform_environment_io.dart'
    as impl;

String? platformEnvironment(String key) => impl.platformEnvironment(key);

bool get platformIsBrowser => impl.platformIsBrowser;
