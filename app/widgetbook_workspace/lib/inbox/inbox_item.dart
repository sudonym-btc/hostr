import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging/thread.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: InboxItemWidget)
Widget inboxItem(BuildContext context) {
  return Align(
    alignment: Alignment.center,
    child: BlocProvider<ThreadCubit>(
      create: (context) => ThreadCubit(
        ThreadCubitState(id: 'hi', messages: []),
        nostrService: getIt<NostrService>(),
        thread: Thread(
          'hi',
          messaging: getIt<NostrService>().messaging,
          accounts: getIt<NostrService>().messaging.ndk.accounts,
        ),
      ),
      child: BlocBuilder<ThreadCubit, ThreadCubitState>(
        builder: (context, state) =>
            InboxItemWidget(threadCubit: context.read<ThreadCubit>()),
      ),
    ),
  );
}
