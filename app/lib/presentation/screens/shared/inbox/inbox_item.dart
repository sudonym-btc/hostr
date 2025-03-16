import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/logic/main.dart'
    show EntityCubitStateError, LatestThreadState, ThreadCubit;
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/router.dart';
import 'package:timeago/timeago.dart' as timeago;

class InboxItem extends StatelessWidget {
  final ThreadCubit threadCubit;

  const InboxItem({super.key, required this.threadCubit});

  @override
  Widget build(BuildContext context) {
    Widget subtitle;
    switch (threadCubit.getLatestState()) {
      case LatestThreadState.MESSAGE_SENT:
        subtitle = Text('Sent');
      case LatestThreadState.MESSAGE_RECEIVED:
        subtitle = Text('Received');
      case LatestThreadState.RESERVATION_REQUEST_RECEIVED:
        subtitle = Text('Reservation Request Received');
      case LatestThreadState.RESERVATION_REQUEST_SENT:
        subtitle = Text('Reservation Request Sent');
      default:
        subtitle = Text('Could not determine state');
    }
    return ProfileProvider(
        pubkey: threadCubit.getCounterpartyPubkey(),
        builder: (context, snapshot) {
          if (snapshot.data is EntityCubitStateError) {
            return Text(
                'Error: ${(snapshot.data as EntityCubitStateError).error}');
          }
          if (snapshot.data == null) {
            return ListTile(
                leading: CircularProgressIndicator(),
                title: Text(threadCubit.getCounterpartyPubkey(),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: subtitle,
                onTap: () {
                  AutoRouter.of(context)
                      .push(ThreadRoute(id: threadCubit.getAnchor()));
                });
          }
          return ListTile(
              leading: snapshot.data!.picture != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(snapshot.data!.picture!))
                  : Icon(Icons.account_circle),
              title: snapshot.data!.name != null
                  ? Text(snapshot.data!.name!)
                  : Text(threadCubit.getCounterpartyPubkey()),
              subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    subtitle,
                    Text(timeago.format(threadCubit.getLastDateTime(),
                        locale: 'en_short'))
                  ]),
              onTap: () {
                AutoRouter.of(context)
                    .push(ThreadRoute(id: threadCubit.getAnchor()));
              });
        });
  }
}
