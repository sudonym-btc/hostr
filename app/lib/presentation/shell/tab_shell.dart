import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// Pure tab-persistence shell.
///
/// Wraps the navigation-destination routes in an [AutoTabsRouter] +
/// [IndexedStack] so that switching between tabs preserves each tab's state.
///
/// Contains **zero** navigation chrome — the parent [AppShellScreen] is
/// responsible for rendering the sidebar or bottom navigation bar.
@RoutePage()
class TabShellScreen extends StatelessWidget {
  const TabShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
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

            return AutoTabsRouter.builder(
              key: ValueKey('tabs_$isLoggedIn'),
              routes: [
                for (final destination in destinations) destination.route,
              ],
              builder: (context, children, tabsRouter) {
                return IndexedStack(
                  index: tabsRouter.activeIndex,
                  children: children,
                );
              },
            );
          },
        );
      },
    );
  }
}
