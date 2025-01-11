import 'package:flutter/material.dart';
import 'package:hostr/logic/services/messages/thread.cubit.dart';
import 'package:hostr/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: InboxItem)
Widget inboxItem(BuildContext context) {
  ThreadCubit threadCubit =
      ThreadCubit(ThreadCubitState(id: 'hi', messages: []));
  return InboxItem(threadCubit: threadCubit);
}
