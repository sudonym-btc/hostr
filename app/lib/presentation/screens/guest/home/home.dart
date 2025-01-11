import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/router.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: [SearchRoute(), InboxRoute(), ProfileRoute()],
      // bottomNavigationBuilder: (context, tabsRouter) =>
      //     SalomonBottomBar(
      //         currentIndex: tabsRouter.activeIndex,
      //         onTap: tabsRouter.setActiveIndex,
      //         margin: EdgeInsets.symmetric(
      //             vertical: 40, horizontal: 20),
      //         items: [
      //       SalomonBottomBarItem(
      //           icon: Icon(Icons.search, size: 30),
      //           title: const Text('Search')),
      //       SalomonBottomBarItem(
      //           icon: Icon(Icons.inbox, size: 30),
      //           title: const Text('Inbox')),
      //       SalomonBottomBarItem(
      //           icon: Icon(Icons.person, size: 30),
      //           title: const Text('Settings'))
      //     ]),
    );
  }
}
