import 'dart:async';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/app.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// The navigation-chrome shell of the app.
///
/// Wraps all content that appears after the startup gate. Renders:
///   • a sidebar on wide viewports (always visible, even for standalone routes)
///   • a bottom navigation bar on compact viewports (only when the active
///     child is [TabShellRoute] — hidden for standalone routes like listing
///     detail or edit-profile)
///
/// Tab persistence is handled by the child [TabShellScreen], which manages
/// an [AutoTabsRouter] + [IndexedStack]. This screen only owns navigation
/// chrome and delegates tab switching to that inner router.
@RoutePage()
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen>
    with SingleTickerProviderStateMixin {
  static const _itemTopPadding = kDefaultPadding / 2;

  late final AnimationController _navController = AnimationController(
    vsync: this,
    duration: kAnimationDuration,
    value: 1.0, // start fully visible
  );
  late final StreamSubscription<AuthState> _authSub;
  late final StreamSubscription<void> _popSub;

  @override
  void initState() {
    super.initState();
    _authSub = getIt<Hostr>().auth.authState.listen((_) => _showNav());
    _popSub = MyObserver.onPop.listen((_) => _showNav());
  }

  @override
  void dispose() {
    _popSub.cancel();
    _authSub.cancel();
    _navController.dispose();
    super.dispose();
  }

  void _showNav() {
    if (mounted) _navController.forward();
  }

  // ---------------------------------------------------------------------------
  // Bottom nav helpers (compact viewports)
  // ---------------------------------------------------------------------------

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
    List<AppNavigationDestination> destinations,
    Color navBg,
  ) {
    final items = [
      for (final destination in destinations)
        _navItem(
          icon: Icon(
            destination.icon,
            size: destination.route.routeName == SearchRoute.name
                ? kIconLg
                : kIconMd,
          ),
          label: destination.label,
        ),
    ];

    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _navController,
        curve: kAnimationCurve,
      ),
      axisAlignment: -1.0, // pin to top so it collapses downward
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Navigate to a tab destination. Always goes through [TabShellRoute] so
  /// the inner [AutoTabsRouter] handles persistence.
  void _selectDestination(
    StackRouter router,
    List<AppNavigationDestination> destinations,
    int index,
  ) {
    _navController.forward();
    router.navigate(TabShellRoute(children: [destinations[index].route]));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return RelayConnectivityBanner(
      child: NwcConnectivityBanner(
        child: BlocListener<ModeCubit, ModeCubitState>(
          listener: (context, state) => _showNav(),
          child: StreamBuilder<AuthState>(
            stream: getIt<Hostr>().auth.authState,
            initialData: getIt<Hostr>().auth.authState.value,
            builder: (context, snapshot) {
              final isLoggedIn = snapshot.data == const LoggedIn();

              return BlocBuilder<ModeCubit, ModeCubitState>(
                builder: (context, modeState) {
                  final destinations = buildAppNavigationDestinations(
                    isLoggedIn: isLoggedIn,
                    modeState: modeState,
                  );

                  return AutoRouter(
                    builder: (context, child) {
                      final router = AutoRouter.of(context);
                      final topRouteName = router.topRoute.name;
                      final layout = AppLayoutSpec.of(context);

                      final isOnTabs = topRouteName == TabShellRoute.name;

                      // Use the deepest route segment for nav-index
                      // resolution. currentSegments traverses the full
                      // route hierarchy including pending children, so
                      // it works on the very first frame — before the
                      // TabShellScreen widget has built its
                      // AutoTabsRouter.
                      final segments = router.currentSegments;
                      final currentRouteName = segments.isNotEmpty
                          ? segments.last.name
                          : topRouteName;

                      final selectedIndex = resolveAppNavigationIndex(
                        currentRouteName: currentRouteName,
                        destinations: destinations,
                        isLoggedIn: isLoggedIn,
                        modeState: modeState,
                      );

                      // --- Wide viewport: sidebar always visible ------------
                      if (layout.showsSidebarNavigation) {
                        return AppWideNavigationScaffold(
                          destinations: destinations,
                          selectedIndex: selectedIndex,
                          onDestinationSelected: (index) {
                            _selectDestination(router, destinations, index);
                          },
                          child: child,
                        );
                      }

                      // --- Compact viewport ---------------------------------
                      // Show bottom nav only when on a tab route.
                      if (!isOnTabs) return child;

                      final tabsRouter = context.innerRouterOf<TabsRouter>(
                        TabShellRoute.name,
                      );
                      if (tabsRouter == null) return child;

                      final navBg = Theme.of(
                        context,
                      ).bottomNavigationBarTheme.backgroundColor!;

                      return Scaffold(
                        extendBody: true,
                        body: NotificationListener<UserScrollNotification>(
                          onNotification: _onScrollNotification,
                          child: child,
                        ),
                        bottomNavigationBar: _buildBottomNav(
                          context,
                          tabsRouter,
                          destinations,
                          navBg,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
