import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/inbox/inbox_item.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class InboxThreadList extends StatelessWidget {
  final String? selectedAnchor;

  const InboxThreadList({super.key, this.selectedAnchor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getIt<Hostr>().messaging.threads.messages$.itemsStream,
      builder: (context, snapshot) {
        final threads = getIt<Hostr>().messaging.threads.threads.values.toList()
          ..sort(
            (a, b) => b.state.value.getLastDateTime.compareTo(
              a.state.value.getLastDateTime,
            ),
          );
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

        return ListView(
          children: [
            for (final thread in threads)
              InboxItem(
                key: ValueKey(thread.anchor),
                thread: thread,
                selected: thread.anchor == selectedAnchor,
              ),
          ],
        );
      },
    );
  }
}
