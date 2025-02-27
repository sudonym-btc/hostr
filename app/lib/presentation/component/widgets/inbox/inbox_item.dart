import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/providers/main.dart';

class InboxItemWidget extends StatelessWidget {
  ThreadCubit threadCubit;
  InboxItemWidget({super.key, required this.threadCubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
        builder: (context, state) {
      return BlocBuilder<ModeCubit, ModeCubitState>(
          builder: (context, modeCubitState) {
        return ProfileProvider(
            pubkey: threadCubit.getCounterpartyPubkey(),
            builder: (context, profile) {
              return ListTile(
                title: Text('Rando: ${modeCubitState.runtimeType}'),
                // subtitle: Text(threadCubit.state.data!.lastMessage),
                leading: profile?.picture != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profile!.picture!),
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
