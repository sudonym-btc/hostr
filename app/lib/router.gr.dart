// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [AppShellScreen]
class AppShellRoute extends PageRouteInfo<void> {
  const AppShellRoute({List<PageRouteInfo>? children})
    : super(AppShellRoute.name, initialChildren: children);

  static const String name = 'AppShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AppShellScreen();
    },
  );
}

/// generated route for
/// [EditListingScreen]
class EditListingRoute extends PageRouteInfo<EditListingRouteArgs> {
  EditListingRoute({String? a, List<PageRouteInfo>? children})
    : super(
        EditListingRoute.name,
        args: EditListingRouteArgs(a: a),
        rawPathParams: {'a': a},
        initialChildren: children,
      );

  static const String name = 'EditListingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<EditListingRouteArgs>(
        orElse: () => EditListingRouteArgs(a: pathParams.optString('a')),
      );
      return EditListingScreen(a: args.a);
    },
  );
}

class EditListingRouteArgs {
  const EditListingRouteArgs({this.a});

  final String? a;

  @override
  String toString() {
    return 'EditListingRouteArgs{a: $a}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditListingRouteArgs) return false;
    return a == other.a;
  }

  @override
  int get hashCode => a.hashCode;
}

/// generated route for
/// [EditProfileScreen]
class EditProfileRoute extends PageRouteInfo<void> {
  const EditProfileRoute({List<PageRouteInfo>? children})
    : super(EditProfileRoute.name, initialChildren: children);

  static const String name = 'EditProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EditProfileScreen();
    },
  );
}

/// generated route for
/// [ExploreScreen]
class ExploreRoute extends PageRouteInfo<void> {
  const ExploreRoute({List<PageRouteInfo>? children})
    : super(ExploreRoute.name, initialChildren: children);

  static const String name = 'ExploreRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ExploreScreen();
    },
  );
}

/// generated route for
/// [FiltersScreen]
class FiltersRoute extends PageRouteInfo<void> {
  const FiltersRoute({List<PageRouteInfo>? children})
    : super(FiltersRoute.name, initialChildren: children);

  static const String name = 'FiltersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return FiltersScreen();
    },
  );
}

/// generated route for
/// [HostingsScreen]
class HostingsRoute extends PageRouteInfo<void> {
  const HostingsRoute({List<PageRouteInfo>? children})
    : super(HostingsRoute.name, initialChildren: children);

  static const String name = 'HostingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HostingsScreen();
    },
  );
}

/// generated route for
/// [InboxScreen]
class InboxRoute extends PageRouteInfo<void> {
  const InboxRoute({List<PageRouteInfo>? children})
    : super(InboxRoute.name, initialChildren: children);

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
    required String a,
    String? dateRangeStart,
    String? dateRangeEnd,
    String? reserveAmountValue,
    String? reserveAmountDenomination,
    String? reserveAmountDecimals,
    String? autoReserve,
    List<PageRouteInfo>? children,
  }) : super(
         ListingRoute.name,
         args: ListingRouteArgs(
           a: a,
           dateRangeStart: dateRangeStart,
           dateRangeEnd: dateRangeEnd,
           reserveAmountValue: reserveAmountValue,
           reserveAmountDenomination: reserveAmountDenomination,
           reserveAmountDecimals: reserveAmountDecimals,
           autoReserve: autoReserve,
         ),
         rawPathParams: {'a': a},
         rawQueryParams: {
           'dateRangeStart': dateRangeStart,
           'dateRangeEnd': dateRangeEnd,
           'reserveAmountValue': reserveAmountValue,
           'reserveAmountDenomination': reserveAmountDenomination,
           'reserveAmountDecimals': reserveAmountDecimals,
           'autoReserve': autoReserve,
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
          a: pathParams.getString('a'),
          dateRangeStart: queryParams.optString('dateRangeStart'),
          dateRangeEnd: queryParams.optString('dateRangeEnd'),
          reserveAmountValue: queryParams.optString('reserveAmountValue'),
          reserveAmountDenomination: queryParams.optString(
            'reserveAmountDenomination',
          ),
          reserveAmountDecimals: queryParams.optString('reserveAmountDecimals'),
          autoReserve: queryParams.optString('autoReserve'),
        ),
      );
      return ListingScreen(
        a: args.a,
        dateRangeStart: args.dateRangeStart,
        dateRangeEnd: args.dateRangeEnd,
        reserveAmountValue: args.reserveAmountValue,
        reserveAmountDenomination: args.reserveAmountDenomination,
        reserveAmountDecimals: args.reserveAmountDecimals,
        autoReserve: args.autoReserve,
      );
    },
  );
}

