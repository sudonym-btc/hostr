import 'package:auto_route/auto_route.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class GuestGuard extends AutoRouteGuard {
  CustomLogger logger = CustomLogger();
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    logger.d('GuestGuard');
    resolver.next(true);
    return;
  }
}
