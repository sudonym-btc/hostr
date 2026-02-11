import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_view.dart';
import 'package:hostr_sdk/hostr.dart';

@RoutePage()
class ThreadScreen extends StatelessWidget {
  final String anchor;
  // ignore: use_key_in_widget_constructors
  const ThreadScreen({@pathParam required this.anchor});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThreadCubit>(
      create: (_) => ThreadCubit(
        thread: getIt<Hostr>().messaging.threads.threads[anchor]!,
      ),
      child: ThreadView(),
    );
  }
}
