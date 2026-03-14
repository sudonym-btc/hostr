import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createPlatformHttpClient() =>
    IOClient(HttpClient()..idleTimeout = const Duration(seconds: 10));
