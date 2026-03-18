import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/app_spacing_theme.dart';
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
const kAppPagePadding = EdgeInsets.zero;
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

class AppPageGutter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  /// When `true`, the child is centered within the available space on
  /// expanded viewports while still constrained by [maxWidth].
  /// On compact viewports the default [alignment] is used.
  final bool centerContent;

  const AppPageGutter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    final resolvedPadding =
        padding ??
        (layout.size == AppViewportSize.compact
            ? EdgeInsets.zero
            : kAppPagePadding);
    final resolvedAlignment = (centerContent && layout.isExpanded)
        ? Alignment.center
        : alignment;
    return Align(
      alignment: resolvedAlignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? layout.contentMaxWidth,
        ),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}

/// Provides the resolved background [Color] of the nearest [AppPanel]
/// ancestor to its descendants.
///
/// Widgets like [SaveBottomBar], custom app bars, or reply inputs can call
/// [AppPaneTheme.of] to inherit the enclosing pane's background colour
/// instead of hard-coding a colour token.
class AppPaneTheme extends InheritedWidget {
  /// The resolved background colour of the enclosing panel.
  final Color color;

  const AppPaneTheme({super.key, required this.color, required super.child});

  /// Returns the [AppPaneTheme] from the nearest ancestor, or `null`
  /// if no panel is above this widget.
  static AppPaneTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppPaneTheme>();
  }

  /// Returns the resolved panel colour, falling back to
  /// [ColorScheme.surface] when no [AppPanel] is above this widget.
  static Color of(BuildContext context) {
    return maybeOf(context)?.color ?? Theme.of(context).colorScheme.surface;
  }

  /// The ordered neutral surface-container scale from lowest to highest.
  static List<Color> _scale(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return [
      cs.surfaceContainerLowest,
      cs.surfaceContainerLow,
      cs.surfaceContainer,
      cs.surfaceContainerHigh,
      cs.surfaceContainerHighest,
    ];
  }

  /// Returns the colour [steps] above the current pane on the neutral
  /// surface-container scale. Clamps at `surfaceContainerHighest`.
  static Color stepped(BuildContext context, [int steps = 1]) {
    final current = of(context);
    final scale = _scale(context);
    final idx = scale.indexOf(current);
    if (idx == -1) return scale.last;
    return scale[(idx + steps).clamp(0, scale.length - 1)];
  }

  @override
  bool updateShouldNotify(AppPaneTheme oldWidget) => color != oldWidget.color;
}

/// A surface that is [steps] levels above its nearest [AppPaneTheme]
/// ancestor on the neutral surface-container scale.
///
/// Re-injects an [AppPaneTheme] at the resolved level so descendants
/// can stack further.
class AppSurface extends StatelessWidget {
  final Widget child;
  final int steps;
  final BorderRadiusGeometry? borderRadius;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? padding;

