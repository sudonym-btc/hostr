import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/main.dart';

@RoutePage()
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.inbox)),
      body: StreamBuilder(
        stream: getIt<Hostr>().messaging.threads.threadStream,
        builder: (context, snapshot) {
          final threads = getIt<Hostr>().messaging.threads.threads.values
              .toList();
          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              return InboxItem(thread: threads[index]);
            },
          );
        },
      ),
    );
  }
}
