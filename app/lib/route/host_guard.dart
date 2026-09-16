import 'package:marketplace_evm/marketplace_evm.dart';
import 'package:auto_route/auto_route.dart';

class HostGuard extends AutoRouteGuard {
  CustomLogger logger = CustomLogger();
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    logger.d('HostGuard');
    resolver.next(true);
    return;
  }
}
