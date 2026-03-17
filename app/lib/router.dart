import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr/route/app_route_path_codec.dart';
import 'package:hostr/route/main.dart';

import 'presentation/screens/host/hostings/hostings.dart';

part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouterConfig<UrlState> config({
    DeepLinkTransformer? deepLinkTransformer,
    DeepLinkBuilder? deepLinkBuilder,
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
    bool includePrefixMatches = !kIsWeb,
    bool Function(String? location)? neglectWhen,
    bool rebuildStackOnDeepLink = false,
    Listenable? reevaluateListenable,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return RouterConfig(
      routeInformationParser: AppDefaultRouteParser(
        matcher,
        includePrefixMatches: includePrefixMatches,
        deepLinkTransformer: deepLinkTransformer,
      ),
      routeInformationProvider: routeInfoProvider(neglectWhen: neglectWhen),
      backButtonDispatcher: RootBackButtonDispatcher(),
      routerDelegate: delegate(
        reevaluateListenable: reevaluateListenable,
        rebuildStackOnDeepLink: rebuildStackOnDeepLink,
        navRestorationScopeId: navRestorationScopeId,
        navigatorObservers: navigatorObservers,
        placeholder: placeholder,
        deepLinkBuilder: deepLinkBuilder,
        clipBehavior: clipBehavior,
      ),
    );
  }

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: RootRoute.page,
      initial: true,
      children: [
        CustomRoute(
          page: StartupGateRoute.page,
          path: 'startup',
          transitionsBuilder: TransitionsBuilders.fadeIn,
          duration: const Duration(milliseconds: 250),
          reverseDuration: const Duration(milliseconds: 250),
        ),
        AutoRoute(
          page: StartupShellRoute.page,
          path: '',
          initial: true,
          children: [
            AutoRoute(
              page: WideViewportShellRoute.page,
              initial: true,
              path: '',
              children: [
                AutoRoute(
                  page: AppShellRoute.page,
                  initial: true,
                  path: '',
                  children: [
                    /// Public routes
                    AutoRoute(
                      page: SearchRoute.page,
                      initial: true,
                      path: 'search',
                      children: [
                        AutoRoute(page: FiltersRoute.page, path: 'filters'),
                      ],
                    ),
                    AutoRoute(page: SignInRoute.page, path: 'signin'),

                    /// Signed in routes
                    AutoRoute(
                      page: ProfileRoute.page,
                      path: 'profile',
                      guards: [AuthGuard()],
                    ),
                    AutoRoute(
                      page: TripsRoute.page,
                      path: 'trips',
                      guards: [AuthGuard()],
                    ),
                    AutoRoute(
                      page: InboxRoute.page,
                      path: 'inbox',
                      guards: [AuthGuard()],
                      children: [
                        AutoRoute(page: ThreadRoute.page, path: ':anchor'),
                      ],
                    ),
                    AutoRoute(
                      page: MyListingsRoute.page,
                      path: 'my-listings',
                      guards: [AuthGuard()],
                    ),
                    AutoRoute(
                      page: HostingsRoute.page,
                      path: 'hostings',
                      guards: [AuthGuard()],
                    ),
                  ],
                ),
                AutoRoute(page: ListingRoute.page, path: 'listing/:a'),
                AutoRoute(
                  page: EditListingRoute.page,
                  path: 'edit-listing/:a?',
                  guards: [],
                ),
                AutoRoute(
                  page: EditProfileRoute.page,
                  path: 'edit-profile',
                  guards: [AuthGuard()],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}
