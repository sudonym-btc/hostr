// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [BookingsScreen]
class BookingsRoute extends PageRouteInfo<void> {
  const BookingsRoute({List<PageRouteInfo>? children})
    : super(BookingsRoute.name, initialChildren: children);

  static const String name = 'BookingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BookingsScreen();
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
/// [FiltersScreen]
class FiltersRoute extends PageRouteInfo<FiltersRouteArgs> {
  FiltersRoute({bool asBottomSheet = false, List<PageRouteInfo>? children})
    : super(
        FiltersRoute.name,
        args: FiltersRouteArgs(asBottomSheet: asBottomSheet),
        initialChildren: children,
      );

  static const String name = 'FiltersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FiltersRouteArgs>(
        orElse: () => const FiltersRouteArgs(),
      );
      return FiltersScreen(asBottomSheet: args.asBottomSheet);
    },
  );
}

class FiltersRouteArgs {
  const FiltersRouteArgs({this.asBottomSheet = false});

  final bool asBottomSheet;

  @override
  String toString() {
    return 'FiltersRouteArgs{asBottomSheet: $asBottomSheet}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FiltersRouteArgs) return false;
    return asBottomSheet == other.asBottomSheet;
  }

  @override
  int get hashCode => asBottomSheet.hashCode;
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

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
    List<PageRouteInfo>? children,
  }) : super(
         ListingRoute.name,
         args: ListingRouteArgs(
           a: a,
           dateRangeStart: dateRangeStart,
           dateRangeEnd: dateRangeEnd,
         ),
         rawPathParams: {'a': a},
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
          a: pathParams.getString('a'),
          dateRangeStart: queryParams.optString('dateRangeStart'),
          dateRangeEnd: queryParams.optString('dateRangeEnd'),
        ),
      );
      return ListingScreen(
        a: args.a,
        dateRangeStart: args.dateRangeStart,
        dateRangeEnd: args.dateRangeEnd,
      );
    },
  );
}

class ListingRouteArgs {
  const ListingRouteArgs({
    required this.a,
    this.dateRangeStart,
    this.dateRangeEnd,
  });

  final String a;

  final String? dateRangeStart;

  final String? dateRangeEnd;

  @override
  String toString() {
    return 'ListingRouteArgs{a: $a, dateRangeStart: $dateRangeStart, dateRangeEnd: $dateRangeEnd}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ListingRouteArgs) return false;
    return a == other.a &&
        dateRangeStart == other.dateRangeStart &&
        dateRangeEnd == other.dateRangeEnd;
  }

  @override
  int get hashCode =>
      a.hashCode ^ dateRangeStart.hashCode ^ dateRangeEnd.hashCode;
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
/// [SearchScreen]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
    : super(SearchRoute.name, initialChildren: children);

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
class SignInRoute extends PageRouteInfo<SignInRouteArgs> {
  SignInRoute({Function? onSuccess, List<PageRouteInfo>? children})
    : super(
        SignInRoute.name,
        args: SignInRouteArgs(onSuccess: onSuccess),
        initialChildren: children,
      );

  static const String name = 'SignInRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SignInRouteArgs>(
        orElse: () => const SignInRouteArgs(),
      );
      return SignInScreen(onSuccess: args.onSuccess);
    },
  );
}

class SignInRouteArgs {
  const SignInRouteArgs({this.onSuccess});

  final Function? onSuccess;

  @override
  String toString() {
    return 'SignInRouteArgs{onSuccess: $onSuccess}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SignInRouteArgs) return false;
    return onSuccess == other.onSuccess;
  }

  @override
  int get hashCode => onSuccess.hashCode;
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
