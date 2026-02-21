import 'package:h3_flutter/h3_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:models/util/location/h3.dart';

void configureFlutterH3Runtime() {
  setH3FactoryOverride(() => const H3Factory().load());
}

@Singleton(as: H3Engine)
class H3EngineIml extends H3Engine {
  H3EngineIml() : super(const H3Factory().load());
}