class ListingRouteArgs {
  const ListingRouteArgs({
    required this.a,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.reserveAmountValue,
    this.reserveAmountDenomination,
    this.reserveAmountDecimals,
    this.autoReserve,
  });

  final String a;

  final String? dateRangeStart;

  final String? dateRangeEnd;

  final String? reserveAmountValue;

  final String? reserveAmountDenomination;

  final String? reserveAmountDecimals;

  final String? autoReserve;

  @override
  String toString() {
    return 'ListingRouteArgs{a: $a, dateRangeStart: $dateRangeStart, dateRangeEnd: $dateRangeEnd, reserveAmountValue: $reserveAmountValue, reserveAmountDenomination: $reserveAmountDenomination, reserveAmountDecimals: $reserveAmountDecimals, autoReserve: $autoReserve}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ListingRouteArgs) return false;
    return a == other.a &&
        dateRangeStart == other.dateRangeStart &&
        dateRangeEnd == other.dateRangeEnd &&
        reserveAmountValue == other.reserveAmountValue &&
        reserveAmountDenomination == other.reserveAmountDenomination &&
        reserveAmountDecimals == other.reserveAmountDecimals &&
        autoReserve == other.autoReserve;
  }

  @override
  int get hashCode =>
      a.hashCode ^
      dateRangeStart.hashCode ^
      dateRangeEnd.hashCode ^
      reserveAmountValue.hashCode ^
      reserveAmountDenomination.hashCode ^
      reserveAmountDecimals.hashCode ^
      autoReserve.hashCode;
}

/// generated route for
/// [MyListingsScreen]
class MyListingsRoute extends PageRouteInfo<void> {
  const MyListingsRoute({List<PageRouteInfo>? children})
    : super(MyListingsRoute.name, initialChildren: children);

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
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileScreen();
    },
  );
}

/// generated route for
/// [RootScreen]
class RootRoute extends PageRouteInfo<void> {
  const RootRoute({List<PageRouteInfo>? children})
    : super(RootRoute.name, initialChildren: children);

  static const String name = 'RootRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return RootScreen();
    },
  );
}

/// generated route for
/// [SignInScreen]
class SignInRoute extends PageRouteInfo<void> {
  const SignInRoute({List<PageRouteInfo>? children})
    : super(SignInRoute.name, initialChildren: children);

  static const String name = 'SignInRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignInScreen();
    },
  );
}

/// generated route for
/// [StartupShellScreen]
class StartupShellRoute extends PageRouteInfo<void> {
  const StartupShellRoute({List<PageRouteInfo>? children})
    : super(StartupShellRoute.name, initialChildren: children);

  static const String name = 'StartupShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StartupShellScreen();
    },
  );
}

/// generated route for
/// [TabShellScreen]
class TabShellRoute extends PageRouteInfo<void> {
  const TabShellRoute({List<PageRouteInfo>? children})
    : super(TabShellRoute.name, initialChildren: children);

  static const String name = 'TabShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TabShellScreen();
    },
  );
}

/// generated route for
/// [ThreadScreen]
class ThreadRoute extends PageRouteInfo<ThreadRouteArgs> {
  ThreadRoute({required String anchor, List<PageRouteInfo>? children})
    : super(
        ThreadRoute.name,
        args: ThreadRouteArgs(anchor: anchor),
        rawPathParams: {'anchor': anchor},
        initialChildren: children,
      );

  static const String name = 'ThreadRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ThreadRouteArgs>(
        orElse: () => ThreadRouteArgs(anchor: pathParams.getString('anchor')),
      );
      return ThreadScreen(anchor: args.anchor);
    },
  );
}

class ThreadRouteArgs {
  const ThreadRouteArgs({required this.anchor});

  final String anchor;

  @override
  String toString() {
    return 'ThreadRouteArgs{anchor: $anchor}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ThreadRouteArgs) return false;
    return anchor == other.anchor;
  }

  @override
  int get hashCode => anchor.hashCode;
}

/// generated route for
/// [TripsScreen]
class TripsRoute extends PageRouteInfo<void> {
  const TripsRoute({List<PageRouteInfo>? children})
    : super(TripsRoute.name, initialChildren: children);

  static const String name = 'TripsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TripsScreen();
    },
  );
}
