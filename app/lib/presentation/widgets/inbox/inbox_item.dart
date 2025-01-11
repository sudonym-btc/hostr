import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/services/messages/thread.cubit.dart';
import 'package:hostr/presentation/widgets/main.dart';

class InboxItem extends StatelessWidget {
  ThreadCubit threadCubit;
  InboxItem({super.key, required this.threadCubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
        builder: (context, state) {
      return ProfileProvider(
          id: threadCubit.state!.id,
          builder: (context, state) {
            // var name =
            //     state.data?.parsedContent.name ?? threadCubit.state.data!.id;
            return ListTile(
              title: Text('Rando'),
              // subtitle: Text(threadCubit.state.data!.lastMessage),
              leading: CircleAvatar(
                backgroundImage:
                    NetworkImage(state.data!.parsedContent.picture!),
              ),
              onTap: () {
                // context
                //     .read<MessagesCubit>()
                //     .setThread(threadCubit.state.data!);
                // Navigator.of(context).pushNamed('/messages');
              },
            );
          });
    });
  }
}
