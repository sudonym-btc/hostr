import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _itemTopPadding = kDefaultPadding / 2;
  late final AnimationController _navController = AnimationController(
    vsync: this,
    duration: kAnimationDuration,
    value: 1.0, // start fully visible
  );

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  BottomNavigationBarItem _navItem({
    required Widget icon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: CustomPadding.only(top: _itemTopPadding, child: icon),
      label: label,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    TabsRouter tabsRouter,
    List<BottomNavigationBarItem> items,
    Color navBg,
  ) {
    final borderRadius = BorderRadius.circular(0);

    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _navController,
        curve: kAnimationCurve,
      ),
      axisAlignment: -1.0, // pin to top so it collapses downward
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          color: navBg,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: min(items.length - 1, tabsRouter.activeIndex),
            onTap: (index) {
              _navController.forward();
              tabsRouter.setActiveIndex(index);
            },
            items: items,
          ),
        ),
      ),
    );
  }

  bool _onScrollNotification(UserScrollNotification notification) {
    final direction = notification.direction;
    if (direction == ScrollDirection.reverse) {
      _navController.reverse();
    } else if (direction == ScrollDirection.forward) {
      _navController.forward();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: _onScrollNotification,
      child: StreamBuilder<AuthState>(
        stream: getIt<Hostr>().auth.authState,
        initialData: getIt<Hostr>().auth.authState.value,
        builder: (context, authSnapshot) {
          final isLoggedIn = authSnapshot.data == const LoggedIn();

          return BlocBuilder<ModeCubit, ModeCubitState>(
            builder: (context, state) {
              final bottomNavigationBarTheme = Theme.of(
                context,
              ).bottomNavigationBarTheme;
              final navBg = bottomNavigationBarTheme.backgroundColor!;

              if (!isLoggedIn) {
                // Unauthenticated: Search and Sign In
                final tabs = [
                  _navItem(
                    icon: Icon(Icons.search, size: kIconLg),
                    label: 'Search',
                  ),
                  _navItem(icon: Icon(Icons.person_outline), label: 'Sign In'),
                ];
                return AutoTabsScaffold(
                  key: const ValueKey('unauthTabs'),
                  extendBody: true,
                  routes: [SearchRoute(), SignInRoute()],
                  bottomNavigationBuilder: (context, tabsRouter) =>
                      _buildBottomNav(context, tabsRouter, tabs, navBg),
                );
              }

              if (state is HostMode) {
                final hostTabs = [
                  _navItem(icon: Icon(Icons.list), label: 'My Listings'),
                  _navItem(icon: Icon(Icons.inbox), label: 'Inbox'),
                  _navItem(icon: Icon(Icons.person), label: 'Profile'),
                ];
                return AutoTabsScaffold(
                  key: const ValueKey('hostTabs'),
                  extendBody: true,
                  routes: [MyListingsRoute(), InboxRoute(), ProfileRoute()],
                  bottomNavigationBuilder: (context, tabsRouter) =>
                      _buildBottomNav(context, tabsRouter, hostTabs, navBg),
                );
              }
              final otherTabs = [
                _navItem(
                  icon: Icon(Icons.search, size: kIconLg),
                  label: 'Search',
                ),
                _navItem(icon: Icon(Icons.travel_explore), label: 'Trips'),
                _navItem(icon: Icon(Icons.inbox), label: 'Inbox'),
                _navItem(icon: Icon(Icons.person), label: 'Profile'),
              ];
              return AutoTabsScaffold(
                key: const ValueKey('guestTabs'),
                extendBody: true,
                routes: [
                  SearchRoute(),
                  TripsRoute(),
                  InboxRoute(),
                  ProfileRoute(),
                ],
                bottomNavigationBuilder: (context, tabsRouter) =>
                    _buildBottomNav(context, tabsRouter, otherTabs, navBg),
              );
            },
          );
        },
      ),
    );
  }
}
