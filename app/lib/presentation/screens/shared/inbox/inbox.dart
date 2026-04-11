import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/widgets/inbox/inbox_thread_list.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

@RoutePage()
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  /// Cached cubits keyed by thread anchor so profile metadata survives
  /// navigation between the thread list and individual threads.
  final Map<String, ThreadCubit> _cubits = {};

  ThreadCubit cubitFor(Thread thread) {
    return _cubits.putIfAbsent(
      thread.anchor,
      () => ThreadCubit(thread: thread),
    );
  }

  /// Close cubits whose threads are no longer in the list.
  void pruneStale(Set<String> activeAnchors) {
    final stale = _cubits.keys
        .where((k) => !activeAnchors.contains(k))
        .toList();
    for (final key in stale) {
      _cubits.remove(key)?.close();
    }
  }

  @override
  void dispose() {
    for (final cubit in _cubits.values) {
      cubit.close();
    }
    _cubits.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoRouter(
      builder: (context, child) {
        final router = AutoRouter.of(context);
        final hasSelectedThread = router.topRoute.name == ThreadRoute.name;
        final selectedAnchor = hasSelectedThread
            ? router.topMatch.params.optString('anchor')
            : null;
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
                    cubitFor: cubitFor,
                    pruneStale: pruneStale,
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
