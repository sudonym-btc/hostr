import 'package:auto_route/auto_route.dart';
import 'package:hostr/main.dart';
import 'package:hostr/route/main.dart';

part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        /// Public routes
        AutoRoute(page: SignInRoute.page, path: '/signin'),
        AutoRoute(
            page: SearchRoute.page,
            initial: true,
            path: 'search',
            children: [
              AutoRoute(page: FiltersRoute.page, path: 'filters'),
            ]),
        AutoRoute(page: ListingRoute.page, path: '/listing/:id'),

        /// Signed in routes
        AutoRoute(path: '/', page: HomeRoute.page, initial: true, guards: [
          AuthGuard()
        ], children: [
          AutoRoute(page: ProfileRoute.page, path: 'profile', guards: []),
          AutoRoute(page: InboxRoute.page, path: 'inbox', guards: [
            AuthGuard()
          ], children: [
            AutoRoute(page: ConversationRoute.page, path: ':id'),
          ]),
          AutoRoute(
              page: MyListingsRoute.page,
              path: 'my-listings',
              guards: [AuthGuard()]),
        ]),
      ];
}
