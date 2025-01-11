import 'package:auto_route/auto_route.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

class HostGuard extends AutoRouteGuard {
  CustomLogger logger = CustomLogger();
  KeyStorage keyStorage = getIt<KeyStorage>();
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    logger.d('HostGuard');
    resolver.next(true);
    return;
  }
}
