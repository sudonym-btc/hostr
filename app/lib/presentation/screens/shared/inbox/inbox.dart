import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

@RoutePage()
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.inbox)),
      body: SafeArea(
        top: false,
        child: StreamBuilder(
          stream: getIt<Hostr>().messaging.threads.stream,
          builder: (context, snapshot) {
            final threads =
                getIt<Hostr>().messaging.threads.threads.values.toList()..sort(
                  (a, b) => b.state.value.getLastDateTime.compareTo(
                    a.state.value.getLastDateTime,
                  ),
                );
            if (threads.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.noMessagesYet,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return ListView(
              children: [
                for (final thread in threads)
                  InboxItem(key: ValueKey(thread.anchor), thread: thread),
              ],
            );
          },
        ),
      ),
    );
  }
}
