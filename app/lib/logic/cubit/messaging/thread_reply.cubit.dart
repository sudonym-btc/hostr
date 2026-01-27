import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging/thread.dart';

enum ThreadReplyStatus { initial, loading, success, error }

class ThreadReplyState {
  final ThreadReplyStatus status;
  final String? error;

  ThreadReplyState({required this.status, this.error});

  ThreadReplyState copyWith({ThreadReplyStatus? status, String? error}) {
    return ThreadReplyState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

class ThreadReplyCubit extends Cubit<ThreadReplyState> {
  final Thread thread;
  ThreadReplyCubit({required this.thread})
    : super(ThreadReplyState(status: ThreadReplyStatus.initial));

  Future<void> sendReply({
    required String message,
    required String threadAnchor,
    required String counterpartyPubkey,
  }) async {
    emit(ThreadReplyState(status: ThreadReplyStatus.loading));
    try {
      // Create message event and publish via event publisher

      await thread.replyText(message);

      emit(ThreadReplyState(status: ThreadReplyStatus.success));
    } catch (e) {
      emit(
        ThreadReplyState(status: ThreadReplyStatus.error, error: e.toString()),
      );
    }
  }
}
