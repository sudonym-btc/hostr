import 'package:auto_route/auto_route.dart';
import 'package:hostr/core/main.dart';

class GuestGuard extends AutoRouteGuard {
  CustomLogger logger = CustomLogger();
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    logger.d('GuestGuard');
    resolver.next(true);
    return;
  }
}
