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
      body: StreamBuilder(
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
              child: Text(AppLocalizations.of(context)!.noMessagesYet),
            );
          }
          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              return InboxItem(
                key: ValueKey(threads[index].anchor),
                thread: threads[index],
              );
            },
          );
        },
      ),
    );
  }
}
