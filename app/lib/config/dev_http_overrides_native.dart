import 'dart:io';

import 'http_overrides.dart';

void configureDevelopmentHttpOverrides() {
  HttpOverrides.global = MyHttpOverrides();
}
