import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/inbox/inbox_thread_list.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_view.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

@RoutePage()
class ThreadScreen extends StatelessWidget {
  final String anchor;
  // ignore: use_key_in_widget_constructors
  const ThreadScreen({@pathParam required this.anchor});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);

    return BlocProvider<ThreadCubit>(
      create: (_) => ThreadCubit(
        thread: getIt<Hostr>().messaging.threads.threads[anchor]!,
      ),
      child: layout.showsInboxSplit
          ? StreamBuilder<AuthState>(
              stream: getIt<Hostr>().auth.authState,
              initialData: getIt<Hostr>().auth.authState.value,
              builder: (context, authSnapshot) {
                final destinations = buildAppNavigationDestinations(
                  isLoggedIn: authSnapshot.data == const LoggedIn(),
                  modeState: context.watch<ModeCubit>().state,
                );
                final inboxIndex = destinations.indexWhere(
                  (destination) =>
                      destination.route.routeName == InboxRoute.name,
                );

                return AppWideNavigationScaffold(
                  destinations: destinations,
                  selectedIndex: inboxIndex == -1 ? 0 : inboxIndex,
                  onDestinationSelected: (index) =>
                      context.router.navigate(destinations[index].route),
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(AppLocalizations.of(context)!.inbox),
                    ),
                    body: SafeArea(
                      top: false,
                      child: AppConstrainedBody(
                        maxWidth: kAppWideContentMaxWidth,
                        padding: const EdgeInsets.fromLTRB(
                          kSpace5,
                          kSpace4,
                          kSpace5,
                          kSpace4,
                        ),
                        child: AppTwoPane(
                          primaryWidth: kAppInboxListPaneWidth,
                          primary: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Material(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                              child: InboxThreadList(selectedAnchor: anchor),
                            ),
                          ),
                          secondary: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Material(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                              child: const ThreadView(embedded: true),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          : const ThreadView(),
    );
  }
}
