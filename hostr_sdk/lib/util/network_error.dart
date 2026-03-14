import 'network_error_stub.dart'
    if (dart.library.io) 'network_error_native.dart'
    as impl;

bool isPlatformSocketException(Object error) =>
    impl.isPlatformSocketException(error);
