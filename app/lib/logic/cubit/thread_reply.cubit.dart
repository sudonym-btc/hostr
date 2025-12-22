import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/main.dart';

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
  final KeyStorage keyStorage;
  final EventPublisherCubit publisher;

  ThreadReplyCubit({required this.keyStorage, required this.publisher})
    : super(ThreadReplyState(status: ThreadReplyStatus.initial));

  Future<void> sendReply({
    required String message,
    required String threadAnchor,
    required String counterpartyPubkey,
  }) async {
    emit(ThreadReplyState(status: ThreadReplyStatus.loading));
    try {
      // Create message event and publish via event publisher
      // This will be integrated with ReservationWorkflow for proper sealing/gift-wrapping

      await publisher.publishEvents([
        // giftWrapAndSeal(counterpartyPubkey, keyPair, msg, null).nip01Event,
        // giftWrapAndSeal(keyPair.publicKey, keyPair, msg, null).nip01Event,
      ]);

      emit(ThreadReplyState(status: ThreadReplyStatus.success));
    } catch (e) {
      emit(
        ThreadReplyState(status: ThreadReplyStatus.error, error: e.toString()),
      );
    }
  }
}
