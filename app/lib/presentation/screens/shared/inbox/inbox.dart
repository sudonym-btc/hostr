import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/services/main.dart';
import 'package:hostr/presentation/screens/shared/inbox/inbox_item.dart';

@RoutePage()
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Inbox'),
        ),
        body: BlocBuilder<ThreadOrganizerCubit, ThreadOrganizerState>(
            builder: (context, state) {
          print(' Thread organizer: ${state.threads}');
          return ListView.builder(
              itemCount: state.threads.length,
              itemBuilder: (context, index) {
                return InboxItem(
                  threadCubit: state.threads[index],
                );
              });
        }));
  }
}
