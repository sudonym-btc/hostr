import 'package:auto_route/auto_route.dart';
import 'package:hostr/main.dart';

part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: '/', page: HomeRoute.page, initial: true, children: [
          AutoRoute(
              page: SearchRoute.page,
              initial: true,
              path: 'search',
              children: [
                AutoRoute(page: FiltersRoute.page, path: 'filters'),
              ]),
          AutoRoute(page: InboxRoute.page, path: 'inbox'),
          AutoRoute(page: SignInRoute.page, path: 'signin'),
          AutoRoute(page: ProfileRoute.page, path: 'profile'),
          AutoRoute(page: MyListingsRoute.page, path: 'my-listings'),
        ]),
        AutoRoute(page: ListingRoute.page, path: '/listing/:id')
      ];
}
