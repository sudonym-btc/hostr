import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/logic/main.dart'
    show EntityCubitStateError, LatestThreadState, ThreadCubit;
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/router.dart';

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
    return ListTile(
      leading: Icon(Icons.account_circle),
      title: ProfileProvider(
          pubkey: threadCubit.getCounterpartyPubkey(),
          builder: (context, state) {
            print('state: $state');

            if (state is EntityCubitStateError) {
              return Text('Error: ${(state as EntityCubitStateError).error}');
            }
            if (state == null) {
              return CircularProgressIndicator();
            }
            return state.name != null
                ? Text(state.name!)
                : Text(threadCubit.getCounterpartyPubkey());
          }),
      subtitle: subtitle,
      onTap: () {
        AutoRouter.of(context).push(ThreadRoute(id: threadCubit.getAnchor()));
      },
    );
  }
}
