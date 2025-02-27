import 'package:auto_route/auto_route.dart';
import 'package:hostr/main.dart';
import 'package:hostr/route/main.dart';

part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: RootRoute.page, initial: true, children: [
          AutoRoute(page: SignInRoute.page, path: 'signin'),
          AutoRoute(page: ListingRoute.page, path: 'listing/:a'),
          AutoRoute(page: ThreadRoute.page, path: 'inbox/:id'),
          AutoRoute(page: HomeRoute.page, initial: true, children: [
            /// Public routes
            AutoRoute(
                page: SearchRoute.page,
                initial: true,
                path: 'search',
                children: [
                  AutoRoute(page: FiltersRoute.page, path: 'filters'),
                ]),

            /// Signed in routes

            AutoRoute(page: ProfileRoute.page, path: 'profile', guards: []),
            AutoRoute(
                page: BookingsRoute.page,
                path: 'bookings',
                guards: [AuthGuard()]),
            AutoRoute(
                page: TripsRoute.page, path: 'trips', guards: [AuthGuard()]),
            AutoRoute(
                page: InboxRoute.page,
                path: 'inbox',
                guards: [AuthGuard()],
                children: []),
            AutoRoute(
                page: MyListingsRoute.page,
                path: 'my-listings',
                guards: [AuthGuard()]),
          ]),
          AutoRoute(
              page: EditListingRoute.page,
              path: 'edit-listing/:a?',
              guards: []),
        ]),
      ];
}
