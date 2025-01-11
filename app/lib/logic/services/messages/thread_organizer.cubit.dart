// class ThreadOrganizer extends Cubit<ThreadsState> {
//   final GlobalMessageCubit globalMessageCubit = getIt<GlobalMessageCubit>();
//   // ThreadOrganizer(super.initialState) {
//   //   /// As soon as the cubit is created, we sort the initial messages and subscribe to incoming
//   //   for (final nostrEvent in globalMessageCubit.state.results) {
//   //     sortMessage(nostrEvent);
//   //   }
//   //   globalMessageCubit.itemStream.listen(sortMessage);
//   // }

//   // void sortMessage(NostrEvent event) {
//   //   final threads = state.threads;
//   //   threads.add(thread);
//   //   emit(ThreadsState(threads: threads, selectedThread: state.selectedThread));
//   // }

//   // String getThreadId(NostrEvent event) {
//   //   return
//   // }
// }

// class ThreadsState {
//   final List<Thread> threads;
//   final Thread? selectedThread;

//   ThreadsState({required this.threads, this.selectedThread});
// }

// class Thread {
//   final NostrEvent event;
//   final List<NostrEvent> messages;

//   Thread({required this.event, this.messages = const []});
// }
