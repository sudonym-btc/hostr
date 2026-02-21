import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/export.dart';
import 'package:hostr/router.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _itemTopPadding = kDefaultPadding / 2;

  BottomNavigationBarItem _navItem({
    required Widget icon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: _itemTopPadding),
        child: icon,
      ),
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
    final borderRadius = BorderRadius.circular(50);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: navBg,
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: min(items.length - 1, tabsRouter.activeIndex),
          onTap: tabsRouter.setActiveIndex,
          items: items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModeCubit, ModeCubitState>(
      builder: (context, state) {
        final bottomSheetTheme = Theme.of(context).bottomSheetTheme;
        final navBg =
            bottomSheetTheme.modalBackgroundColor ??
            bottomSheetTheme.backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerLow;

        if (state is HostMode) {
          final hostTabs = [
            _navItem(icon: Icon(Icons.list), label: 'My Listings'),
            _navItem(icon: Icon(Icons.inbox), label: 'Inbox'),
            _navItem(icon: Icon(Icons.person), label: 'Profile'),
          ];
          return AutoTabsScaffold(
            key: const ValueKey('hostTabs'),
            routes: [MyListingsRoute(), InboxRoute(), ProfileRoute()],
            bottomNavigationBuilder: (context, tabsRouter) =>
                _buildBottomNav(context, tabsRouter, hostTabs, navBg),
          );
        }
        final otherTabs = [
          _navItem(icon: Icon(Icons.search, size: 30), label: 'Search'),
          _navItem(icon: Icon(Icons.travel_explore), label: 'Trips'),
          _navItem(icon: Icon(Icons.inbox), label: 'Inbox'),
          _navItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
        return AutoTabsScaffold(
          key: const ValueKey('guestTabs'),
          routes: [SearchRoute(), TripsRoute(), InboxRoute(), ProfileRoute()],
          bottomNavigationBuilder: (context, tabsRouter) =>
              _buildBottomNav(context, tabsRouter, otherTabs, navBg),
        );
      },
    );

    // );
  }
}
