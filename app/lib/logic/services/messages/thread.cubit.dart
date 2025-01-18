import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/util/custom_logger.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/models/nostr_kind/event.dart';
import 'package:hostr/injection.dart';

class ThreadCubit extends Cubit<ThreadCubitState> {
  CustomLogger logger = CustomLogger();
  ThreadCubit(ThreadCubitState initialState) : super(initialState);

  addMessage(GiftWrap message) {
    final messages = state.messages;
    messages.add(message);
    emit(ThreadCubitState(id: state.id, messages: messages));
  }

  String getCounterpartyPubkey() {
    logger.i('Getting counterparty pubkey');
    NostrKeyPairs ours = getIt<KeyStorage>().getActiveKeyPairSync()!;
    return state.messages.first.getTag('p').first.first != ours.public
        ? state.messages.first.getTag('p').first.first
        : state.messages.first.child.pubkey;
  }

  String getAnchor() {
    logger.i('Getting anchor');
    GiftWrap lastMessage = state.messages.last;
    if (lastMessage.child is Seal &&
        (lastMessage.child as Seal).child is Event) {
      return ((lastMessage.child as Seal).child as Event).anchor;
    }
    return '';
  }

  /// Get the latest state of the thread
  LatestThreadState? getLatestState() {
    logger.i('Getting latest state');

    NostrKeyPairs ours = (getIt<KeyStorage>().getActiveKeyPairSync())!;

    for (GiftWrap g in state.messages.reversed) {
      Seal seal = (g.child as Seal);
      Event content = (seal.child as Event);
      if (content is ReservationRequest) {
        if (seal.pubkey == ours.public) {
          return LatestThreadState.RESERVATION_REQUEST_SENT;
        }
        return LatestThreadState.RESERVATION_REQUEST_RECEIVED;
      } else if (content is Message) {
        if (seal.pubkey == ours.public) {
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
}

enum LatestThreadState {
  RESERVATION_REQUEST_RECEIVED,
  RESERVATION_REQUEST_SENT,
  MESSAGE_SENT,
  MESSAGE_RECEIVED,
  CONFIRMED,
  CANCELLED
}

class ThreadCubitState {
  final String id;
  final List<GiftWrap> messages;

  ThreadCubitState({required this.id, required this.messages});
}
