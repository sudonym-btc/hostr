import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/util/custom_logger.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging/thread.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class ThreadCubit extends Cubit<ThreadCubitState> {
  CustomLogger logger = CustomLogger();
  final NostrService nostrService;
  StreamSubscription<List<Message>>? _messagesSub;
  final Thread thread;

  ThreadCubit(
    super.initialState, {
    required this.nostrService,
    required this.thread,
  }) {
    _messagesSub = thread.outputStream.listen(updateMessages);
  }

  Stream<ListCubitState<Reservation>> loadBookingState() {
    var x = ListCubit<Reservation>(
      nostrService: nostrService,
      kinds: [NOSTR_KIND_RESERVATION],
      filter: Filter(aTags: [getAnchor()]),
    );
    x.sync();
    return x.stream;
  }

  addMessage(Message message) {
    final messages = state.messages;
    messages.add(message);
    emit(state.copyWith(messages: messages));
  }

  /// Add raw Nip01Event messages (for threaded giftwraps)
  void updateMessages(List<Message> newMessages) {
    emit(state.copyWith(messages: newMessages));
  }

  /// Get the latest raw message for display
  Message? getLatestMessage() {
    if (state.messages.isEmpty) return null;
    return state.messages.reduce((a, b) => a.createdAt > b.createdAt ? a : b);
  }

  String getCounterpartyPubkey() {
    logger.i('Getting counterparty pubkey');
    KeyPair? ours = getIt<KeyStorage>().getActiveKeyPairSync();

    // Try raw messages first if available
    if (state.messages.isNotEmpty && ours != null) {
      final allPubkeys = state.messages
          .expand(
            (e) => [
              e.pubKey,
              ...e.tags
                  .where((t) => t.isNotEmpty && t[0] == 'p')
                  .map((t) => t[1]),
            ],
          )
          .toSet()
          .where((pk) => pk != ours.publicKey)
          .toList();

      if (allPubkeys.isNotEmpty) {
        return allPubkeys.first;
      }
    }

    // Fallback to legacy Message handling
    if (ours == null) {
      return 'unknown';
    }
    var keys = state.messages.expand((e) {
      var keys = [...e.pTags];
      if (e.child != null) {
        keys.add(e.child!.pubKey);
      }
      return keys;
    }).toList();

    return keys.firstWhere(
      (element) => element != ours.publicKey,
      orElse: () => 'unknown',
    );
  }

  String getListingAnchor() {
    logger.i('Getting listing anchor');

    // Try raw messages first
    if (state.messages.isNotEmpty) {
      for (final msg in state.messages) {
        final aTag = msg.tags.firstWhere(
          (t) => t.isNotEmpty && t[0] == 'a' && t.length > 1,
          orElse: () => [],
        );
        if (aTag.isNotEmpty) {
          return aTag[1];
        }
      }
    }

    // Fallback to legacy Message handling
    return state.messages
        .where((element) {
          return element.child is ReservationRequest;
        })
        .map((e) => e.child!.anchor)
        .first;
  }

  String getAnchor() {
    logger.i('Getting anchor');

    // Use thread ID from state
    return state.id;
  }

  /// Get the latest state of the thread
  LatestThreadState? getLatestState() {
    logger.i('Getting latest state');

    KeyPair? ours = getIt<KeyStorage>().getActiveKeyPairSync();
    if (ours == null) return null;

    // Try raw messages first
    if (state.messages.isNotEmpty) {
      final latest = state.messages.reduce(
        (a, b) => a.createdAt > b.createdAt ? a : b,
      );

      if (latest.pubKey == ours.publicKey) {
        return LatestThreadState.MESSAGE_SENT;
      }
      return LatestThreadState.MESSAGE_RECEIVED;
    }

    // Fallback to legacy Message handling
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
    // Return a default state if no matching type is found
    logger.i('No matching state found');
    return null;
  }

  getReadStatus() {}

  DateTime getLastDateTime() {
    // Try raw messages first
    if (state.messages.isNotEmpty) {
      final latest = state.messages.reduce(
        (a, b) => a.createdAt > b.createdAt ? a : b,
      );
      return DateTime.fromMillisecondsSinceEpoch(latest.createdAt * 1000);
    }

    // Fallback to legacy Message handling
    return state.messages
        .map(
          (message) =>
              DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000),
        )
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Future<void> close() async {
    await _messagesSub?.cancel();
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
