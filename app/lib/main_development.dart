import 'dart:io';

import 'injection.dart';
import 'main.dart';

void main(List<String> args) {
  HttpOverrides.global = MyHttpOverrides();

  mainCommon(Env.dev);
}
