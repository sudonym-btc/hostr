import 'package:http/http.dart' as http;

import 'http_client_factory_stub.dart'
    if (dart.library.io) 'http_client_factory_native.dart'
    as impl;

http.Client createPlatformHttpClient() => impl.createPlatformHttpClient();
