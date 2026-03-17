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

const kAppPanelRadius = 0.0;
const kAppNavBarItemRadius = 0.0;
const kAppPanelGap = 0.0;
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
                      // padding: const EdgeInsets.all(kSpace5),
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

class AppPageGutter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const AppPageGutter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    final resolvedPadding =
        padding ??
        (layout.size == AppViewportSize.compact
            ? EdgeInsets.zero
            : kAppPagePadding);
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? layout.contentMaxWidth,
        ),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}

class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final AppPanelTone tone;

  const AppPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.radius = kAppPanelRadius,
    this.tone = AppPanelTone.secondary,
  });

  const AppPanel.primary({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.radius = kAppPanelRadius,
  }) : tone = AppPanelTone.primary;

  const AppPanel.secondary({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.radius = kAppPanelRadius,
  }) : tone = AppPanelTone.secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor =
        color ??
        switch (tone) {
          AppPanelTone.primary => theme.colorScheme.surfaceContainerHigh,
          AppPanelTone.secondary => theme.colorScheme.surfaceContainer,
        };

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: resolvedColor,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

enum AppPanelTone { primary, secondary }

enum AppPaneContentAlignment { start, center }

class AppPane extends StatelessWidget {
  final int? flex;
  final double? width;
  final PreferredSizeWidget? appBar;
  final SliverAppBar Function(BuildContext context)?
  promotedSliverAppBarBuilder;
  final Widget child;
  final Widget? bottomBar;
  final bool promoteChromeWhenStacked;
  final bool showWhenStacked;
  final Color? color;
  final AppPanelTone panelTone;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;
  final AppPaneContentAlignment alignment;
  final bool usePanel;

  const AppPane({
    super.key,
    this.flex,
    this.width,
    this.appBar,
    this.promotedSliverAppBarBuilder,
    required this.child,
    this.bottomBar,
    this.promoteChromeWhenStacked = false,
    this.showWhenStacked = true,
    this.color,
    this.panelTone = AppPanelTone.secondary,
    this.radius = kAppPanelRadius,
    this.padding = EdgeInsets.zero,
    this.maxWidth,
    this.alignment = AppPaneContentAlignment.start,
    this.usePanel = true,
  }) : assert(
         flex == null || width == null,
         'AppPane cannot define both flex and width.',
       );

  AlignmentGeometry get _contentAlignment => switch (alignment) {
    AppPaneContentAlignment.start => Alignment.topLeft,
    AppPaneContentAlignment.center => Alignment.topCenter,
  };

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: appBar!,
    );
  }

  Widget buildPane({
    required BuildContext context,
    bool includeAppBar = true,
    bool includeBottomBar = true,
  }) {
    Widget buildPaneBody(BoxConstraints constraints) {
      final content = Padding(
        padding: padding,
        child: Align(
          alignment: _contentAlignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
            child: child,
          ),
        ),
      );

      final paneChildren = <Widget>[
        if (includeAppBar && appBar != null) _buildAppBar(context),
        constraints.hasBoundedHeight ? Expanded(child: content) : content,
        if (includeBottomBar && bottomBar != null) bottomBar!,
      ];

      return Column(
        mainAxisSize: constraints.hasBoundedHeight
            ? MainAxisSize.max
            : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: paneChildren,
      );
    }

    final body = LayoutBuilder(
      builder: (context, constraints) {
        return buildPaneBody(constraints);
      },
    );

    if (!usePanel) {
      return body;
    }

    if (color != null) {
      return AppPanel(color: color, radius: radius, child: body);
    }

    return switch (panelTone) {
      AppPanelTone.primary => AppPanel.primary(radius: radius, child: body),
      AppPanelTone.secondary => AppPanel.secondary(radius: radius, child: body),
    };
  }

  @override
  Widget build(BuildContext context) {
    return buildPane(context: context);
  }
}

class AppPaneLayout extends StatelessWidget {
  final List<AppPane> panes;
  final double gap;

  const AppPaneLayout({
    super.key,
    required this.panes,
    this.gap = kAppPanelGap,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    final isHorizontal = layout.isExpanded;
    final stackedPanes = panes.where((pane) => pane.showWhenStacked).toList();

    if (isHorizontal) {
      final children = <Widget>[];

      for (var i = 0; i < panes.length; i++) {
        final pane = panes[i];
        final paneChild = pane.width != null
            ? SizedBox(width: pane.width, child: pane)
            : Expanded(flex: pane.flex ?? 1, child: pane);
        children.add(paneChild);
        if (i < panes.length - 1) {
          children.add(SizedBox(width: gap));
        }
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    final promotedPane = stackedPanes
        .where((pane) => pane.promoteChromeWhenStacked)
        .firstOrNull;
    final promotedSliverAppBar = promotedPane?.promotedSliverAppBarBuilder;

    final children = <Widget>[];
    for (var i = 0; i < stackedPanes.length; i++) {
      final pane = stackedPanes[i];
      final suppressChrome = identical(pane, promotedPane);
      children.add(
        pane.buildPane(
          context: context,
          includeAppBar: !suppressChrome,
          includeBottomBar: !suppressChrome,
        ),
      );
      if (i < stackedPanes.length - 1) {
        children.add(SizedBox(height: gap));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (promotedSliverAppBar == null && promotedPane?.appBar != null)
          promotedPane!._buildAppBar(context),
        Expanded(
          child: promotedSliverAppBar != null
              ? CustomScrollView(
                  slivers: [
                    promotedSliverAppBar(context),
                    SliverList(delegate: SliverChildListDelegate(children)),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
        ),
        if (promotedPane?.bottomBar != null) promotedPane!.bottomBar!,
      ],
    );
  }
}
