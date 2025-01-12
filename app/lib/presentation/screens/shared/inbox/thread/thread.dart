import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/logic/services/messages/thread.cubit.dart';

import 'thread_view.dart';

@RoutePage()
class ThreadScreen extends StatelessWidget {
  final String id;
  // ignore: use_key_in_widget_constructors
  const ThreadScreen({@pathParam required this.id});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider<ThreadCubit>(
          create: (context) =>
              // context.read<ThreadOrganizer>().getThreadId(),
              ThreadCubit(ThreadCubitState(id: id, messages: []))),
    ], child: ThreadView());
  }
}
