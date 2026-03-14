import 'config/dev_http_overrides.dart';
import 'injection.dart';
import 'main.dart';

void main(List<String> args) {
  configureDevelopmentHttpOverrides();

  mainCommon(Env.dev);
}
