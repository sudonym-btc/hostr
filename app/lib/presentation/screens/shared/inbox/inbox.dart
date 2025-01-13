import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/services/main.dart';

@RoutePage()
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Inbox'),
        ),
        body: BlocProvider<ThreadOrganizerCubit>(
            create: (context) => ThreadOrganizerCubit(),
            child: BlocBuilder<ThreadOrganizerCubit, ThreadOrganizerState>(
                builder: (context, state) {
              return ListView.builder(
                  itemCount: state.threads.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Example thread'),
                      onTap: () {
                        // context
                        //     .read<ThreadOrganizer>()
                        //     .selectThread(state.threads[index]);
                        context.router.pushNamed('/inbox/thread');
                      },
                    );
                  });
            })));
  }
}
