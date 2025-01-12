import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/services/messages/thread.cubit.dart';
import 'package:hostr/presentation/screens/shared/inbox/thread/thread_header.dart';

class ThreadView extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const ThreadView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ThreadHeader(title: 'hi', subtitle: 'there'),
        BlocBuilder<ThreadCubit, ThreadCubitState>(builder: (context, state) {
          return ListView.builder(itemBuilder: (listContext, index) {
            return ListTile(
              title: Text('Rando'),
              subtitle: Text(state.messages[index].content!),
              leading: CircleAvatar(
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
        }),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Reply',
          ),
        ),
      ],
    );
  }
}
