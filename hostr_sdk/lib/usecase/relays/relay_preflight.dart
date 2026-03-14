import 'relay_preflight_stub.dart'
    if (dart.library.io) 'relay_preflight_native.dart'
    as impl;

Future<void> warmUpRelayConnection(String url) =>
    impl.warmUpRelayConnection(url);
