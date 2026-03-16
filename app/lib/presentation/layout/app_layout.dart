import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/router.dart';

const kAppCompactBreakpoint = 900.0;
const kAppWideBreakpoint = 1100.0;
const kAppShellMaxWidth = 1720.0;
const kAppContentMaxWidth = 1280.0;
const kAppWideContentMaxWidth = 1600.0;
const kAppSidebarWidth = 280.0;
const kAppSidebarCollapsedWidth = 96.0;
const kAppSearchListPaneWidth = 460.0;
const kAppInboxListPaneWidth = 460.0;
const kAppProfileMaxWidth = 460.0;
const kAppFormMaxWidth = 460.0;
const kAppPanelLargeWidth = 760.0;

const kAppPanelRadius = 16.0;
const kAppPanelGap = kSpace5;
const kAppPagePadding = EdgeInsets.fromLTRB(kSpace5, kSpace4, kSpace5, kSpace4);
const kAppPagePaddingWithHeader = EdgeInsets.fromLTRB(
  kSpace5,
  kSpace5,
  kSpace5,
  kSpace4,
);
const kAppPanelPadding = EdgeInsets.all(kSpace5);

enum AppViewportSize { compact, medium, expanded }

class AppLayoutSpec {
  final double width;

  const AppLayoutSpec._(this.width);

  factory AppLayoutSpec.of(BuildContext context) {
    return AppLayoutSpec._(MediaQuery.sizeOf(context).width);
  }

  AppViewportSize get size {
    if (width >= kAppWideBreakpoint) return AppViewportSize.expanded;
    if (width >= kAppCompactBreakpoint) return AppViewportSize.medium;
    return AppViewportSize.compact;
  }

  bool get showsSidebarNavigation => width >= kAppWideBreakpoint;
  bool get showsSearchSplit => width >= kAppWideBreakpoint;
  bool get showsInboxSplit => width >= kAppWideBreakpoint;
  bool get isExpanded => size == AppViewportSize.expanded;
  double get shellMaxWidth => kAppShellMaxWidth;
  double get contentMaxWidth =>
      isExpanded ? kAppWideContentMaxWidth : kAppContentMaxWidth;
}

class AppNavigationDestination {
  final String label;
  final IconData icon;
  final PageRouteInfo route;

  const AppNavigationDestination({
    required this.label,
    required this.icon,
    required this.route,
  });
}

List<AppNavigationDestination> buildAppNavigationDestinations({
  required bool isLoggedIn,
  required ModeCubitState modeState,
}) {
  if (!isLoggedIn) {
    return [
      const AppNavigationDestination(
        label: 'Explore',
        icon: Icons.travel_explore,
        route: SearchRoute(),
      ),
      AppNavigationDestination(
        label: 'Sign In',
        icon: Icons.person_outline,
        route: SignInRoute(),
      ),
    ];
  }

  if (modeState is HostMode) {
    return [
      const AppNavigationDestination(
        label: 'My Listings',
        icon: Icons.list,
        route: MyListingsRoute(),
      ),
      const AppNavigationDestination(
        label: 'Bookings',
        icon: Icons.calendar_today,
        route: HostingsRoute(),
      ),
      const AppNavigationDestination(
        label: 'Inbox',
        icon: Icons.inbox,
        route: InboxRoute(),
      ),
      const AppNavigationDestination(
        label: 'Profile',
        icon: Icons.person,
        route: ProfileRoute(),
      ),
    ];
  }

  return [
    const AppNavigationDestination(
      label: 'Explore',
      icon: Icons.travel_explore,
      route: SearchRoute(),
    ),
    const AppNavigationDestination(
      label: 'Trips',
      icon: Icons.flight,
      route: TripsRoute(),
    ),
    const AppNavigationDestination(
      label: 'Inbox',
      icon: Icons.inbox,
      route: InboxRoute(),
    ),
    const AppNavigationDestination(
      label: 'Profile',
      icon: Icons.person,
      route: ProfileRoute(),
    ),
  ];
}

String resolveAppNavigationRouteName({
  required String currentRouteName,
  required bool isLoggedIn,
  required ModeCubitState modeState,
}) {
  switch (currentRouteName) {
    case EditProfileRoute.name:
      return ProfileRoute.name;
    case EditListingRoute.name:
      return isLoggedIn && modeState is HostMode
          ? MyListingsRoute.name
          : SearchRoute.name;
    case ListingRoute.name:
      return isLoggedIn && modeState is HostMode
          ? MyListingsRoute.name
          : SearchRoute.name;
    case FiltersRoute.name:
      return SearchRoute.name;
    case ThreadRoute.name:
      return InboxRoute.name;
    default:
      return currentRouteName;
  }
}

