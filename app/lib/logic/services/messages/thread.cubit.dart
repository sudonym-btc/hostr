import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThreadCubit extends Cubit<ThreadCubitState> {
  ThreadCubit(ThreadCubitState initialState) : super(initialState);

  addMessage(NostrEvent message) {
    final messages = state.messages;
    messages.add(message);
    emit(ThreadCubitState(id: state.id, messages: messages));
  }
}

class ThreadCubitState {
  final String id;
  final List<NostrEvent> messages;

  ThreadCubitState({required this.id, required this.messages});
}
