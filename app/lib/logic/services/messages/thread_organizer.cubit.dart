import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/models/nostr_kind/event.dart';

import 'global_gift_wrap.cubit.dart';
import 'thread.cubit.dart';

class ThreadOrganizerCubit<T extends Event>
    extends Cubit<ThreadOrganizerState> {
  CustomLogger logger = CustomLogger();
  final GlobalGiftWrapCubit? globalMessageCubit;
  ThreadOrganizerCubit({this.globalMessageCubit})
      : super(ThreadOrganizerState(threads: [])) {
    if (globalMessageCubit != null) {
      logger.d("Setting up listeners for ThreadOrganizerCubit");

      /// As soon as the cubit is created, we sort the initial messages and subscribe to incoming
      for (final nostrEvent in globalMessageCubit!.state.results) {
        logger.i("Received event: $nostrEvent");

        if (nostrEvent.child is Seal<T>) {
          sortMessage(nostrEvent);
        }
      }
      globalMessageCubit!.itemStream.listen((element) {
        logger.i("Received event: $element");
        if (element.child is Seal<T>) {
          // Safely cast `element` to the desired type
          sortMessage(element);
        } else {
          logger.i("Discarding event: $element");
        }
      });
    }
  }

  /// Attempt to add message to existing thread, if not found, create new thread
  void sortMessage(GiftWrap event) {
    final threads = state.threads;
    if (getThreadId(event) == null) {
      logger.i("No thread id found for event $event");
      return;
    }
    logger.i("Sorting message with anchor $event");
    final ThreadCubit threadCubit = threads.firstWhere(
        (thread) => thread.state.id == getThreadId(event), orElse: () {
      ThreadCubit newThreadCubit =
          ThreadCubit(ThreadCubitState(id: getThreadId(event)!, messages: []));
      threads.add(newThreadCubit);
      logger.i("Emitting $threads");

      emit(ThreadOrganizerState(
          threads: threads, selectedThread: state.selectedThread));
      return newThreadCubit;
    });

    threadCubit.addMessage(event);
  }

  String? getThreadId(GiftWrap event) {
    if (event.child is Seal && (event.child as Seal).child is Event) {
      return ((event.child as Seal).child as Event).anchor;
    }
    logger.i(
        "No thread id found for event ${event.child.runtimeType}, ${event.child.runtimeType},${(event.child as Seal).child.runtimeType}, $event");
  }
}

class ThreadOrganizerState {
  final List<ThreadCubit> threads;
  final ThreadCubit? selectedThread;

  ThreadOrganizerState({required this.threads, this.selectedThread});
}