int resolveAppNavigationIndex({
  required String currentRouteName,
  required List<AppNavigationDestination> destinations,
  required bool isLoggedIn,
  required ModeCubitState modeState,
}) {
  final targetRouteName = resolveAppNavigationRouteName(
    currentRouteName: currentRouteName,
    isLoggedIn: isLoggedIn,
    modeState: modeState,
  );
  final selectedIndex = destinations.indexWhere(
    (destination) => destination.route.routeName == targetRouteName,
  );
  return selectedIndex < 0 ? 0 : selectedIndex;
}

class AppWideNavigationScaffold extends StatelessWidget {
  final List<AppNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const AppWideNavigationScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    final theme = Theme.of(context);
    final navWidth = kAppSidebarWidth;
    final safeSelectedIndex = min(
      max(0, selectedIndex),
      max(0, destinations.length - 1),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: layout.shellMaxWidth),
              child: Row(
                children: [
                  SizedBox(
                    width: navWidth,
                    child: AppPanel(
                      color: Colors.transparent,
                      padding: const EdgeInsets.all(kSpace5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: destinations.length,
                              itemBuilder: (context, index) {
                                final destination = destinations[index];
                                return _AppWideNavigationItem(
                                  label: destination.label,
                                  icon: destination.icon,
                                  selected: index == safeSelectedIndex,
                                  onTap: () => onDestinationSelected(index),
                                );
                              },
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: kSpace2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppWideNavigationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AppWideNavigationItem({
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
      borderRadius: BorderRadius.circular(kSpace2),
      child: InkWell(
        borderRadius: BorderRadius.circular(kSpace2),
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

class AppConstrainedBody extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const AppConstrainedBody({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding = const EdgeInsets.all(kSpace5),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return AppPageGutter(
      maxWidth: maxWidth,
      padding: padding,
      alignment: alignment,
      child: child,
    );
  }
}

class AppPageGutter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const AppPageGutter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding = kAppPagePadding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? layout.contentMaxWidth,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;

  const AppPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.radius = kAppPanelRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AppPanelScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomBar;
  final Color? color;
  final double radius;

  const AppPanelScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomBar,
    this.color,
    this.radius = kAppPanelRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      color: color,
      radius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (appBar != null)
            Theme(
              data: theme.copyWith(
                appBarTheme: theme.appBarTheme.copyWith(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                ),
              ),
              child: appBar!,
            ),
          Expanded(child: body),
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );
  }
}

class AppSinglePanePage extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final bool usePanel;
  final EdgeInsetsGeometry panelPadding;
  final Color? panelColor;
  final double panelRadius;

  const AppSinglePanePage({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding = kAppPagePadding,
    this.alignment = Alignment.topCenter,
    this.usePanel = true,
    this.panelPadding = EdgeInsets.zero,
    this.panelColor,
    this.panelRadius = kAppPanelRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AppPageGutter(
      maxWidth: maxWidth,
      padding: padding,
      alignment: alignment,
      child: usePanel
          ? AppPanel(
              padding: panelPadding,
              color: panelColor,
              radius: panelRadius,
              child: child,
            )
          : child,
    );
  }
}

class AppSplitPage extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final double primaryWidth;
  final double gap;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const AppSplitPage({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryWidth = kAppSearchListPaneWidth,
    this.gap = kAppPanelGap,
    this.maxWidth = kAppWideContentMaxWidth,
    this.padding = kAppPagePadding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return AppPageGutter(
      maxWidth: maxWidth,
      padding: padding,
      alignment: alignment,
      child: AppTwoPane(
        primaryWidth: primaryWidth,
        gap: gap,
        primary: primary,
        secondary: secondary,
      ),
    );
  }
}

class AppTwoPane extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final double primaryWidth;
  final double gap;

  const AppTwoPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryWidth = kAppSearchListPaneWidth,
    this.gap = kSpace5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: primaryWidth, child: primary),
        SizedBox(width: gap),
        Expanded(child: secondary),
      ],
    );
  }
}
