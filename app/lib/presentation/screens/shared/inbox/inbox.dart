import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/inbox/inbox_thread_list.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';

@RoutePage()
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    return AutoRouter(
      builder: (context, child) {
        final router = AutoRouter.of(context);
        var selectedAnchor = router.topRoute.name == ThreadRoute.name
            ? router.topMatch.params.optString('anchor')
            : null;
        for (final segment in router.currentSegments.reversed) {
          if (segment.name == ThreadRoute.name) {
            selectedAnchor = segment.params.optString('anchor');
            break;
          }
        }
        final hasSelectedThread = selectedAnchor != null;
        final isExpanded = AppLayoutSpec.of(context).isExpanded;

        // On compact viewports, let AutoRouter push ThreadScreen as a
        // normal route — this gives a proper back button and transition.
        if (hasSelectedThread && !isExpanded) {
          return child;
        }

        return SafeArea(
          top: false,
          child: AppPageGutter(
            maxWidth: kAppWideContentMaxWidth,
            padding: EdgeInsets.zero,
            child: AppPaneLayout(
              panes: [
                AppPane(
                  flex: 2,
                  appBarBuilder: (context) => AppBar(
                    automaticallyImplyLeading: false,
                    title: Text(AppLocalizations.of(context)!.inbox),
                  ),
                  promoteChromeWhenStacked: true,
                  child: InboxThreadList(
                    selectedAnchor: selectedAnchor,
                    onThreadSelected: (anchor) {
                      final route = ThreadRoute(anchor: anchor);
                      if (hasSelectedThread) {
                        router.replace(route);
                      } else {
                        router.push(route);
                      }
                    },
                  ),
                ),
                AppPane(
                  flex: 3,
                  showWhenStacked: false,
                  appBarBuilder: hasSelectedThread
                      ? null
                      : (context) => AppBar(automaticallyImplyLeading: false),
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
        );
      },
    );
  }
}