  const AppSurface({
    super.key,
    required this.child,
    this.steps = 1,
    this.borderRadius,
    this.shape,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppPaneTheme.stepped(context, steps);
    return AppPaneTheme(
      color: color,
      child: Material(
        color: color,
        borderRadius: shape == null ? borderRadius : null,
        shape: shape,
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
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

  /// Resolves the effective background colour for the given [tone]
  /// and optional explicit [color] override.
  static Color resolveColor(
    BuildContext context, {
    Color? color,
    AppPanelTone tone = AppPanelTone.secondary,
  }) {
    return color ??
        switch (tone) {
          AppPanelTone.primary => Theme.of(
            context,
          ).colorScheme.surfaceContainerHigh,
          AppPanelTone.secondary => Theme.of(
            context,
          ).colorScheme.surfaceContainer,
        };
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = resolveColor(context, color: color, tone: tone);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AppPaneTheme(
        color: resolvedColor,
        child: Material(
          color: resolvedColor,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

enum AppPanelTone { primary, secondary }

/// Controls how [AppPaneLayout] assigns background colours to panes on
/// expanded (web) viewports.
enum AppPaneColorMode {
  /// Assigns decreasing surface-container tones by pane index.
  /// First pane → [surfaceContainerHigh], second → [surfaceContainer], etc.
  autoStepped,

  /// All panes are transparent — no background is applied by the layout.
  flat,
}

/// Controls the stacked (compact / mobile) viewport background behaviour.
enum AppPaneStackMode {
  /// Panes are transparent; the single [Scaffold] background shows through.
  flat,

  /// Each pane paints the same stepped colour it would receive on web.
  tinted,
}

enum AppPaneContentAlignment { start, center }

class AppPane extends StatelessWidget {
  final int? flex;
  final double? width;
  final PreferredSizeWidget Function(BuildContext context)? appBarBuilder;
  final SliverAppBar Function(BuildContext context)? sliverAppBarBuilder;
  final Widget child;
  final Widget? bottomBar;
  final bool promoteChromeWhenStacked;
  final bool showWhenStacked;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;
  final AppPaneContentAlignment alignment;
  final bool usePanel;

  /// When `true` and the pane has bounded height (expanded viewport),
  /// its content is wrapped in a [SingleChildScrollView] so it scrolls
  /// independently.
  ///
  /// Leave `false` (the default) for panes that manage their own
  /// scrolling (e.g. contain a [ListView]) or use [Expanded] internally.
  /// Panes with a [sliverAppBarBuilder] are always scrollable regardless
  /// of this flag.
  final bool scrollable;

  const AppPane({
    super.key,
    this.flex,
    this.width,
    this.appBarBuilder,
    this.sliverAppBarBuilder,
    required this.child,
    this.bottomBar,
    this.promoteChromeWhenStacked = true,
    this.showWhenStacked = true,
    this.color,
    this.radius = kAppPanelRadius,
    this.padding = EdgeInsets.zero,
    this.maxWidth,
    this.alignment = AppPaneContentAlignment.start,
    this.usePanel = true,
    this.scrollable = false,
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
    final hPad = AppSpacing.of(context).lg;
    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleSpacing: hPad,
          actionsPadding: EdgeInsets.only(right: hPad),
        ),
      ),
      child: appBarBuilder!(context),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final hPad = AppSpacing.of(context).lg;
    final bar = sliverAppBarBuilder!(context);
    return SliverAppBar(
      key: bar.key,
      leading: bar.leading,
      automaticallyImplyLeading: bar.automaticallyImplyLeading,
      title: bar.title,
      actions: bar.actions != null
          ? [...bar.actions!, SizedBox(width: hPad)]
          : null,
      flexibleSpace: bar.flexibleSpace,
      bottom: bar.bottom,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: bar.shadowColor,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      foregroundColor: bar.foregroundColor,
      iconTheme: bar.iconTheme,
      actionsIconTheme: bar.actionsIconTheme,
      primary: bar.primary,
      centerTitle: bar.centerTitle,
      excludeHeaderSemantics: bar.excludeHeaderSemantics,
      titleSpacing: hPad,
      collapsedHeight: bar.collapsedHeight,
      expandedHeight: bar.expandedHeight,
      floating: bar.floating,
      pinned: bar.pinned,
      snap: bar.snap,
      stretch: bar.stretch,
      stretchTriggerOffset: bar.stretchTriggerOffset,
      onStretchTrigger: bar.onStretchTrigger,
      shape: bar.shape,
      toolbarHeight: bar.toolbarHeight,
      toolbarTextStyle: bar.toolbarTextStyle,
      titleTextStyle: bar.titleTextStyle,
      forceMaterialTransparency: bar.forceMaterialTransparency,
      clipBehavior: bar.clipBehavior,
    );
  }

  Widget buildPane({
    required BuildContext context,
    bool includeAppBar = true,
    bool includeBottomBar = true,
    Color? assignedColor,
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

      final useSliverChrome =
          includeAppBar &&
          sliverAppBarBuilder != null &&
          constraints.hasBoundedHeight;

      final Widget bodyContent;
      if (useSliverChrome) {
        bodyContent = CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(child: content),
          ],
        );
      } else if (scrollable && constraints.hasBoundedHeight) {
        // Opt-in: wrap in a scroll view so this pane scrolls
        // independently on expanded viewports.
        bodyContent = SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: content,
        );
      } else {
        bodyContent = content;
      }

      final paneChildren = <Widget>[
        if (!useSliverChrome && includeAppBar && appBarBuilder != null)
          _buildAppBar(context),
        constraints.hasBoundedHeight
            ? Expanded(child: bodyContent)
            : bodyContent,
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

    final resolvedColor = color ?? assignedColor;

    if (!usePanel || resolvedColor == null) {
      // Inject AppPaneTheme even without a visual panel so descendants
      // can call AppPaneTheme.of(context) / .stepped().
      if (resolvedColor != null) {
        return AppPaneTheme(color: resolvedColor, child: body);
      }
      return body;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AppPaneTheme(
        color: resolvedColor,
        child: Material(color: resolvedColor, child: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Standalone usage (outside AppPaneLayout): default to primary tone.
    return buildPane(
      context: context,
      assignedColor:
          color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
    );
  }
}

class AppPaneLayout extends StatelessWidget {
  final List<AppPane> panes;
  final double gap;

  /// The total flex denominator for the horizontal layout.
  ///
  /// When set, if the sum of pane flex values is less than [totalFlex],
  /// the remaining flex is filled with empty space.  This lets a single
  /// pane occupy a fraction of the row — e.g. `totalFlex: 5` with one
  /// `flex: 2` pane gives it 2/5 of the width.
  final int? totalFlex;

  /// How pane background colours are assigned on expanded (web) viewports.
  final AppPaneColorMode colorMode;

  /// How pane backgrounds behave when stacked on compact (mobile) viewports.
  final AppPaneStackMode stackMode;

  const AppPaneLayout({
    super.key,
    required this.panes,
    this.gap = kAppPanelGap,
    this.totalFlex,
    this.colorMode = AppPaneColorMode.autoStepped,
    this.stackMode = AppPaneStackMode.flat,
  });

  /// Resolves the background colour for the pane at [index].
  ///
  /// Returns `null` when [colorMode] is [AppPaneColorMode.flat].
  Color? _resolveColor(BuildContext context, int index) {
    switch (colorMode) {
      case AppPaneColorMode.autoStepped:
        final scale = AppPaneTheme._scale(context);
        // One step below the shell (surfaceContainerHighest) and descend.
        final level = (scale.length - 2 - index).clamp(0, scale.length - 1);
        return scale[level];
      case AppPaneColorMode.flat:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    return layout.isExpanded
        ? _buildHorizontal(context)
        : _buildStacked(context);
  }

  // ---------------------------------------------------------------------------
  // Expanded (web) — side-by-side, each pane scrolls independently.
  // ---------------------------------------------------------------------------

  Widget _buildHorizontal(BuildContext context) {
    final children = <Widget>[];
    var flexSum = 0;

    for (var i = 0; i < panes.length; i++) {
      final pane = panes[i];
      final assignedColor = _resolveColor(context, i);
      final paneWidget = pane.buildPane(
        context: context,
        assignedColor: assignedColor,
      );

      if (pane.width != null) {
        children.add(SizedBox(width: pane.width, child: paneWidget));
      } else {
        children.add(Expanded(flex: pane.flex ?? 1, child: paneWidget));
        flexSum += pane.flex ?? 1;
      }
      if (i < panes.length - 1) {
        children.add(SizedBox(width: gap));
      }
    }

    if (totalFlex != null && flexSum < totalFlex!) {
      children.add(Spacer(flex: totalFlex! - flexSum));
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Compact (mobile) — stacked vertically in a single scroll container.
  // ---------------------------------------------------------------------------

  Widget _buildStacked(BuildContext context) {
    final stackedPanes = panes.where((pane) => pane.showWhenStacked).toList();
    final useTinted = stackMode == AppPaneStackMode.tinted;

    final promotedPane = stackedPanes
        .where((pane) => pane.promoteChromeWhenStacked)
        .firstOrNull;
    final promotedSliverAppBar = promotedPane?.sliverAppBarBuilder;

    final children = <Widget>[];
    for (var i = 0; i < stackedPanes.length; i++) {
      final pane = stackedPanes[i];
      final suppressChrome = identical(pane, promotedPane);

      // In tinted mode, assign the same stepped colour as on web.
      Color? stackedColor;
      if (useTinted) {
        final originalIndex = panes.indexOf(pane);
        stackedColor = _resolveColor(context, originalIndex);
      }

      children.add(
        pane.buildPane(
          context: context,
          includeAppBar: !suppressChrome,
          includeBottomBar: !suppressChrome,
          assignedColor: stackedColor,
        ),
      );
      if (i < stackedPanes.length - 1) {
        children.add(SizedBox(height: gap));
      }
    }

    Widget body;

    if (promotedSliverAppBar != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                promotedPane!._buildSliverAppBar(context),
                SliverList(delegate: SliverChildListDelegate(children)),
              ],
            ),
          ),
          if (promotedPane.bottomBar != null) promotedPane.bottomBar!,
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (promotedPane?.appBarBuilder != null)
            promotedPane!._buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
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

    // Inject a baseline AppPaneTheme so descendants always have a reference.
    // Wrap in Material so ink effects (InkWell, etc.) work without a Scaffold.
    final surfaceColor = Theme.of(context).colorScheme.surface;
    return AppPaneTheme(
      color: surfaceColor,
      child: Material(color: surfaceColor, child: body),
    );
  }
}

/// A layout-level widget that renders different subtrees for expanded
/// (side-by-side) and compact (stacked) viewports.
///
/// Use this when two viewport modes require fundamentally different widget
/// trees that cannot be expressed as a single declarative [AppPaneLayout].
class AppAdaptiveView extends StatelessWidget {
  /// Builder for expanded (wide, side-by-side) viewports.
  final WidgetBuilder expanded;

  /// Builder for compact (narrow, stacked) viewports.
  final WidgetBuilder compact;

  const AppAdaptiveView({
    super.key,
    required this.expanded,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return AppLayoutSpec.of(context).isExpanded
        ? expanded(context)
        : compact(context);
  }
}
