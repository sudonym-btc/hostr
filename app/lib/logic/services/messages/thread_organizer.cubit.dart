import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/nostr/nostr/nostr.service.dart';
import 'package:hostr/logic/services/thread_routing_service.dart';
import 'package:models/main.dart';

import 'global_gift_wrap.cubit.dart';
import 'thread.cubit.dart';

/// Cubit organizing messages into threads.
/// Routing logic delegated to ThreadRoutingService.
/// This cubit manages ThreadCubit instances and UI state.
class ThreadOrganizerCubit<T extends Event>
    extends Cubit<ThreadOrganizerState> {
  CustomLogger logger = CustomLogger();
  final GlobalGiftWrapCubit? globalMessageCubit;
  final NostrService nostrService;
  final ThreadRoutingService _routingService;
  
  ThreadOrganizerCubit({
    this.globalMessageCubit,
    required this.nostrService,
    required ThreadRoutingService routingService,
  })  : _routingService = routingService,
        super(ThreadOrganizerState(threads: [])) {
    if (globalMessageCubit != null) {
      logger.d("Setting up listeners for ThreadOrganizerCubit");

      /// As soon as the cubit is created, we sort the initial messages and subscribe to incoming
      for (final nostrEvent in globalMessageCubit!.state.results) {
        logger.i("Received event: $nostrEvent");

        // if (nostrEvent.child is Seal<T>) {
        //   sortMessage(nostrEvent);
        // }
      }
      globalMessageCubit!.itemStream.listen((element) {
        logger.i("Received event: $element");
        // if (element.child is Seal<T>) {
        //   // Safely cast `element` to the desired type
        //   sortMessage(element);
        // } else {
        //   logger.i("Discarding event: $element");
        // }
      });
    }
  }

  /// Attempt to add message to existing thread, if not found, create new thread.
  /// Routing logic delegated to service.
  void sortMessage(Event event) {
    // Business decision: should we route this event?
    if (!_routingService.shouldRouteToThread(event)) {
      logger.i("Event should not be routed: $event");
      return;
    }

    final threadId = _routingService.extractThreadId(event);
    if (threadId == null) {
      logger.i("No thread id found for event $event");
      return;
    }

    logger.i("Sorting message with thread ID: $threadId");
    final threads = state.threads;
    
    threads.firstWhere(
      (thread) => thread.state.id == threadId,
      orElse: () {
        // Business decision: create new thread
        ThreadCubit newThreadCubit = ThreadCubit(
          ThreadCubitState(id: threadId, messages: []),
          nostrService: nostrService,
        );
        threads.add(newThreadCubit);
        logger.i("Created new thread: $threadId");

        emit(
          ThreadOrganizerState(
            threads: threads,
            selectedThread: state.selectedThread,
          ),
        );
        return newThreadCubit;
      },
    );

    // threadCubit.addMessage((event.child as Seal).child as Message);
  }

  String? getThreadId(Event event) {
    // Delegate to service
    return _routingService.extractThreadId(event);
  }
}

class ThreadOrganizerState {
  final List<ThreadCubit> threads;
  final ThreadCubit? selectedThread;

  ThreadOrganizerState({required this.threads, this.selectedThread});
}
