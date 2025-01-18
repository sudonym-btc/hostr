import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/logic/main.dart' show LatestThreadState, ThreadCubit;
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
          e: threadCubit.getCounterpartyPubkey(),
          builder: (context, state) {
            if (state.data == null) {
              return CircularProgressIndicator();
            }
            return state.data?.parsedContent.name != null
                ? Text(state.data!.parsedContent.name!)
                : Text(threadCubit.getCounterpartyPubkey());
          }),
      subtitle: subtitle,
      onTap: () async {
        // context
        //     .read<ThreadOrganizer>()
        //     .selectThread(state.threads[index]);
        print('Thread id: ${threadCubit.getAnchor()}' +
            'inbox/${threadCubit.getAnchor()}');
        AutoRouter.of(context).push(ThreadRoute(id: threadCubit.getAnchor()));
      },
    );
  }
}
