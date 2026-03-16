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
    final nextPath = _routeMatchToPath(resolver.route);
    router.push(
      SignInRoute(
        onSuccess: () {
          logger.d('AuthGuard: sign-in complete, routing through startup gate');
          router.replaceAll([StartupGateRoute(nextPath: nextPath)]);
        },
      ),
    );
  }
}

String _routeMatchToPath(RouteMatch route) {
  final queryParameters = route.queryParams.rawMap.isEmpty
      ? null
      : route.queryParams.rawMap.map(
          (key, value) => MapEntry(key, value.toString()),
        );

  return Uri(
    path: '/${route.fullPath}',
    queryParameters: queryParameters,
    fragment: route.fragment.isEmpty ? null : route.fragment,
  ).toString();
}
