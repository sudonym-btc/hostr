import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart'
    show ThreadCubit, ThreadCubitState;

import 'thread_view.dart';

@RoutePage()
class ThreadScreen extends StatelessWidget {
  final String id;
  // ignore: use_key_in_widget_constructors
  const ThreadScreen({@pathParam required this.id});

  @override
  Widget build(BuildContext context) {
    // Get messages for this thread from ThreadedMessagesCubit
    final threads = getIt<NostrService>().messaging.threads;

    // Create ThreadCubit on-demand for this thread
    return BlocProvider(
      create: (_) => ThreadCubit(
        ThreadCubitState(id: id, messages: []),
        nostrService: getIt<NostrService>(),
        thread: threads.threads[id]!,
      ),
      child: ThreadView(a: id),
    );
  }
}
