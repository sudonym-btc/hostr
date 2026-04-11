import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/widgets/inbox/inbox_item.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class InboxThreadList extends StatelessWidget {
  final String? selectedAnchor;
  final ValueChanged<String> onThreadSelected;

  /// Obtain (or create) a [ThreadCubit] for a given thread.
  /// Provided by the parent [InboxScreen] so the cache outlives this widget.
  final ThreadCubit Function(Thread thread) cubitFor;

  /// Prune cubits for threads that no longer exist.
  /// Provided by the parent [InboxScreen].
  final void Function(Set<String> activeAnchors) pruneStale;

  const InboxThreadList({
    super.key,
    this.selectedAnchor,
    required this.onThreadSelected,
    required this.cubitFor,
    required this.pruneStale,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getIt<Hostr>().messaging.threads.messages$.itemsStream,
      builder: (context, snapshot) {
        final threads =
            getIt<Hostr>().messaging.threads.threads.values
                .where((thread) => thread.state.value.messages.isNotEmpty)
                .toList()
              ..sort(
                (a, b) => b.state.value.getLastDateTime.compareTo(
                  a.state.value.getLastDateTime,
                ),
              );

        // Remove cubits for threads that no longer exist.
        pruneStale(threads.map((t) => t.anchor).toSet());

        if (threads.isEmpty) {
          return EmtyResultsWidget(
            leading: Icon(
              Icons.inbox_outlined,
              size: kIconHero,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: AppLocalizations.of(context)!.noMessagesYet,
            subtitle:
                'Your conversations with guests and hosts will appear here.',
          );
        }

        final items = threads
            .map(
              (thread) => InboxItem(
                key: ValueKey(thread.anchor),
                cubit: cubitFor(thread),
                thread: thread,
                selected: thread.anchor == selectedAnchor,
                onSelect: onThreadSelected,
              ),
            )
            .toList();

        return ListView(padding: EdgeInsets.zero, children: items);
      },
    );
  }
}
