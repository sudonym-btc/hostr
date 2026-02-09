import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/logic/main.dart' show EntityCubitStateError;
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:timeago/timeago.dart' as timeago;

class InboxItem extends StatelessWidget {
  final Thread thread;

  const InboxItem({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    final counterpartyPubkey = thread.counterpartyPubkey();
    final lastDateTime = thread.getLastDateTime();
    final subtitle = Text(thread.isLastMessageOurs() ? 'Sent' : 'Received');

    return ProfileProvider(
      pubkey: counterpartyPubkey,
      builder: (context, snapshot) {
        if (snapshot.data is EntityCubitStateError) {
          return Text(
            'Error: ${(snapshot.data as EntityCubitStateError).error}',
          );
        }
        if (snapshot.data == null) {
          return ListTile(
            leading: CircularProgressIndicator(),
            title: Text(
              counterpartyPubkey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: subtitle,
            onTap: () {
              AutoRouter.of(context).push(ThreadRoute(anchor: thread.anchor));
            },
          );
        }
        return ListTile(
          leading: snapshot.data!.metadata.picture != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(
                    snapshot.data!.metadata.picture!,
                  ),
                )
              : Icon(Icons.account_circle),
          title: snapshot.data!.metadata.name != null
              ? Text(snapshot.data!.metadata.name!)
              : Text(counterpartyPubkey),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              subtitle,
              Text(timeago.format(lastDateTime, locale: 'en_short')),
            ],
          ),
          onTap: () {
            AutoRouter.of(context).push(ThreadRoute(anchor: thread.anchor));
          },
        );
      },
    );
  }
}
