import 'package:auto_route/auto_route.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/auth/auth.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/router.dart';

class AuthGuard extends AutoRouteGuard {
  CustomLogger logger = CustomLogger();
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    logger.d('AuthGuard');
    if (getIt<Hostr>().auth.authState.value == LoggedIn()) {
      logger.d('AuthGuard logged in');
      resolver.next(true);
      return;
    }
    logger.d('AuthGuard logged out');
    router.push(
      SignInRoute(
        onSuccess: () {
          logger.d('AuthGuard forwarding to ${resolver.route.name}');
          resolver.next(true);
          router.removeLast();
        },
      ),
    );
  }
}
