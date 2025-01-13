import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: InboxItemWidget)
Widget inboxItem(BuildContext context) {
  return Align(
      alignment: Alignment.center,
      child: BlocProvider<ThreadCubit>(
          create: (context) =>
              ThreadCubit(ThreadCubitState(id: 'hi', messages: [])),
          child: BlocBuilder<ThreadCubit, ThreadCubitState>(
            builder: (context, state) =>
                InboxItemWidget(threadCubit: context.read<ThreadCubit>()),
          )));
}
