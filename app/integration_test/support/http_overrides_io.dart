import 'dart:io';

import 'package:hostr/config/http_overrides.dart';

void configureTestHttpOverrides() {
  HttpOverrides.global = MyHttpOverrides();
}
