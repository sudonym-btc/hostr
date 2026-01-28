import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/util/custom_logger.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging/thread.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class ThreadCubit extends Cubit<ThreadCubitState> {
  CustomLogger logger = CustomLogger();
  final NostrService nostrService;
  final Thread thread;

  ThreadCubit(
    super.initialState, {
    required this.nostrService,
    required this.thread,
  });

  /// Get the latest state of the thread
  LatestThreadState? getLatestState() {
    logger.i('Getting latest state');

    KeyPair? ours = getIt<KeyStorage>().getActiveKeyPairSync();
    if (ours == null) return null;

    for (Message m in state.messages.reversed) {
      Event? content = m.child;
      if (content is ReservationRequest) {
        if (m.pubKey == ours.publicKey) {
          return LatestThreadState.RESERVATION_REQUEST_SENT;
        }
        return LatestThreadState.RESERVATION_REQUEST_RECEIVED;
      } else {
        if (m.pubKey == ours.publicKey) {
          return LatestThreadState.MESSAGE_SENT;
        }
        return LatestThreadState.MESSAGE_RECEIVED;
      }
    }

    logger.i('No matching state found');
    return null;
  }

  getReadStatus() {}

  @override
  Future<void> close() async {
    return super.close();
  }
}

enum LatestThreadState {
  RESERVATION_REQUEST_RECEIVED,
  RESERVATION_REQUEST_SENT,
  MESSAGE_SENT,
  MESSAGE_RECEIVED,
  CONFIRMED,
  CANCELLED,
}

class ThreadCubitState {
  final String id;
  final List<Message> messages;

  ThreadCubitState({required this.id, required this.messages});

  ThreadCubitState copyWith({String? id, List<Message>? messages}) {
    return ThreadCubitState(
      id: id ?? this.id,
      messages: messages ?? this.messages,
    );
  }
}
