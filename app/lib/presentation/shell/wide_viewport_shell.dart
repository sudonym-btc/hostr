import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

@RoutePage()
class WideViewportShellScreen extends StatelessWidget {
  const WideViewportShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    if (!layout.showsSidebarNavigation) {
      return const AutoRouter();
    }

    return StreamBuilder<AuthState>(
      stream: getIt<Hostr>().auth.authState,
      initialData: getIt<Hostr>().auth.authState.value,
      builder: (context, authSnapshot) {
        final isLoggedIn = authSnapshot.data == const LoggedIn();

        return BlocBuilder<ModeCubit, ModeCubitState>(
          builder: (context, modeState) {
            final destinations = buildAppNavigationDestinations(
              isLoggedIn: isLoggedIn,
              modeState: modeState,
            );

            return AutoRouter(
              builder: (context, child) {
                final router = AutoRouter.of(context);
                final selectedIndex = resolveAppNavigationIndex(
                  currentRouteName: router.topRoute.name,
                  destinations: destinations,
                  isLoggedIn: isLoggedIn,
                  modeState: modeState,
                );

                return AppWideNavigationScaffold(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    router.replaceAll([
                      AppShellRoute(children: [destinations[index].route]),
                    ]);
                  },
                  child: child,
                );
              },
            );
          },
        );
      },
    );
  }
}
