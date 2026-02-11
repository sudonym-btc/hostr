import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:timeago/timeago.dart' as timeago;

class InboxItem extends StatelessWidget {
  final Thread thread;

  const InboxItem({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    final lastDateTime = thread.getLastDateTime();
    final subtitle = Text(thread.isLastMessageOurs() ? 'Sent' : 'Received');

    return BlocProvider(
      create: (_) => ThreadCubit(thread: thread),
      child: BlocBuilder<ThreadCubit, ThreadCubitState>(
        builder: (context, state) {
          return ListTile(
            leading: ProfileAvatars(
              profiles: state.counterpartyStates
                  .where((c) => c.data != null)
                  .map((c) => c.data!)
                  .toList(),
            ),
            title: Text(
              state.counterpartyStates
                  .where((c) => c.data != null)
                  .map((c) => c.data!.metadata.getName())
                  .toList()
                  .join(','),
            ),

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
      ),
    );
  }
}
