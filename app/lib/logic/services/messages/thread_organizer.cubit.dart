import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/messages/thread.cubit.dart';

import 'global_gift_wrap.cubit.dart';

class ThreadOrganizer extends Cubit<ThreadOrganizerState> {
  final GlobalGiftWrapCubit globalMessageCubit = getIt<GlobalGiftWrapCubit>();
  ThreadOrganizer(super.initialState) {
    /// As soon as the cubit is created, we sort the initial messages and subscribe to incoming
    for (final nostrEvent in globalMessageCubit.state.results) {
      sortMessage(nostrEvent);
    }
    globalMessageCubit.itemStream.listen(sortMessage);
  }

  /// Attempt to add message to existing thread, if not found, create new thread
  void sortMessage(NostrEvent event) {
    final threads = state.threads;
    final ThreadCubit threadCubit = threads.firstWhere(
        (thread) => thread.state.id == getThreadId(event), orElse: () {
      ThreadCubit newThreadCubit =
          ThreadCubit(ThreadCubitState(id: getThreadId(event), messages: []));
      threads.add(newThreadCubit);
      emit(ThreadOrganizerState(
          threads: threads, selectedThread: state.selectedThread));
      return newThreadCubit;
    });

    threadCubit.addMessage(event);
  }

  String getThreadId(NostrEvent event) {
    return event.tags!.firstWhere(
      (tag) => tag[0] == 'a',
      orElse: () {
        throw Exception('No thread id found');
      },
    )[1];
  }
}

class ThreadOrganizerState {
  final List<ThreadCubit> threads;
  final ThreadCubit? selectedThread;

  ThreadOrganizerState({required this.threads, this.selectedThread});
}
