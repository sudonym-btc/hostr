import 'package:auto_route/auto_route.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/widgets/main.dart';

@RoutePage()
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
      ),
      body: Center(
          child: ListWidget(
        builder: (el) =>
            MessageInboxItem(thread: MessageType0.fromNostrEvent(el)),
        emptyText: 'No messages',
        list: () => ListCubit(getIt<MessageRepository>())
          ..setFilter(NostrFilter()), // todo: must be enquiry tag
      )),
    );
  }
}
