import 'package:auto_route/auto_route.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

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
          logger.d('AuthGuard: sign-in complete, routing through onboarding');
          // Replace with onboarding which will navigate to HomeRoute when done.
          router.replaceAll([OnboardingRoute()]);
        },
      ),
    );
  }
}
