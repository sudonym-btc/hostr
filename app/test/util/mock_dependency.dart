import 'package:get_it/get_it.dart';

final _getIt = GetIt.instance;

void mockDependency<T extends Object>(T mockObject) {
  if (_getIt.isRegistered<T>()) {
    _getIt.unregister<T>();
  }
  _getIt.registerSingleton<T>(mockObject);
}

void resetDependencies() {
  _getIt.reset();
}
