import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/inbox/inbox_thread_list.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';

@RoutePage()
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoRouter(
      builder: (context, child) {
        final router = AutoRouter.of(context);
        final hasSelectedThread = router.topRoute.name == ThreadRoute.name;
        final selectedAnchor = hasSelectedThread
            ? router.topMatch.params.optString('anchor')
            : null;

        return Scaffold(
          body: SafeArea(
            top: false,
            child: AppPageGutter(
              maxWidth: kAppWideContentMaxWidth,
              padding: EdgeInsets.zero,
              child: AppPaneLayout(
                panes: [
                  AppPane(
                    flex: 2,
                    panelTone: AppPanelTone.primary,
                    appBarBuilder: (context) => AppBar(
                      automaticallyImplyLeading: false,
                      title: Text(AppLocalizations.of(context)!.inbox),
                    ),
                    promoteChromeWhenStacked: true,
                    child: InboxThreadList(
                      selectedAnchor: selectedAnchor,
                      onThreadSelected: (anchor) {
                        router.navigate(
                          InboxRoute(children: [ThreadRoute(anchor: anchor)]),
                        );
                      },
                    ),
                  ),
                  AppPane(
                    flex: 3,
                    showWhenStacked: false,
                    child: hasSelectedThread
                        ? child
                        : EmtyResultsWidget(
                            leading: Icon(
                              Icons.forum_outlined,
                              size: kIconHero,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: 'Select a conversation',
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
