import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

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
  ThreadReplyCubit()
    : super(ThreadReplyState(status: ThreadReplyStatus.initial));

  Future<void> sendReply({
    required String message,
    required String threadAnchor,
    required String counterpartyPubkey,
  }) async {
    emit(ThreadReplyState(status: ThreadReplyStatus.loading));
    try {
      final keyPair = getIt<KeyStorage>().getActiveKeyPairSync()!;

      Nip01Event msg = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: NOSTR_KIND_DM,
        tags: [
          ['a', threadAnchor],
        ],
        content: message.trim(),
      );

      await getIt<EventPublisherCubit>().publishEvents([
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
