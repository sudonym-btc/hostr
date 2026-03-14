import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/inbox/inbox_thread_list.dart';
import 'package:hostr/presentation/layout/app_layout.dart';

@RoutePage()
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.inbox)),
      body: SafeArea(
        top: false,
        child: layout.showsInboxSplit
            ? AppConstrainedBody(
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
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: const InboxThreadList(),
                    ),
                  ),
                  secondary: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: kIconHero,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: kSpace4),
                              Text(
                                'Select a conversation',
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: kSpace2),
                              Text(
                                'Messages stay visible alongside the selected thread on wide layouts.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const InboxThreadList(),
      ),
    );
  }
}
