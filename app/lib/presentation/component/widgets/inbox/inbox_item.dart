import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/providers/main.dart';

class InboxItem extends StatelessWidget {
  ThreadCubit threadCubit;
  InboxItem({super.key, required this.threadCubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
        builder: (context, state) {
      return BlocBuilder<ModeCubit, ModeCubitState>(
          builder: (context, modeCubitState) {
        print('modeCubitState: $modeCubitState');
        return ProfileProvider(
            e: threadCubit.state!.id,
            builder: (context, profile) {
              // var name =
              //     state.data?.parsedContent.name ?? threadCubit.state.data!.id;
              return ListTile(
                title: Text('Rando: ${modeCubitState.runtimeType}'),
                // subtitle: Text(threadCubit.state.data!.lastMessage),
                leading: profile.data?.parsedContent.picture != null
                    ? CircleAvatar(
                        backgroundImage:
                            NetworkImage(profile.data!.parsedContent.picture!),
                      )
                    : CircleAvatar(
                        backgroundColor: Colors.grey,
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
    });
  }
}
