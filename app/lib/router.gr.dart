// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [FiltersScreen]
class FiltersRoute extends PageRouteInfo<void> {
  const FiltersRoute({List<PageRouteInfo>? children})
      : super(
          FiltersRoute.name,
          initialChildren: children,
        );

  static const String name = 'FiltersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FiltersScreen();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [InboxScreen]
class InboxRoute extends PageRouteInfo<void> {
  const InboxRoute({List<PageRouteInfo>? children})
      : super(
          InboxRoute.name,
          initialChildren: children,
        );

  static const String name = 'InboxRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const InboxScreen();
    },
  );
}

/// generated route for
/// [ListingScreen]
class ListingRoute extends PageRouteInfo<ListingRouteArgs> {
  ListingRoute({
    required String id,
    String? dateRangeStart,
    String? dateRangeEnd,
    List<PageRouteInfo>? children,
  }) : super(
          ListingRoute.name,
          args: ListingRouteArgs(
            id: id,
            dateRangeStart: dateRangeStart,
            dateRangeEnd: dateRangeEnd,
          ),
          rawPathParams: {'id': id},
          rawQueryParams: {
            'dateRangeStart': dateRangeStart,
            'dateRangeEnd': dateRangeEnd,
          },
          initialChildren: children,
        );

  static const String name = 'ListingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<ListingRouteArgs>(
          orElse: () => ListingRouteArgs(
                id: pathParams.getString('id'),
                dateRangeStart: queryParams.optString('dateRangeStart'),
                dateRangeEnd: queryParams.optString('dateRangeEnd'),
              ));
      return ListingScreen(
        id: args.id,
        dateRangeStart: args.dateRangeStart,
        dateRangeEnd: args.dateRangeEnd,
      );
    },
  );
}

class ListingRouteArgs {
  const ListingRouteArgs({
    required this.id,
    this.dateRangeStart,
    this.dateRangeEnd,
  });

  final String id;

  final String? dateRangeStart;

  final String? dateRangeEnd;

  @override
  String toString() {
    return 'ListingRouteArgs{id: $id, dateRangeStart: $dateRangeStart, dateRangeEnd: $dateRangeEnd}';
  }
}

/// generated route for
/// [MyListingsScreen]
class MyListingsRoute extends PageRouteInfo<void> {
  const MyListingsRoute({List<PageRouteInfo>? children})
      : super(
          MyListingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'MyListingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MyListingsScreen();
    },
  );
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
      : super(
          ProfileRoute.name,
          initialChildren: children,
        );

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileScreen();
    },
  );
}

/// generated route for
/// [SearchScreen]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SearchScreen();
    },
  );
}

/// generated route for
/// [SignInScreen]
class SignInRoute extends PageRouteInfo<void> {
  const SignInRoute({List<PageRouteInfo>? children})
      : super(
          SignInRoute.name,
          initialChildren: children,
        );

  static const String name = 'SignInRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignInScreen();
    },
  );
}
