import 'dart:async';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
    BuildContext context, {
    required StackRouter router,
    required List<AppNavigationDestination> destinations,
    required int selectedIndex,
    required Color navBg,
  }) {
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
            currentIndex: min(items.length - 1, selectedIndex),
            onTap: (index) {
              _selectDestination(router, destinations, index);
            },
            items: items,
          ),
        ),
      ),
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0) {
        _navController.reverse();
      } else if (delta < 0) {
        _navController.forward();
      }
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
  // Sidebar (wide viewports)
  // ---------------------------------------------------------------------------

  Widget _buildSidebar(
    BuildContext context, {
    required List<AppNavigationDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onDestinationSelected,
  }) {
    final theme = Theme.of(context);
    final safeSelectedIndex = min(
      max(0, selectedIndex),
      max(0, destinations.length - 1),
    );

    return AppPanel(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return _SidebarNavItem(
                  label: destination.label,
                  icon: destination.icon,
                  selected: index == safeSelectedIndex,
                  onTap: () => onDestinationSelected(index),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: kSpace2),
            ),
          ),
        ],
      ),
    );
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
                      final theme = Theme.of(context);

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

                      final showSidebar = layout.showsSidebarNavigation;
                      final isOnTabs = segments.any(
                        (s) => s.name == TabShellRoute.name,
                      );

                      // On compact viewports, hide the bottom nav when
                      // the user has navigated into a nested child route
                      // (e.g. ThreadRoute inside InboxRoute). Only show
                      // the nav bar for the tab destination routes
                      // themselves.
                      final isOnNestedChild =
                          !showSidebar &&
                          isOnTabs &&
                          segments.length > 1 &&
                          !destinations.any(
                            (d) => d.route.routeName == segments.last.name,
                          );
                      final showBottomNav =
                          !showSidebar && isOnTabs && !isOnNestedChild;

                      // ── Single stable Scaffold ──────────────────────
                      // The child always sits at Row index 1, so
                      // crossing the breakpoint never unmounts
                      // TabShellScreen / IndexedStack — tab state and
                      // initState fetches are preserved.
                      return Scaffold(
                        backgroundColor: showSidebar
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.surface,
                        extendBody: showBottomNav,
                        body: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: layout.shellMaxWidth,
                            ),
                            child: Row(
                              children: [
                                // Sidebar — always at index 0, zero
                                // width when hidden. Keeps the content
                                // child at a stable tree position.
                                SizedBox(
                                  width: showSidebar ? kAppSidebarWidth : 0,
                                  child: showSidebar
                                      ? SafeArea(
                                          right: false,
                                          bottom: false,
                                          child: _buildSidebar(
                                            context,
                                            destinations: destinations,
                                            selectedIndex: selectedIndex,
                                            onDestinationSelected: (idx) {
                                              _selectDestination(
                                                router,
                                                destinations,
                                                idx,
                                              );
                                            },
                                          ),
                                        )
                                      : null,
                                ),
                                // Content — always at index 1.
                                Expanded(
                                  child:
                                      NotificationListener<ScrollNotification>(
                                        onNotification: _onScrollNotification,
                                        child: child,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        bottomNavigationBar: showBottomNav
                            ? _buildBottomNav(
                                context,
                                router: router,
                                destinations: destinations,
                                selectedIndex: selectedIndex,
                                navBg: theme
                                    .bottomNavigationBarTheme
                                    .backgroundColor!,
                              )
                            : null,
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

// ---------------------------------------------------------------------------
// Sidebar nav item (wide viewports)
// ---------------------------------------------------------------------------

class _SidebarNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = selected
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.transparent;
    final foregroundColor = selected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(kAppNavBarItemRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kAppNavBarItemRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpace4,
            vertical: kSpace3,
          ),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(width: kSpace3),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
