import 'package:injectable/injectable.dart';
import 'package:models/util/location/h3.dart';

@Singleton(as: H3Engine)
class H3EngineIml extends H3Engine {
  H3EngineIml() : super(createOptimalH3());
}
